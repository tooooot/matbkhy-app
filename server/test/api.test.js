const { test } = require('node:test');
const assert = require('node:assert/strict');
const { createApi } = require('../api');
const { presignPut } = require('../s3');

const USERS = {
  chef1: { id: 'c1', name: 'أم خالد', roles: ['chef'] }, user1: { id: 'u1', name: 'سارة', roles: ['user'] },
  cap1: { id: 'k1', name: 'كابتن', roles: ['captain'] }, admin1: { id: 'a1', name: 'مدير', roles: ['admin'] }, user2: { id: 'u2', name: 'ليلى', roles: ['user'] },
};
const calls = [];
const fakeFetch = async (url, o = {}) => {
  const path = url.replace('https://core.test', ''), tok = (o.headers.Authorization || '').slice(7), u = USERS[tok];
  calls.push([o.method || 'GET', path]);
  if (!u) return { ok: false, status: 401, json: async () => ({}) };
  if (path === '/v1/me') return { ok: true, json: async () => ({ user: u }) };
  if (path.startsWith('/v1/admin/users?')) return { ok: true, json: async () => Object.values(USERS) };
  if (/\/roles$/.test(path)) { const t = Object.values(USERS).find((x) => path.includes(x.id)); t.roles = JSON.parse(o.body).roles; return { ok: true, json: async () => ({ ok: 1 }) }; }
  return { ok: false, status: 404, json: async () => ({}) };
};
const r2 = { account: 'acc', bucket: 'bk', accessKey: 'AK', secretKey: 'SK', base: 'https://cdn.test' };

async function boot() {
  const api = createApi({ db: ':memory:', fetch: fakeFetch, coreUrl: 'https://core.test', appKey: 'ck', r2 });
  await new Promise((r) => api.server.listen(0, r));
  const base = `http://127.0.0.1:${api.server.address().port}`;
  const call = async (method, path, tok, body) => { const r = await fetch(base + path, { method, headers: { 'Content-Type': 'application/json', ...(tok ? { Authorization: 'Bearer ' + tok } : {}) }, body: body && JSON.stringify(body) }); return { s: r.status, j: await r.json() }; };
  return { api, call };
}
const goodMeal = { title: 'كبسة لحم', section: 'مأكولات عربية', price: 85, qty: 5 };

test('رابط الرفع الموقّع: صيغة SigV4 ثابتة وحتمية', () => {
  const u = presignPut({ ...r2, key: 'meals/a b/x.mp4', now: new Date('2026-10-30T10:00:00Z') });
  assert.match(u, /^https:\/\/acc\.r2\.cloudflarestorage\.com\/bk\/meals\/a%20b\/x\.mp4\?X-Amz-Algorithm=AWS4-HMAC-SHA256/);
  assert.match(u, /X-Amz-Date=20261030T100000Z/); assert.match(u, /X-Amz-Signature=[0-9a-f]{64}$/);
  assert.equal(u, presignPut({ ...r2, key: 'meals/a b/x.mp4', now: new Date('2026-10-30T10:00:00Z') }));
});

test('الطاهي ينشر وجبة بفيديو ثم تظهر للجميع، والمستخدم لا ينشر', async () => {
  const { api, call } = await boot();
  assert.equal((await call('POST', '/v1/meals', 'user1', goodMeal)).s, 403);
  assert.equal((await call('POST', '/v1/meals', null, goodMeal)).s, 401);
  assert.equal((await call('POST', '/v1/meals', 'chef1', { ...goodMeal, price: -1 })).s, 400);
  const { j: { id } } = await call('POST', '/v1/meals', 'chef1', goodMeal);
  assert.equal((await call('GET', '/v1/meals')).j.length, 0, 'المسودة لا تظهر');
  const up = (await call('POST', `/v1/meals/${id}/upload-url`, 'chef1')).j; assert.match(up.put_url, /X-Amz-Signature/);
  assert.equal((await call('POST', `/v1/meals/${id}/upload-url`, 'user1')).s, 403);
  assert.equal((await call('POST', `/v1/meals/${id}/publish`, 'chef1', { key: 'meals/other/x.mp4' })).s, 400);
  assert.equal((await call('POST', `/v1/meals/${id}/publish`, 'chef1', { key: up.key })).s, 200);
  const list = (await call('GET', '/v1/meals?section=' + encodeURIComponent('مأكولات عربية'))).j;
  assert.equal(list.length, 1); assert.equal(list[0].video, 'https://cdn.test/' + up.key);
  api.close();
});

