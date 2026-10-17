import assert from 'node:assert/strict';
import { fixtureOwnershipIndex } from './ownership-index-fixtures.mjs';
import { readFileSync } from 'node:fs';
import vm from 'node:vm';
import { exchangeOAuthToken } from '../oauth-token-exchange.js';
import { authenticatedUid, oauthStateStore, persistOwnedIntegration } from '../mercado-pago-security.js';

export async function betaSecurityProbes({ auth, db, a, b, projectId }) {
  assert.match(projectId, /^demo-/);
  await fixtureOwnershipIndex(db, [{ id: '987002', conflict: true }]);
  const req = token => ({ headers: { authorization: `Bearer ${token}` }, query: { userId: b.localId } });
  assert.equal(await authenticatedUid(req(a.idToken), auth), a.localId);
  await assert.rejects(authenticatedUid({ headers: {} }, auth), { status: 401 });
  await assert.rejects(authenticatedUid(req('invalid'), auth), { status: 401 });
  const parts = a.idToken.split('.');
  const payload = JSON.parse(Buffer.from(parts[1], 'base64url'));
  payload.exp = 1;
  parts[1] = Buffer.from(JSON.stringify(payload)).toString('base64url');
  await assert.rejects(authenticatedUid(req(parts.join('.')), auth), { status: 401 });

  let clock = Date.now();
  const states = oauthStateStore(db, () => clock);
  const nonce = await states.issue(a.localId);
  const results = await Promise.allSettled(Array.from({ length: 5 }, () => states.consume(nonce)));
  assert.equal(results.filter(r => r.status === 'fulfilled').length, 1);
  assert.equal(results.find(r => r.status === 'fulfilled').value.userId, a.localId);
  await assert.rejects(states.consume(nonce), { status: 400 });
  const expired = await states.issue(a.localId);
  clock += 600001;
  await assert.rejects(states.consume(expired), { status: 400 });
  await assert.rejects(states.consume('legacy-signed-state'), { status: 400 });

  // Execute the actual callback handler with local state storage and a fake provider.
  const source = readFileSync(new URL('../server.js', import.meta.url), 'utf8').replaceAll('\r\n', '\n');
  const callbackSource = source.slice(source.indexOf("app.get('/integrations/mercado-pago/callback'"), source.indexOf("app.post(\n  '/simulate-sale'"));
  let callback, exchanges = 0, saves = 0;
  const context = vm.createContext({ app: { get: (_, fn) => callback = fn }, db,
    oauthStateStore, getMissingMercadoPagoOAuthConfig: () => [], URLSearchParams,
    MERCADO_PAGO_CLIENT_ID: 'fixture', MERCADO_PAGO_CLIENT_SECRET: 'fixture',
    MERCADO_PAGO_REDIRECT_URI: 'https://api.example.invalid/callback', MERCADO_PAGO_OAUTH_TOKEN_URL: 'https://provider.example.invalid/token',
    exchangeOAuthToken: (url, options) => exchangeOAuthToken(url, options, { fetchImpl: async () => { exchanges++; return { ok: true, json: async () => ({ user_id: 123, access_token: 'fixture' }) }; } }),
    saveMercadoPagoIntegration: async ({ userId }) => { saves++; assert.equal(userId, a.localId); return { userId, status: 'connected' }; },
    mercadoPagoReturnPage: status => status, console: { log() {}, warn() {}, error() {} },
  });
  vm.runInContext(callbackSource, context);
  const callbackState = await oauthStateStore(db).issue(a.localId);
  const callbacks = await Promise.all(Array.from({ length: 4 }, async () => {
    let status;
    const res = { set() {}, status(value) { status = value; return res; }, send() {} };
    await callback({ query: { code: 'fixture-code', state: callbackState } }, res);
    return status;
  }));
  assert.equal(exchanges, 1); assert.equal(saves, 1);
  assert.equal(callbacks.filter(status => status === 200).length, 1);
  assert.equal(callbacks.filter(status => status === 400).length, 3);

  const ownershipUids = ['ownership-a', 'ownership-b'];
  const authorization = async uid => { const store = oauthStateStore(db); return store.consume(await store.issue(uid)); };
  const ownershipContexts = await Promise.all(ownershipUids.map(authorization));
  const write = uid => [db.doc(`users/${uid}/integrations/mercado_pago`),
    { platformId: 'mercado_pago', mercadoPagoUserId: '987001', status: 'connected', accessTokenEncrypted: { fixture: true } }];
  const races = await Promise.allSettled(ownershipUids.map((uid, i) =>
    persistOwnedIntegration(db, uid, '987001', [write(uid)], ownershipContexts[i])));
  assert.equal(races.filter(r => r.status === 'fulfilled').length, 1);
  const owner = (await db.doc('mp_account_owners/987001').get()).data().userId;
  await persistOwnedIntegration(db, owner, '987001', [write(owner)], await authorization(owner));
  const other = ownershipUids.find(uid => uid !== owner);
  await assert.rejects(persistOwnedIntegration(db, other, '987001', [write(other)], await authorization(other)), { status: 409 });

  // Existing duplicate fixture records are never overwritten or disconnected.
  for (const uid of ['legacy-a', 'legacy-b']) {
    await db.doc(`users/${uid}/integrations/mercado_pago`).set({ mercadoPagoUserId: '987002', status: 'connected' });
  }
  await assert.rejects(persistOwnedIntegration(db, 'legacy-a', '987002', [], await authorization('legacy-a')), { status: 409 });
  assert.equal((await db.doc('users/legacy-b/integrations/mercado_pago').get()).data().status, 'connected');
  assert.equal((await db.doc('mp_account_owners/987002').get()).data().state, 'conflict');

  await db.doc(`users/${a.localId}/sales/fixture-sale`).set({ amount: 1, status: 'approved' });
  const root = `http://127.0.0.1:18891/v1/projects/${projectId}/databases/(default)/documents/`;
  const call = (path, fields, token = b.idToken) => fetch(root + path, {
    method: fields ? 'PATCH' : 'GET', headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
    body: fields ? JSON.stringify({ fields }) : undefined,
  });
  assert.equal((await call(`users/${a.localId}/sales/fixture-sale`)).status, 403);
  assert.equal((await call(`users/${a.localId}/sales/fixture-sale`, null, a.idToken)).status, 200);
  // b profile does not exist yet: neither create nor update can set a plan.
  assert.equal((await call(`users/${b.localId}`, { plan: { stringValue: 'plus' } })).status, 403);
  assert.equal((await call(`users/${b.localId}`, { displayName: { stringValue: 'Fixture' } })).status, 200);
  assert.equal((await call(`users/${b.localId}`, { displayName: { stringValue: 'Fixture' }, plan: { stringValue: 'plus' } })).status, 403);
  await db.doc(`users/${b.localId}`).set({ plan: 'plus', displayName: 'Admin fixture' });
  assert.equal((await call(`users/${b.localId}`)).status, 200);
  for (const path of ['mp_account_owners/987001', 'mp_ownership_index/active', 'mp_index_certificates/anything', 'mp_index_evidence/anything', 'mp_oauth_nonces/anything', 'oauth_nonce_slots/anything', 'oauth_authorization_controls/anything']) {
    assert.equal((await call(path)).status, 403);
    assert.equal((await call(path, { state: { stringValue: 'ready' } })).status, 403);
  }
  console.log('PASS Beta: Auth token/expiry/UID, nonce concurrency/replay/expiry, merchant uniqueness/legacy conflicts, plan Rules/private registries');
}
