import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync, mkdtempSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { versionWebShell } from '../../scripts/version-web-shell.mjs';
import vm from 'node:vm';
import { authenticatedUid } from '../mercado-pago-security.js';
import { validateEmulatorIsolation } from '../environment-isolation.js';

test('authorization uses revoked-token verification; query UID cannot substitute authentication', async () => {
  const auth = { verifyIdToken: async (token, revoked) => {
    assert.equal(revoked, true);
    if (token !== 'valid') throw new Error('sensitive upstream detail');
    return { uid: 'owner' };
  } };
  assert.equal(await authenticatedUid({ headers: { authorization: 'Bearer valid' }, query: { userId: 'victim' } }, auth), 'owner');
  for (const value of ['', 'Bearer invalid', 'Basic valid', 'Bearer valid extra']) {
    await assert.rejects(authenticatedUid({ headers: { authorization: value } }, auth), { status: 401 });
  }
});

test('actual POST handler authenticates before issuing state and never reads query UID', async () => {
  const source = readFileSync(new URL('../server.js', import.meta.url), 'utf8');
  const start = source.indexOf("app.post('/integrations/mercado-pago/connect'");
  const end = source.indexOf("app.get('/integrations/mercado-pago/callback'", start);
  let handler, issued = 0, uid, body, status;
  const context = vm.createContext({ app: { post: (_, fn) => handler = fn },
    authenticatedUid, admin: { auth: () => ({ verifyIdToken: async () => ({ uid: 'token-owner' }) }) },
    getMissingMercadoPagoOAuthConfig: () => [], db: {}, oauthStateStore: () => ({ issue: async value => { uid = value; issued++; return 'nonce'; } }),
    URL, MERCADO_PAGO_OAUTH_AUTHORIZE_URL: 'https://auth.mercadopago.com.br/authorization', MERCADO_PAGO_CLIENT_ID: 'fixture',
    MERCADO_PAGO_REDIRECT_URI: 'https://api.meutorico.com.br/integrations/mercado-pago/callback', console: { warn() {} } });
  vm.runInContext(source.slice(start, end), context);
  const res = { set() {}, status(code) { status = code; return res; }, json(value) { body = value; } };
  await handler({ headers: {}, query: { userId: 'victim' } }, res);
  assert.equal(status, 401); assert.equal(issued, 0);
  await handler({ headers: { authorization: 'Bearer fixture' }, query: { userId: 'victim' } }, res);
  assert.equal(uid, 'token-owner'); assert.equal(issued, 1);
  const url = new URL(body.authorizationUrl);
  assert.equal(url.searchParams.get('state'), 'nonce');
  assert.equal(url.searchParams.get('redirect_uri'), 'https://api.meutorico.com.br/integrations/mercado-pago/callback');
  assert.equal(url.searchParams.has('userId'), false);
});

test('demo runtime rejects mixed project/credentials/Cloud Run configurations', () => {
  const demo = { FIREBASE_PROJECT_ID: 'demo-local', FIREBASE_AUTH_EMULATOR_HOST: '127.0.0.1:19099', FIRESTORE_EMULATOR_HOST: '127.0.0.1:18891' };
  validateEmulatorIsolation({ FIREBASE_PROJECT_ID: 'torico-ca479' });
  validateEmulatorIsolation(demo);
  for (const extra of [{ FIREBASE_PROJECT_ID: 'torico-ca479' }, { K_SERVICE: 'cloud' }, { GOOGLE_APPLICATION_CREDENTIALS: 'file' },
    { FIRESTORE_EMULATOR_HOST: '' }, { GCLOUD_PROJECT: 'other-project' }]) {
    assert.throws(() => validateEmulatorIsolation({ ...demo, ...extra }), /startup refused/);
  }
  assert.throws(() => validateEmulatorIsolation({ APP_ENV: 'development', FIREBASE_PROJECT_ID: 'torico-ca479' }), /startup refused/);
});

test('stable PWA routes revalidate; immutable is restricted to explicit hashed asset directory', () => {
  const config = JSON.parse(readFileSync(new URL('../../firebase.json', import.meta.url)));
  const rules = config.hosting.headers;
  const cache = rule => rule.headers.find(h => h.key === 'Cache-Control').value;
  assert.match(cache(rules.find(r => r.source === '**')), /no-cache.*must-revalidate/);
  assert.deepEqual(rules.filter(r => cache(r).includes('immutable')).map(r => r.source), ['/releases/**']);
  // Both old shell and old worker are forced to revalidate after cache expiry.
  for (const path of ['/', '/account', '/main.dart.js', '/flutter_service_worker.js', '/flutter_bootstrap.js', '/version.json']) {
    const rule = rules.find(r => r.source === '**');
    assert.ok(rule, path); assert.doesNotMatch(cache(rule), /immutable/);
  }
});

test('two PWA builds use distinct content-versioned URLs and re-running is stable', () => {
  const root = mkdtempSync(join(tmpdir(), 'torico-web-cache-'));
  writeFileSync(join(root, 'main.dart.js'), 'release one');
  writeFileSync(join(root, 'flutter_bootstrap.js'), '/* TORICO_IMMUTABLE_BOOTSTRAP_V1 */ _flutter.buildConfig={"mainJsPath":"main.dart.js"}');
  writeFileSync(join(root, 'index.html'), '<script src="flutter_bootstrap.js"></script>');
  writeFileSync(join(root, 'flutter_service_worker.js'), 'self.registration.unregister();');
  const one = versionWebShell(root);
  assert.deepEqual(versionWebShell(root), one);
  writeFileSync(join(root, 'main.dart.js'), 'release two');
  const two = versionWebShell(root);
  assert.notEqual(one.mainSha256, two.mainSha256);
  assert.notEqual(one.releaseId, two.releaseId);
  assert.ok(readFileSync(join(root, 'index.html'), 'utf8').includes(two.releaseId));
  assert.equal(readFileSync(join(root, 'releases', one.releaseId, 'main.dart.js'), 'utf8'), 'release one');
  assert.equal(readFileSync(join(root, 'releases', two.releaseId, 'main.dart.js'), 'utf8'), 'release two');
  writeFileSync(join(root, 'flutter_service_worker.js'), 'const RESOURCES = {};');
  assert.throws(() => versionWebShell(root), /separate upgrade review/);
});