test('طلب كامل: إنقاص الكمية، رفض الزائد، الحالات، الكابتن، والإلغاء يعيد الكمية', async () => {
  const { api, call } = await boot();
  const id = (await call('POST', '/v1/meals', 'chef1', goodMeal)).j.id; const key = (await call('POST', `/v1/meals/${id}/upload-url`, 'chef1')).j.key;
  await call('POST', `/v1/meals/${id}/publish`, 'chef1', { key });
  assert.equal((await call('POST', '/v1/orders', 'user1', { items: [{ meal_id: id, qty: 9 }], address: 'جدة' })).s, 409);
  assert.equal((await call('POST', '/v1/orders', 'user1', { items: [{ meal_id: id, qty: 2 }] })).s, 400, 'بلا عنوان');
  const oid = (await call('POST', '/v1/orders', 'user1', { items: [{ meal_id: id, qty: 2 }], address: 'جدة، الصفا' })).j.orders[0];
  assert.equal((await call('GET', `/v1/meals/${id}`)).j.qty, 3);
  assert.equal((await call('POST', `/v1/orders/${oid}/status`, 'user2', { status: 'cancelled' })).s, 409, 'غريب');
  assert.equal((await call('POST', `/v1/orders/${oid}/status`, 'cap1', { status: 'picked' })).s, 409, 'قبل الجاهزية');
  assert.equal((await call('POST', `/v1/orders/${oid}/status`, 'chef1', { status: 'accepted' })).s, 200);
  assert.equal((await call('POST', `/v1/orders/${oid}/status`, 'chef1', { status: 'ready' })).s, 200);
  assert.equal((await call('GET', '/v1/captain/orders', 'cap1')).j.length, 1);
  assert.equal((await call('POST', `/v1/orders/${oid}/status`, 'cap1', { status: 'picked' })).s, 200);
  assert.equal((await call('POST', `/v1/orders/${oid}/status`, 'cap1', { status: 'delivered' })).s, 200);
  assert.equal((await call('GET', '/v1/orders/mine', 'user1')).j[0].status, 'delivered');
  const o2 = (await call('POST', '/v1/orders', 'user1', { items: [{ meal_id: id, qty: 3 }], address: 'x' })).j.orders[0];
  assert.equal((await call('GET', `/v1/meals/${id}`)).j.qty, 0);
  await call('POST', `/v1/orders/${o2}/status`, 'user1', { status: 'cancelled' });
  assert.equal((await call('GET', `/v1/meals/${id}`)).j.qty, 3, 'الإلغاء يعيد الكمية');
  api.close();
});

test('طلب دور طاهٍ ثم موافقة المدير فقط', async () => {
  const { api, call } = await boot();
  assert.equal((await call('POST', '/v1/role-requests', 'user1', { role: 'owner' })).s, 400);
  assert.equal((await call('POST', '/v1/role-requests', 'user1', { role: 'chef', info: 'مطبخ منزلي' })).s, 200);
  assert.equal((await call('POST', '/v1/role-requests', 'user1', { role: 'chef' })).s, 409);
  assert.equal((await call('GET', '/v1/admin/role-requests', 'user1')).s, 403);
  const [rq] = (await call('GET', '/v1/admin/role-requests', 'admin1')).j;
  assert.equal((await call('POST', `/v1/admin/role-requests/${rq.id}/approve`, 'user1')).s, 403);
  assert.equal((await call('POST', `/v1/admin/role-requests/${rq.id}/approve`, 'admin1')).s, 200);
  assert.ok(USERS.user1.roles.includes('chef'));
  assert.equal((await call('GET', '/v1/admin/role-requests', 'admin1')).j.length, 0);
  api.close();
});

test('إعجاب وتعليق ومتابعة', async () => {
  const { api, call } = await boot();
  const id = (await call('POST', '/v1/meals', 'chef1', goodMeal)).j.id;
  assert.equal((await call('POST', `/v1/meals/${id}/like`, 'user1')).j.likes, 1);
  assert.equal((await call('POST', `/v1/meals/${id}/like`, 'user1')).j.likes, 0, 'تبديل');
  assert.equal((await call('POST', `/v1/meals/${id}/comments`, 'user1', { body: '  ' })).s, 400);
  await call('POST', `/v1/meals/${id}/comments`, 'user1', { body: 'لذيذة' });
  assert.equal((await call('GET', `/v1/meals/${id}/comments`)).j[0].body, 'لذيذة');
  await call('PUT', '/v1/chef/profile', 'chef1', { area: 'جدة' });
  await call('POST', '/v1/chefs/c1/follow', 'user1');
  assert.equal((await call('GET', '/v1/chefs/c1')).j.followers, 1);
  api.close();
});
