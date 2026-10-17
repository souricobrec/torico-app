import assert from 'node:assert/strict';
import { fixtureOwnershipIndex } from './ownership-index-fixtures.mjs';
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { FieldValue } from '@google-cloud/firestore';
import vm from 'node:vm';
import { oauthStateStore, persistOwnedIntegration, canonicalMerchantId, canonicalIntegrationMatches, authenticatedUid } from '../mercado-pago-security.js';
import { disconnectPlatformHandler } from '../disconnect-platform.js';

export async function remediationProbes({ auth, db, a, b, projectId }) {
  assert.equal(projectId, 'demo-torico-intake');
  await fixtureOwnershipIndex(db, [
    { id: 990001, userId: 'numeric-owner' }, { id: '990002', userId: 'alias-owner' },
    { id: 990003, conflict: true }, { id: 990004, userId: a.localId },
  ]);
  const evidence = [];
  const pass = text => { evidence.push(text); console.log('PASS remediation: ' + text); };
  const ref = uid => db.doc(`users/${uid}/integrations/mercado_pago`);
  const authorize = async (uid, store = oauthStateStore(db)) => store.consume(await store.issue(uid));
  const data = id => ({ platformId: 'mercado_pago', mercadoPagoUserId: id, status: 'connected', accessTokenEncrypted: { fixture: true } });

  await ref('numeric-owner').set(data(990001));
  const before = (await ref('numeric-owner').get()).data();
  await assert.rejects(persistOwnedIntegration(db, 'numeric-other', ' 000990001 ', [[ref('numeric-other'), data('990001')]], await authorize('numeric-other')), { status: 409 });
  assert.deepEqual((await ref('numeric-owner').get()).data(), before);
  assert.equal((await canonicalIntegrationMatches(db, '000990001')).length, 1);
  await persistOwnedIntegration(db, 'numeric-owner', 990001, [[ref('numeric-owner'), data(990001)]], await authorize('numeric-owner'));
  assert.equal((await ref('numeric-owner').get()).data().mercadoPagoUserId, '990001');
  await db.doc('mp_account_owners/000990002').set({ userId: 'alias-owner' });
  await assert.rejects(persistOwnedIntegration(db, 'alias-other', 990002, [], await authorize('alias-other')), { status: 409 });
  await ref('mixed-a').set(data(990003));
  await ref('mixed-b').set(data(' 000990003 '));
  await assert.rejects(persistOwnedIntegration(db, 'mixed-a', '990003', [], await authorize('mixed-a')), { status: 409 });
  assert.equal((await ref('mixed-b').get()).data().status, 'connected');
  const racers = ['canonical-race-a', 'canonical-race-b'];
  const contexts = await Promise.all(racers.map(uid => authorize(uid)));
  const race = await Promise.allSettled(racers.map((uid, i) => persistOwnedIntegration(db, uid, i ? '000990006' : 990006, [[ref(uid), data(990006)]], contexts[i])));
  assert.equal(race.filter(r => r.status === 'fulfilled').length, 1);
  pass('numeric/padded IDs, legacy registry aliases, mixed duplicates and concurrent canonical claims');

  // Real Auth Emulator token + real disconnect endpoint transaction.
  let clock = Date.now() + 1200000;
  const store = oauthStateStore(db, () => clock);
  const pending = await store.issue(a.localId);
  const inFlight = await authorize(a.localId, store);
  await ref(a.localId).set(data('990004'));
  const sale = db.doc(`users/${a.localId}/sales/remediation-preserved`);
  await sale.set({ amount: 1, status: 'approved' });
  const disconnect = disconnectPlatformHandler({ auth, db, fieldValue: FieldValue });
  async function leave() {
    const res = { set() {}, status(code) { this.code = code; return this; }, json() {} };
    await disconnect({ headers: { authorization: `Bearer ${a.idToken}` }, params: { platform: 'mercado_pago' } }, res);
    assert.equal(res.code, 200);
  }
  await leave();
  await assert.rejects(store.consume(pending), { code: 'authorization_cancelled' });
  await assert.rejects(persistOwnedIntegration(db, a.localId, '990004', [[ref(a.localId), data('990004')]], inFlight), { code: 'authorization_cancelled' });
  assert.equal((await ref(a.localId).get()).data().status, 'disconnected');
  await persistOwnedIntegration(db, a.localId, '990004', [[ref(a.localId), data('990004')]], await authorize(a.localId, store));
  assert.equal((await ref(a.localId).get()).data().status, 'connected');
  const concurrent = await authorize(a.localId, store);
  await Promise.allSettled([leave(), persistOwnedIntegration(db, a.localId, '990004', [[ref(a.localId), data('990004')]], concurrent)]);
  assert.equal((await ref(a.localId).get()).data().status, 'disconnected');
  assert.deepEqual((await sale.get()).data(), { amount: 1, status: 'approved' });
  pass('disconnect cancels pending and already-consumed callbacks atomically; explicit reconnect works; history preserved');

  let quotaTime = Date.now();
  const quotaUid = 'quota-fixture';
  const quota = () => oauthStateStore(db, () => quotaTime);
  const attempts = await Promise.allSettled(Array.from({ length: 12 }, () => quota().issue(quotaUid)));
  const issued = attempts.filter(r => r.status === 'fulfilled').map(r => r.value);
  assert.equal(issued.length, 5);
  assert.ok(attempts.filter(r => r.status === 'rejected').every(r => r.reason.status === 429));
  const old = issued[0];
  await quota().consume(old);
  await assert.rejects(quota().issue(quotaUid), { status: 429 });
  const countBefore = (await db.collection('oauth_nonce_slots').get()).size;
  quotaTime += 600001;
  const replacement = await quota().issue(quotaUid);
  await assert.rejects(quota().consume(old), { status: 400 });
  await assert.rejects(quota().consume(issued[1]), { status: 400 });
  assert.equal((await db.collection('oauth_nonce_slots').get()).size, countBefore);
  await quota().consume(replacement);
  pass('distributed quota across store instances, 429 on excess, expiry, reuse without growth and replay rejection');

  const source = readFileSync(new URL('../server.js', import.meta.url), 'utf8');
  let handler, state;
  const pbStore = oauthStateStore(db, Date.now, 'pagbank');
  const context = vm.createContext({ app: { post: (_, fn) => handler = fn }, authenticatedUid,
    admin: { auth: () => auth }, URL, getMissingPagBankOAuthConfig: () => [],
    createStoredOAuthState: async ({ userId }) => { state = await pbStore.issue(userId); return state; },
    PAGBANK_CONNECT_AUTHORIZE_URL: 'https://provider.example.invalid/authorize', PAGBANK_CLIENT_ID: 'fixture',
    PAGBANK_REDIRECT_URI: 'https://api.example.invalid/callback', getPagBankOAuthScopeForAuthorizationUrl: () => 'fixture', console: { warn() {} },
  });
  vm.runInContext(source.slice(source.indexOf("app.post('/integrations/pagbank/connect'"), source.indexOf("app.get('/integrations/pagbank/callback'")), context);
  const res = () => ({ set() {}, status(code) { this.code = code; return this; }, json() {} });
  for (const authorization of ['', 'Bearer invalid']) {
    const response = res(); await handler({ headers: { authorization }, query: { userId: b.localId } }, response);
    assert.equal(response.code, 401);
  }
  await handler({ headers: { authorization: `Bearer ${a.idToken}` }, query: { userId: b.localId } }, res());
  await assert.rejects(oauthStateStore(db).consume(state), { status: 400 });
  assert.equal((await pbStore.consume(state)).userId, a.localId);
  await assert.rejects(pbStore.consume(state), { status: 400 });
  const signup = await fetch('http://127.0.0.1:19099/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fixture', {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: 'revoked-pagbank@example.invalid', password: 'local-fixture-only-123', returnSecureToken: true }),
  });
  assert.equal(signup.status, 200);
  const revoked = await signup.json();
  await new Promise(resolve => setTimeout(resolve, 1100));
  await auth.revokeRefreshTokens(revoked.localId);
  const revokedResponse = res();
  await handler({ headers: { authorization: `Bearer ${revoked.idToken}` }, query: { userId: b.localId } }, revokedResponse);
  assert.equal(revokedResponse.code, 401);
  pass('PagBank real emulator token/revocation, query UID ignored, unauthenticated denial, platform isolation and replay');
  mkdirSync('.tmp-beta-remediation', { recursive: true });
  writeFileSync('.tmp-beta-remediation/emulator-results.json', JSON.stringify({ projectId, syntheticOnly: true, evidence }, null, 2));
}
