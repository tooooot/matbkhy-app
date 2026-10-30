// واجهة مطبخي: وجبات وفيديو وطلبات وأدوار. الدخول والأدوار من wardyat-core؛ هذه الخدمة تتحقق من الجلسة عنده.
const http = require('node:http');
const crypto = require('node:crypto');
const { DatabaseSync } = require('node:sqlite');
const { presignPut } = require('./s3');

const SECTIONS = ['مأكولات عربية', 'مأكولات سورية', 'مأكولات أردنية', 'حلويات', 'مشروبات'];
const NEXT = { pending: { chef: ['accepted', 'rejected'], user: ['cancelled'] }, accepted: { chef: ['ready'] }, ready: { captain: ['picked'] }, picked: { captain: ['delivered'] } };
const E = (code, msg) => Object.assign(new Error(msg), { code });
const id = () => crypto.randomBytes(8).toString('base64url');
const iso = () => new Date().toISOString();

function createApi(opts = {}) {
  const db = new DatabaseSync(opts.db || process.env.DB || ':memory:');
  db.exec(`
    pragma journal_mode=wal;
    create table if not exists chefs(user_id text primary key, name text, area text, bio text, created text);
    create table if not exists meals(id text primary key, chef_id text, title text, section text, price integer, unit text, qty integer, descr text, video_key text, status text default 'draft', created text);
    create table if not exists likes(meal_id text, user_id text, primary key(meal_id,user_id));
    create table if not exists comments(id text primary key, meal_id text, user_id text, name text, body text, created text);
    create table if not exists follows(chef_id text, user_id text, primary key(chef_id,user_id));
    create table if not exists orders(id text primary key, user_id text, chef_id text, captain_id text, status text, total integer, address text, created text, updated text);
    create table if not exists order_items(order_id text, meal_id text, title text, price integer, qty integer);
    create table if not exists role_requests(id text primary key, user_id text, name text, role text, info text, status text default 'open', created text);
  `);
  const q = (s, ...a) => db.prepare(s).get(...a), all = (s, ...a) => db.prepare(s).all(...a), run = (s, ...a) => db.prepare(s).run(...a);
  const fetchFn = opts.fetch || fetch, CORE = opts.coreUrl || process.env.CORE_URL || 'https://core.wardyat.net', KEY = opts.appKey || process.env.CORE_APP_KEY || '';
  const r2 = opts.r2 || (process.env.R2_ACCOUNT ? { account: process.env.R2_ACCOUNT, bucket: process.env.R2_BUCKET, accessKey: process.env.R2_KEY, secretKey: process.env.R2_SECRET, base: process.env.R2_PUBLIC_BASE } : null);
  const cache = new Map();

  async function core(path, token, method = 'GET', body) {
    const r = await fetchFn(CORE + path, { method, headers: { 'X-App-Key': KEY, Authorization: 'Bearer ' + token, 'Content-Type': 'application/json' }, body: body && JSON.stringify(body) });
    if (!r.ok) throw E(r.status === 401 ? 401 : 502, 'تعذّر التحقق من الجلسة');
    return r.json();
  }
  async function who(token) {
    const hit = cache.get(token); if (hit && hit.exp > Date.now()) return hit.user;
    const { user } = await core('/v1/me', token); cache.set(token, { user, exp: Date.now() + 30000 });
    if (cache.size > 2000) cache.clear();
    return user;
  }
  const meal = (m) => m && ({ id: m.id, title: m.title, section: m.section, price: m.price, unit: m.unit, qty: m.qty, desc: m.descr, chef_id: m.chef_id, chef: (q('select name,area from chefs where user_id=?', m.chef_id) || {}).name || '', area: (q('select area from chefs where user_id=?', m.chef_id) || {}).area || '',
    video: m.video_key && r2 ? `${r2.base}/${m.video_key}` : null, likes: q('select count(*) n from likes where meal_id=?', m.id).n, comments: q('select count(*) n from comments where meal_id=?', m.id).n, created: m.created });
  const order = (o) => ({ ...o, items: all('select meal_id,title,price,qty from order_items where order_id=?', o.id) });

  const routes = [];
  const R = (m, p, fn) => routes.push({ m, re: new RegExp('^' + p.replace(/:(\w+)/g, '(?<$1>[^/]+)') + '$'), fn });
  const need = (c, ...roles) => { if (!c.user) throw E(401, 'سجّل الدخول'); if (roles.length && !roles.some((r) => c.user.roles.includes(r)) && !c.user.roles.some((r) => r === 'admin' || r === 'owner')) throw E(403, 'غير مصرّح لدورك'); };
  const own = (c, mealId) => { const m = q('select * from meals where id=?', mealId); if (!m) throw E(404, 'غير موجود'); if (m.chef_id !== c.user.id) throw E(403, 'ليست وجبتك'); return m; };

  R('GET', '/healthz', async () => ({ ok: 1, storage: !!r2 }));
  R('GET', '/v1/sections', async () => SECTIONS.map((s) => ({ name: s, count: q("select count(*) n from meals where section=? and status='live'", s).n })));
  R('GET', '/v1/meals', async (c) => {
    const where = ["status='live'"], a = [];
    if (c.query.section) { where.push('section=?'); a.push(c.query.section); }
    if (c.query.chef) { where.push('chef_id=?'); a.push(c.query.chef); }
    if (c.query.q) { where.push('(title like ? or descr like ?)'); a.push('%' + c.query.q + '%', '%' + c.query.q + '%'); }
    return all(`select * from meals where ${where.join(' and ')} order by created desc limit ?`, ...a, Math.min(Number(c.query.limit) || 20, 50)).map(meal);
  });
  R('GET', '/v1/meals/:id', async (c) => { const m = q('select * from meals where id=?', c.p.id); if (!m || m.status !== 'live') throw E(404, 'غير موجود'); return meal(m); });
  R('POST', '/v1/meals', async (c) => {
    need(c, 'chef'); const b = c.body, title = String(b.title || '').trim().slice(0, 80), price = Number(b.price), qty = Number(b.qty);
    if (!title || !SECTIONS.includes(b.section) || !(price > 0 && price <= 5000) || !(qty >= 1 && qty <= 1000)) throw E(400, 'بيانات الوجبة غير مكتملة');
    const mid = id(); run('insert into meals values(?,?,?,?,?,?,?,?,?,?,?)', mid, c.user.id, title, b.section, Math.round(price), String(b.unit || 'وجبة').slice(0, 20), Math.round(qty), String(b.desc || '').slice(0, 300), null, 'draft', iso());
    return { id: mid };
  });
  R('POST', '/v1/meals/:id/upload-url', async (c) => {
    need(c, 'chef'); own(c, c.p.id); if (!r2) throw E(503, 'تخزين الفيديو غير مهيّأ بعد');
    const key = `meals/${c.p.id}/${id()}.mp4`; return { key, put_url: presignPut({ ...r2, key }), content_type: 'video/mp4', max_mb: 100 };
  });
  R('POST', '/v1/meals/:id/publish', async (c) => {
    need(c, 'chef'); own(c, c.p.id); const key = String(c.body.key || '');
    if (!key.startsWith(`meals/${c.p.id}/`)) throw E(400, 'مفتاح الفيديو غير صالح');
    run("update meals set video_key=?, status='live' where id=?", key, c.p.id); return { ok: 1 };
  });
  R('POST', '/v1/meals/:id/like', async (c) => { need(c); const had = q('select 1 x from likes where meal_id=? and user_id=?', c.p.id, c.user.id); if (had) run('delete from likes where meal_id=? and user_id=?', c.p.id, c.user.id); else run('insert into likes values(?,?)', c.p.id, c.user.id); return { liked: !had, likes: q('select count(*) n from likes where meal_id=?', c.p.id).n }; });
  R('GET', '/v1/meals/:id/comments', async (c) => all('select id,name,body,created from comments where meal_id=? order by created desc limit 100', c.p.id));
  R('POST', '/v1/meals/:id/comments', async (c) => { need(c); const t = String(c.body.body || '').trim().slice(0, 300); if (!t) throw E(400, 'التعليق فارغ'); run('insert into comments values(?,?,?,?,?,?)', id(), c.p.id, c.user.id, c.user.name || '', t, iso()); return { ok: 1 }; });
  R('GET', '/v1/chefs/:id', async (c) => { const ch = q('select * from chefs where user_id=?', c.p.id); if (!ch) throw E(404, 'غير موجود'); return { id: ch.user_id, name: ch.name, area: ch.area, bio: ch.bio, followers: q('select count(*) n from follows where chef_id=?', ch.user_id).n, meals: q("select count(*) n from meals where chef_id=? and status='live'", ch.user_id).n }; });
  R('PUT', '/v1/chef/profile', async (c) => { need(c, 'chef'); const b = c.body; run('insert into chefs values(?,?,?,?,?) on conflict(user_id) do update set name=excluded.name, area=excluded.area, bio=excluded.bio', c.user.id, String(b.name || c.user.name || '').slice(0, 60), String(b.area || '').slice(0, 80), String(b.bio || '').slice(0, 300), iso()); return { ok: 1 }; });
  R('POST', '/v1/chefs/:id/follow', async (c) => { need(c); const had = q('select 1 x from follows where chef_id=? and user_id=?', c.p.id, c.user.id); if (had) run('delete from follows where chef_id=? and user_id=?', c.p.id, c.user.id); else run('insert into follows values(?,?)', c.p.id, c.user.id); return { following: !had }; });

  R('POST', '/v1/orders', async (c) => {
    need(c); const items = Array.isArray(c.body.items) ? c.body.items.slice(0, 30) : [], address = String(c.body.address || '').trim().slice(0, 200);
    if (!items.length || !address) throw E(400, 'الطلب غير مكتمل');
    const byChef = new Map();
    for (const it of items) {
      const m = q("select * from meals where id=? and status='live'", String(it.meal_id)), n = Math.round(Number(it.qty));
      if (!m || !(n >= 1 && n <= 50)) throw E(400, 'وجبة غير متاحة'); if (m.qty < n) throw E(409, `الكمية المتاحة من «${m.title}» ${m.qty} فقط`);
      (byChef.get(m.chef_id) || byChef.set(m.chef_id, []).get(m.chef_id)).push({ m, n });
    }
    const out = [];
    for (const [chef, list] of byChef) {
      const oid = id(), total = list.reduce((s, x) => s + x.m.price * x.n, 0);
      run('insert into orders values(?,?,?,?,?,?,?,?,?)', oid, c.user.id, chef, null, 'pending', total, address, iso(), iso());
      for (const { m, n } of list) { run('insert into order_items values(?,?,?,?,?)', oid, m.id, m.title, m.price, n); run('update meals set qty=qty-? where id=?', n, m.id); }
      out.push(oid);
    }
    return { orders: out };
  });
  R('GET', '/v1/orders/mine', async (c) => { need(c); return all('select * from orders where user_id=? order by created desc limit 50', c.user.id).map(order); });
  R('GET', '/v1/chef/orders', async (c) => { need(c, 'chef'); return all('select * from orders where chef_id=? order by created desc limit 50', c.user.id).map(order); });
  R('GET', '/v1/captain/orders', async (c) => { need(c, 'captain'); return all("select * from orders where (status='ready' and captain_id is null) or captain_id=? order by created desc limit 50", c.user.id).map(order); });
  R('POST', '/v1/orders/:id/status', async (c) => {
    need(c); const o = q('select * from orders where id=?', c.p.id); if (!o) throw E(404, 'غير موجود'); const to = String(c.body.status || '');
    const as = o.user_id === c.user.id ? 'user' : o.chef_id === c.user.id ? 'chef' : c.user.roles.includes('captain') && (o.captain_id === c.user.id || (o.status === 'ready' && !o.captain_id)) ? 'captain' : null;
    if (!as || !(NEXT[o.status]?.[as] || []).includes(to)) throw E(409, 'لا يمكن هذا الانتقال');
    if (as === 'captain' && to === 'picked') run('update orders set captain_id=? where id=?', c.user.id, o.id);
    if (['rejected', 'cancelled'].includes(to)) for (const it of all('select meal_id,qty from order_items where order_id=?', o.id)) run('update meals set qty=qty+? where id=?', it.qty, it.meal_id);
    run('update orders set status=?, updated=? where id=?', to, iso(), o.id); return { status: to };
  });

  R('POST', '/v1/role-requests', async (c) => { need(c); const role = String(c.body.role); if (!['chef', 'captain'].includes(role)) throw E(400, 'دور غير صالح'); if (q("select 1 x from role_requests where user_id=? and role=? and status='open'", c.user.id, role)) throw E(409, 'لديك طلب مفتوح'); run('insert into role_requests values(?,?,?,?,?,?,?)', id(), c.user.id, c.user.name || '', role, String(c.body.info || '').slice(0, 300), 'open', iso()); return { ok: 1 }; });
  R('GET', '/v1/admin/role-requests', async (c) => { need(c, 'admin'); return all("select * from role_requests where status='open' order by created"); });
  R('POST', '/v1/admin/role-requests/:id/approve', async (c) => {
    need(c, 'admin'); const rq = q("select * from role_requests where id=? and status='open'", c.p.id); if (!rq) throw E(404, 'غير موجود');
    const cur = (await core('/v1/admin/users?q=', c.token)).find((u) => u.id === rq.user_id); const roles = [...new Set([...(cur ? cur.roles : ['user']), rq.role])];
    await core(`/v1/admin/users/${rq.user_id}/roles`, c.token, 'PUT', { roles });
    if (rq.role === 'chef') run('insert or ignore into chefs values(?,?,?,?,?)', rq.user_id, rq.name, '', '', iso());
    run("update role_requests set status='approved' where id=?", rq.id); cache.clear(); return { ok: 1 };
  });

  const server = http.createServer(async (req, res) => {
    const u = new URL(req.url, 'http://x'), send = (code, obj) => { res.writeHead(code, { 'Content-Type': 'application/json; charset=utf-8', 'Cache-Control': 'no-store', 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Headers': 'Content-Type, Authorization' }); res.end(JSON.stringify(obj)); };
    if (req.method === 'OPTIONS') return send(204, {});
    try {
      const r = routes.find((x) => x.m === req.method && x.re.test(u.pathname)); if (!r) return send(404, { error: 'مسار غير معروف' });
      let raw = ''; for await (const ch of req) { raw += ch; if (raw.length > 32768) return send(413, { error: 'الحجم كبير' }); }
      let body = {}; if (raw) { try { body = JSON.parse(raw); } catch { return send(400, { error: 'JSON غير صالح' }); } }
      const a = req.headers.authorization || '', c = { body, p: r.re.exec(u.pathname).groups || {}, query: Object.fromEntries(u.searchParams), token: a.slice(7) };
      if (a.startsWith('Bearer ')) c.user = await who(c.token).catch(() => null);
      send(200, await r.fn(c));
    } catch (e) { const code = Number.isInteger(e.code) ? e.code : 500; if (code === 500) console.error('api', e.message); send(code, { error: code === 500 ? 'خطأ داخلي' : e.message }); }
  });
  return { server, db, close: () => { server.close(); db.close(); } };
}
module.exports = { createApi };
if (require.main === module) { createApi().server.listen(3200, () => console.log('matbkhy-api on 3200')); process.on('uncaughtException', (e) => console.error('uncaught', e.message)); }
