import test from 'node:test';
import assert from 'node:assert/strict';
import { canonicalMerchantId, canonicalIntegrationMatches, authenticatedUid } from '../mercado-pago-security.js';
import { exchangeOAuthToken } from '../oauth-token-exchange.js';
import { validateEmulatorIsolation } from '../environment-isolation.js';
import { readFileSync } from 'node:fs';
import vm from 'node:vm';

test('canonical MP IDs cover safe numbers and padded strings without rounding unsafe values', () => {
  for (const value of [123, '123', ' 000123 ']) assert.equal(canonicalMerchantId(value), '123');
  for (const value of [0, -1, 1.5, Number.MAX_SAFE_INTEGER + 1, '1e3', '', null, '12/3', '0', '9'.repeat(31)]) {
    assert.throws(() => canonicalMerchantId(value), { code: 'merchant_id_review_required' });
  }
});

test('missing certification fails closed without scanning legacy documents', async () => {
  const db = { runTransaction: fn => fn({ get: ref => ref.get() }),
    doc: () => ({ get: async () => ({ exists: false, data: () => undefined }) }) };
  await assert.rejects(canonicalIntegrationMatches(db, '123'), { code: 'certification_anchor_unconfigured' });
});

test('OAuth deadline covers ignored abort and slow JSON; no late result reaches persistence', async () => {
  for (const slowJson of [false, true]) {
    let finish, signal, saved = false;
    const pending = new Promise(resolve => { finish = resolve; });
    const task = exchangeOAuthToken('https://provider.example.invalid/token', {}, {
      timeoutMs: 20, fetchImpl: async (_, options) => {
        signal = options.signal;
        return slowJson ? { ok: true, json: () => pending } : pending;
      },
    }).then(() => { saved = true; });
    await assert.rejects(task, { status: 504, code: 'oauth_provider_timeout' });
    assert.equal(signal.aborted, true);
    finish(slowJson ? { access_token: 'fixture' } : { ok: true, json: async () => ({ access_token: 'fixture' }) });
    await new Promise(resolve => setTimeout(resolve, 10));
    assert.equal(saved, false);
  }
});

test('OAuth exchange rejects HTTP, JSON and empty-token faults without upstream secrets', async () => {
  for (const response of [
    { ok: false, json: async () => ({ private: 'do-not-log', access_token: 'fixture' }) },
    { ok: true, json: async () => { throw Error('do-not-log'); } },
    { ok: true, json: async () => ({ access_token: '' }) },
  ]) await assert.rejects(exchangeOAuthToken('https://provider.example.invalid/token', {}, { fetchImpl: async () => response }),
    error => error.code === 'oauth_token_exchange_failed' && !error.message.includes('do-not-log'));
});

test('PagBank token identity overrides query/body UID and denies missing/revoked authentication', async () => {
  const source = readFileSync(new URL('../server.js', import.meta.url), 'utf8');
  let handler, captured, issued = 0;
  const context = vm.createContext({ app: { post: (_, fn) => handler = fn }, authenticatedUid,
    admin: { auth: () => ({ verifyIdToken: async token => {
      if (token !== 'valid') throw Error('revoked'); return { uid: 'token-owner' };
    } }) }, getMissingPagBankOAuthConfig: () => [], URL,
    createStoredOAuthState: async ({ userId }) => { captured = userId; issued++; return 'fixture'; },
    PAGBANK_CONNECT_AUTHORIZE_URL: 'https://provider.example.invalid/authorize', PAGBANK_CLIENT_ID: 'fixture',
    PAGBANK_REDIRECT_URI: 'https://api.example.invalid/callback', getPagBankOAuthScopeForAuthorizationUrl: () => 'fixture',
    console: { warn() {} },
  });
  vm.runInContext(source.slice(source.indexOf("app.post('/integrations/pagbank/connect'"), source.indexOf("app.get('/integrations/pagbank/callback'")), context);
  const res = { set() {}, status(code) { this.code = code; return this; }, json(value) { this.body = value; } };
  for (const authorization of ['', 'Bearer revoked']) {
    await handler({ headers: { authorization }, query: { userId: 'victim' } }, res);
    assert.equal(res.code, 401); assert.equal(issued, 0);
  }
  await handler({ headers: { authorization: 'Bearer valid' }, query: { userId: 'victim' }, body: { userId: 'victim' } }, res);
  assert.equal(captured, 'token-owner'); assert.equal(issued, 1);
  assert.ok(res.body.authorizationUrl.startsWith('https://provider.example.invalid/'));
});

test('runtime rejects unknown modes, local/production mixing and secret-bearing demo configurations', () => {
  for (const env of [
    { APP_ENV: 'staging', FIREBASE_PROJECT_ID: 'production-fixture' },
    { NODE_ENV: 'development', FIREBASE_PROJECT_ID: 'production-fixture' },
    { NODE_ENV: 'test', APP_ENV: 'production' },
    { APP_ENV: 'development', K_SERVICE: 'fixture' },
    { APP_ENV: 'production', FIREBASE_PROJECT_ID: 'demo-local', FIREBASE_AUTH_EMULATOR_HOST: 'localhost:19099', FIRESTORE_EMULATOR_HOST: 'localhost:18891' },
    { FIREBASE_PROJECT_ID: 'production-a', GOOGLE_CLOUD_PROJECT: 'production-b' },
    { FIREBASE_PROJECT_ID: 'demo-local', FIRESTORE_EMULATOR_HOST: '127.0.0.1:99999', FIREBASE_AUTH_EMULATOR_HOST: 'localhost:19099' },
  ]) assert.throws(() => validateEmulatorIsolation(env), /startup refused/);
});
