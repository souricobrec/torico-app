import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import vm from 'node:vm';
import { disconnectPlatformHandler } from '../disconnect-platform.js';

function fixture({ valid = true, fail = false } = {}) {
  const writes = [];
  const refs = (path) => ({ path, collection: (c) => ({ doc: (id) => refs(`${path}/${c}/${id}`) }) });
  const db = {
    collection: (c) => ({ doc: (id) => refs(`${c}/${id}`) }),
    runTransaction: async (fn) => {
      if (fail) throw new Error('unavailable');
      await fn({ get: async () => ({}), set: (ref, data) => writes.push({ path: ref.path, data }) });
    },
  };
  const handler = disconnectPlatformHandler({
    auth: { verifyIdToken: async (token, checkRevoked) => {
      assert.equal(token, 'valid-token'); assert.equal(checkRevoked, true);
      if (!valid) throw new Error('expired');
      return { uid: 'token-owner' };
    } }, db, fieldValue: { delete: () => 'DELETE', serverTimestamp: () => 'NOW' },
  });
  const res = { set() {}, status(code) { this.code = code; return this; }, json(body) { this.body = body; return this; } };
  return { handler, writes, res };
}

test('disconnect requires valid Firebase ID token; invalid/missing token writes nothing', async () => {
  for (const headers of [{}, { authorization: 'Bearer invalid token' }]) {
    const f = fixture(); await f.handler({ headers }, f.res);
    assert.equal(f.res.code, 401); assert.equal(f.writes.length, 0);
  }
  const f = fixture({ valid: false });
  await f.handler({ headers: { authorization: 'Bearer valid-token' } }, f.res);
  assert.equal(f.res.code, 401); assert.equal(f.writes.length, 0);
});

test('UID comes only from token, removes encrypted tokens and preserves sales/aggregates', async () => {
  const f = fixture();
  const req = { headers: { authorization: 'Bearer valid-token' }, params: { platform: 'mercado_pago' },
    query: { userId: 'victim' }, body: { userId: 'victim' } };
  await f.handler(req, f.res);
  assert.equal(f.res.code, 200);
  assert.deepEqual(f.writes.map(w => w.path), [
    'users/token-owner/integrations/mercado_pago', 'users/token-owner/integration_status/mercado_pago',
  ]);
  assert.equal(f.writes[0].data.accessTokenEncrypted, 'DELETE');
  assert.equal(f.writes[0].data.refreshTokenEncrypted, 'DELETE');
  assert.equal(f.writes[1].data.status, 'disconnected');
  await f.handler(req, f.res); // idempotent
  assert.equal(f.res.code, 200);
});

test('future platforms are rejected and storage errors are friendly', async () => {
  const f = fixture();
  await f.handler({ headers: { authorization: 'Bearer valid-token' }, params: { platform: 'rede' } }, f.res);
  assert.equal(f.res.code, 400); assert.equal(f.writes.length, 0);
  const failed = fixture({ fail: true });
  await failed.handler({ headers: { authorization: 'Bearer valid-token' }, params: { platform: 'mercado_pago' } }, failed.res);
  assert.equal(failed.res.code, 503);
});

test('disconnected integration blocks in-flight webhook and fallback sale before any writes', async () => {
  const source = readFileSync(new URL('../server.js', import.meta.url), 'utf8');
  const save = source.slice(source.indexOf('async function saveSale('), source.indexOf('async function processMercadoPagoPaymentWebhook'));
  const writes = [];
  const refs = (path) => ({ id: path, collection: c => ({ doc: id => refs(`${path}/${c}/${id}`) }) });
  const context = vm.createContext({
    db: { collection: c => ({ doc: id => refs(`${c}/${id}`) }), runTransaction: fn => fn({
      get: async ref => { assert.match(ref.id, /integrations\/mercado_pago$/); return { data: () => ({ status: 'disconnected' }) }; },
      set: (...args) => writes.push(args),
    }) }, normalizePlatformId: () => 'mercado_pago', getBrazilDateKey: () => '2026-10-03',
    roundMoney: Number, admin: { firestore: { Timestamp: { fromDate: d => d }, FieldValue: { serverTimestamp: () => 1 } } },
  });
  vm.runInContext(save, context);
  const result = await context.saveSale({ userId: 'token-owner', amount: 1, platform: 'Mercado Pago', source: 'webhook', externalId: 'payment' });
  assert.equal(result.ignored, true); assert.equal(writes.length, 0);
});

test('disconnected merchant cannot resolve webhook credentials; connected merchant still resolves', () => {
  const source = readFileSync(new URL('../server.js', import.meta.url), 'utf8');
  const fn = source.slice(source.indexOf('function buildMercadoPagoIntegrationContextFromDoc('), source.indexOf('async function findMercadoPagoIntegrationByMercadoPagoUserId('));
  let decryptions = 0;
  const context = vm.createContext({ decryptSecret: () => { decryptions++; return 'test-token'; } });
  vm.runInContext(fn, context);
  const doc = (status) => ({ data: () => ({ platformId: 'mercado_pago', status, mercadoPagoUserId: '123' }), ref: { parent: { parent: { id: 'owner' } } } });
  assert.equal(context.buildMercadoPagoIntegrationContextFromDoc({ integrationDoc: doc('disconnected'), mercadoPagoUserId: '123' }), null);
  assert.equal(decryptions, 0);
  assert.equal(context.buildMercadoPagoIntegrationContextFromDoc({ integrationDoc: doc('connected'), mercadoPagoUserId: '123' }).userId, 'owner');
  assert.equal(decryptions, 1);
});
