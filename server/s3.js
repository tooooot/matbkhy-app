// رابط رفع مؤقت (SigV4) لتخزين متوافق مع S3 مثل Cloudflare R2؛ الجوال يرفع الفيديو مباشرة دون المرور بالسيرفر.
const crypto = require('node:crypto');
const hmac = (k, d) => crypto.createHmac('sha256', k).update(d).digest();
const hex = (d) => crypto.createHash('sha256').update(d).digest('hex');
const enc = (s) => encodeURIComponent(s).replace(/[!'()*]/g, (c) => '%' + c.charCodeAt(0).toString(16).toUpperCase());

function presignPut({ account, bucket, accessKey, secretKey, key, expires = 900, contentType = 'video/mp4', now = new Date() }) {
  const host = `${account}.r2.cloudflarestorage.com`;
  const amz = now.toISOString().replace(/[:-]|\.\d{3}/g, ''), day = amz.slice(0, 8), scope = `${day}/auto/s3/aws4_request`;
  const path = `/${bucket}/${key.split('/').map(enc).join('/')}`;
  const q = { 'X-Amz-Algorithm': 'AWS4-HMAC-SHA256', 'X-Amz-Credential': `${accessKey}/${scope}`, 'X-Amz-Date': amz, 'X-Amz-Expires': String(expires), 'X-Amz-SignedHeaders': 'content-type;host' };
  const qs = Object.keys(q).sort().map((k) => `${enc(k)}=${enc(q[k])}`).join('&');
  const canon = ['PUT', path, qs, `content-type:${contentType}\nhost:${host}\n`, 'content-type;host', 'UNSIGNED-PAYLOAD'].join('\n');
  const sts = ['AWS4-HMAC-SHA256', amz, scope, hex(canon)].join('\n');
  const k = hmac(hmac(hmac(hmac('AWS4' + secretKey, day), 'auto'), 's3'), 'aws4_request');
  return `https://${host}${path}?${qs}&X-Amz-Signature=${hmac(k, sts).toString('hex')}`;
}
module.exports = { presignPut };
