// Test orchestrator. Every data operation is confined to freshly started emulators.
import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { spawn } from 'node:child_process';
import { once } from 'node:events';
import { mkdirSync, openSync, closeSync, existsSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { createServer } from 'node:net';
import admin from 'firebase-admin';
import { Firestore } from '@google-cloud/firestore';
import { intakeEnabled } from '../account-deletion-gate.js';

const env = process.env, projectId = 'demo-torico-intake';
assert.equal(env.TORICO_INTAKE_EMULATOR_TEST, projectId);
assert.equal(env.FIREBASE_PROJECT_ID, projectId);
assert.equal(env.FIREBASE_AUTH_EMULATOR_HOST, '127.0.0.1:19099');
assert.equal(env.FIRESTORE_EMULATOR_HOST, '127.0.0.1:18891');
assert.ok(intakeEnabled(env));
assert.ok(!existsSync('.env') && !existsSync('backend/.env'));
for (const port of [18891, 19099, 18893]) {
  await new Promise((ok, reject) => {
    const probe = createServer(); probe.once('error', reject);
    probe.listen(port, '127.0.0.1', () => probe.close(ok));
  });
}
const flutterRoot = resolve(process.argv[4]);
const dart = resolve(flutterRoot, 'bin/cache/dart-sdk/bin', process.platform === 'win32' ? 'dart.exe' : 'dart');
const tool = resolve(flutterRoot, 'bin/cache/flutter_tools.snapshot');
assert.ok(existsSync(dart) && existsSync(tool), 'Use an already installed Flutter SDK');
const require = createRequire(import.meta.url);
const { AuthEmulator } = require(resolve(process.argv[2]));
const emulator = new AuthEmulator({ projectId, host: '127.0.0.1', port: 19099, singleProjectMode: 2 });
const artifactsBase = resolve('.tmp-deletion-integrated');
const root = resolve(artifactsBase, 'run-' + new Date().toISOString().replace(/[:.]/g, '-'));
mkdirSync(root, { recursive: true });
const logs = [];
function logFile(name) { const fd = openSync(resolve(root, name), 'a'); logs.push(fd); return fd; }
const firestoreLog = logFile('firestore.log'), backendLog = logFile('backend.log');
const result = { project: projectId, hosts: ['127.0.0.1'], productionCredentials: false, checks: [] };
function pass(name) { result.checks.push(name); console.log('PASS ' + name); }
let firestore, backend, app, db;
async function stop(child) {
  if (child?.pid && child.exitCode === null && child.signalCode === null) {
    const ended = once(child, 'exit'); child.kill(); await ended;
  }
}
async function ready(url, child) {
  for (let i = 0; i < 120; i++) {
    if (child?.exitCode !== null && child?.exitCode !== undefined) throw Error('Local child exited before readiness');
    try { if ((await fetch(url, { signal: AbortSignal.timeout(500) })).ok) return; } catch (_) {}
    await new Promise(r => setTimeout(r, 250));
  }
  throw Error('Local readiness timed out');
}
async function startBackend(overrides = {}) {
  backend = spawn(process.execPath, ['test-support/account-deletion-local-backend.mjs'], {
    cwd: resolve('backend'), env: { ...env, ...overrides }, stdio: ['ignore', backendLog, backendLog], windowsHide: true,
  });
  await ready('http://127.0.0.1:18893/health', backend);
}
async function flutter(phase) {
  const args = [tool, 'test', '--no-pub', '--reporter', 'expanded',
    '--dart-define=TORICO_TEST_PROJECT=demo-torico-intake',
    `--dart-define=TORICO_TEST_OUTAGE=${phase === 'outage'}`,
    'test-support/flutter/account_deletion_emulator_flow_test.dart'];
  const fd = logFile(`flutter-${phase}.log`);
  const child = spawn(dart, args, { env: { ...env, FLUTTER_ROOT: flutterRoot }, stdio: ['ignore', 'pipe', 'pipe'], windowsHide: true });
  // Test names/statuses only are printed; Auth response bodies are never logged.
  const { writeSync } = await import('node:fs');
  child.stdout.on('data', chunk => { writeSync(fd, chunk); process.stdout.write(chunk); });
  child.stderr.on('data', chunk => { writeSync(fd, chunk); process.stderr.write(chunk); });
  const timer = setTimeout(() => child.kill(), 180000);
  try { const [code] = await once(child, 'exit'); assert.equal(code, 0, `Flutter ${phase} must pass`); }
  finally { clearTimeout(timer); await stop(child); }
}
try {
  firestore = spawn('java', ['-jar', resolve(process.argv[3]), '--host', '127.0.0.1', '--port', '18891',
    '--project_id', projectId, '--single_project_mode', 'true', '--single_project_mode_error', 'true',
    '--rules', resolve('firestore.rules')], { env, stdio: ['ignore', firestoreLog, firestoreLog], windowsHide: true });
  await ready('http://127.0.0.1:18891/', firestore);
  await emulator.start();
  app = admin.initializeApp({ projectId,
    credential: { getAccessToken: async () => ({ access_token: 'owner', expires_in: 3600 }) } }, 'integrated-demo');
  const auth = app.auth();
  db = new Firestore({ projectId, host: env.FIRESTORE_EMULATOR_HOST, ssl: false });
  const protectedDocs = [];
  const before = [];
  for (const name of ['integrated-a', 'integrated-b']) {
    const user = await auth.createUser({ email: `${name}@example.invalid`, password: 'emulator-fixture-only-123', emailVerified: true });
    for (const [path, value] of [
      [`users/${user.uid}`, { displayName: 'Local fixture' }],
      [`users/${user.uid}/sales/fixture-sale`, { amount: 12, status: 'approved' }],
      [`users/${user.uid}/daily_totals/fixture-day`, { totalSold: 12 }],
      [`users/${user.uid}/integrations/mercado_pago`, { status: 'connected', encryptedAccessToken: 'fixture-ciphertext-not-valid' }],
      [`users/${user.uid}/integration_status/mercado_pago`, { status: 'connected' }],
    ]) {
      const ref = db.doc(path); await ref.set(value); protectedDocs.push(ref); before.push(value);
    }
  }
  pass('isolated demo emulators, fictitious users, credentials-free child environment');
  await assert.rejects(startBackend({ K_SERVICE: 'local-cloudrun-simulation' }), /Local child exited before readiness/);
  assert.equal(backend.exitCode, 1);
  await stop(backend);
  for (const configuration of [{ ACCOUNT_DELETION_INTAKE_ENABLED: 'false' }]) {
    await startBackend(configuration);
    const response = await fetch('http://127.0.0.1:18893/v1/account-deletion/requests', {
      method: 'POST', headers: { 'Content-Type': 'application/json' }, body: '{' + 'x'.repeat(3000),
    });
    assert.equal(response.status, 404);
    assert.equal((await response.json()).code, 'feature_disabled');
    await stop(backend);
  }
  pass('actual server fails closed for Cloud Run marker and disabled flag before parsing');
  await startBackend();
  await flutter('normal');
  pass('Flutter service and screen -> actual backend -> Auth/Firestore Emulator');
  for (let i = 0; i < protectedDocs.length; i++) assert.deepEqual((await protectedDocs[i].get()).data(), before[i]);
  assert.equal((await auth.listUsers()).users.length, 2);
  assert.equal((await db.collection('account_deletion_requests').get()).size, 2);
  assert.equal((await db.collection('account_deletion_uid_index').get()).size, 2);
  assert.equal((await db.collection('account_lifecycle').get()).empty, true);
  for (const doc of (await db.collection('account_deletion_outbox').get()).docs) assert.equal(doc.data().executionAllowed, false);
  pass('profiles, sales, totals, integration ciphertext/status and Auth users preserved; only two protocols; no lifecycle');
  await stop(firestore);
  await flutter('outage');
  pass('actual Firestore outage does not confirm receipt');
  result.status = 'passed';
} catch (error) {
  result.status = 'failed';
  throw error;
} finally {
  await stop(backend);
  if (db) await db.terminate();
  if (app) await app.delete(); // Dispose local SDK instance, never delete an Auth user.
  await emulator.stop();
  await stop(firestore);
  for (const fd of logs) closeSync(fd);
  writeFileSync(resolve(root, 'summary.json'), JSON.stringify(result, null, 2));
  writeFileSync(resolve(artifactsBase, 'latest.json'), JSON.stringify({ runDirectory: root, ...result }, null, 2));
}
