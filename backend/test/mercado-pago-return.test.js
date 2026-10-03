import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import vm from 'node:vm';
import { mercadoPagoReturnPage } from '../mercado-pago-return.js';

const source = readFileSync(new URL('../server.js', import.meta.url), 'utf8').replaceAll('\r\n', '\n');
const callback = source.slice(
  source.indexOf("app.get('/integrations/mercado-pago/callback'"),
  source.indexOf("app.post(\n  '/simulate-sale'"),
);

test('successful real callback saves UID before rendering official return', async () => {
  let handler;
  let saved;
  let html;
  let code;
  const logs = [];
  const context = vm.createContext({
    app: { get: (_, fn) => { handler = fn; } },
    getMissingMercadoPagoOAuthConfig: () => [],
    verifyOAuthState: () => ({ userId: 'firebase-test-uid' }),
    URLSearchParams,
    MERCADO_PAGO_CLIENT_ID: 'test-only',
    MERCADO_PAGO_CLIENT_SECRET: 'test-only',
    MERCADO_PAGO_REDIRECT_URI: 'https://api.meutorico.com.br/integrations/mercado-pago/callback',
    MERCADO_PAGO_OAUTH_TOKEN_URL: 'https://example.invalid/token',
    fetch: async () => ({ ok: true, json: async () => ({ user_id: 123 }) }),
    saveMercadoPagoIntegration: async (args) => {
      saved = args;
      return { userId: args.userId, mercadoPagoUserId: '123', status: 'connected' };
    },
    mercadoPagoReturnPage,
    console: { log: (...args) => logs.push(args), warn: () => {}, error: () => {} },
  });
  vm.runInContext(callback, context);
  const res = { set: () => {}, status: (value) => { code = value; return res; }, send: (value) => { html = value; } };
  await handler({ query: { code: 'test-code', state: 'test-state' } }, res);
  assert.equal(code, 200);
  assert.equal(saved.userId, 'firebase-test-uid');
  assert.match(html, /Mercado Pago conectado com sucesso\./);
  assert.match(html, /http-equiv="refresh" content="2;url=https:\/\/app\.meutorico\.com\.br\/\?integration=mercado_pago&amp;status=connected/);
  assert.match(html, /Voltar ao TORICO/);
  assert.equal(logs[0][0], 'Integracao Mercado Pago conectada:');

  await handler({ query: { error: 'access_denied' } }, res);
  assert.equal(code, 400);
  assert.match(html, /status=error/);
  assert.doesNotMatch(html, /http-equiv="refresh"/);
});

test('integration persists private encrypted tokens and minimal readable status atomically', async () => {
  const writes = [];
  let committed = false;
  const save = source.slice(source.indexOf('async function saveMercadoPagoIntegration('), source.indexOf('const OAUTH_STATE_TTL_MS'));
  const db = {
    collection: (collection) => ({ doc: (uid) => ({ collection: (sub) => ({ doc: (id) => ({ path: `${collection}/${uid}/${sub}/${id}` }) }) }) }),
    batch: () => ({ set: (ref, data) => writes.push({ ref, data }), commit: async () => { committed = true; } }),
  };
  const context = vm.createContext({
    db,
    admin: { firestore: { Timestamp: { fromDate: (d) => d }, FieldValue: { serverTimestamp: () => 'timestamp' } } },
    encryptSecret: (value) => ({ encrypted: value }),
  });
  vm.runInContext(save, context);
  await context.saveMercadoPagoIntegration({ userId: 'firebase-test-uid', tokenResponse: { access_token: 'test-access', refresh_token: 'test-refresh', user_id: 123 } });
  assert.equal(committed, true);
  assert.equal(writes[0].ref.path, 'users/firebase-test-uid/integrations/mercado_pago');
  assert.equal(writes[0].data.mercadoPagoUserId, '123');
  assert.equal(writes[0].data.accessTokenEncrypted.encrypted, 'test-access');
  assert.equal(writes[1].ref.path, 'users/firebase-test-uid/integration_status/mercado_pago');
  assert.deepEqual(Object.keys(writes[1].data).sort(), ['platform', 'platformId', 'status', 'updatedAt']);
  assert.equal(writes[1].data.status, 'connected');
});
