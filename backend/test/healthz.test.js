import { test } from 'node:test';
import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { once } from 'node:events';
import { existsSync } from 'node:fs';

async function verifyHealth(environment, detailedPublic = false) {
  assert.equal(existsSync(new URL('../.env', import.meta.url)), false,
    'Run this isolated test without backend/.env');
  const testPort = String(20000 + Math.floor(Math.random() * 20000));
  const server = spawn(process.execPath, ['server.js'], {
    cwd: new URL('../', import.meta.url),
    env: {
      PATH: process.env.PATH,
      SystemRoot: process.env.SystemRoot,
      PORT: testPort,
      FIREBASE_PROJECT_ID: 'torico-healthz-local-test',
      ...environment,
      ACCOUNT_DELETION_INTAKE_ENABLED: environment.FIREBASE_PROJECT_ID?.startsWith('demo-') ? 'false' : 'true', // Health fixture never enables intake.
    },
    stdio: ['ignore', 'pipe', 'pipe'],
  });
  let output = '';
  const ready = new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error('Server startup timed out')), 15000);
    server.stdout.on('data', chunk => {
      output += chunk;
      const match = output.match(/porta (\d+)/);
      if (match) { clearTimeout(timer); resolve(match[1]); }
    });
    server.once('exit', () => { clearTimeout(timer); reject(new Error('Server exited before ready')); });
  });
  try {
    const port = await ready;
    const response = await fetch(`http://127.0.0.1:${port}/healthz`);
    assert.equal(response.status, 200);
    assert.match(response.headers.get('content-type'), /application\/json/);
    assert.equal(response.headers.get('cache-control'), 'no-store');
    const intake = await fetch(`http://127.0.0.1:${port}/v1/account-deletion/requests`, {
      method: 'POST', headers: { 'content-type': 'application/json' }, body: '{}',
    });
    assert.equal(intake.status, 404);
    assert.equal((await intake.json()).code, 'feature_disabled');
    const minimal = {
      ok: true, service: 'torico-backend', status: 'healthy',
    };
    assert.deepEqual(await response.json(), minimal);
    const get = async (path, headers = {}) => {
      const result = await fetch(`http://127.0.0.1:${port}${path}`, { headers });
      assert.equal(result.status, 200);
      if (path !== '/') assert.equal(result.headers.get('cache-control'), 'no-store');
      return result.json();
    };
    assert.equal((await get('/')).health, '/health');
    if (detailedPublic) {
      assert.equal((await get('/health')).projectId, environment.FIREBASE_PROJECT_ID || 'torico-healthz-local-test');
    } else {
      assert.deepEqual(await get('/health'), minimal);
      for (const key of ['wrong', 'invalid-health-key!!']) {
        assert.deepEqual(await get('/health', { 'x-health-key': key }), minimal);
      }
      assert.deepEqual(await get('/health?key=test-only-health-key'), minimal);
    }
    if (environment.HEALTH_DETAILS_KEY) {
      const headers = { 'x-health-key': environment.HEALTH_DETAILS_KEY };
      assert.deepEqual(await get('/healthz', headers), minimal);
      const details = await get('/health', headers);
      assert.equal(details.projectId, 'torico-healthz-local-test');
      for (const name of ['mercadoPago', 'pagBank', 'stone', 'rede']) assert.ok(details[name]);
      assert.equal(JSON.stringify(details).includes(environment.HEALTH_DETAILS_KEY), false);
    }
  } finally {
    if (server.exitCode === null) {
      const stopped = once(server, 'exit');
      server.kill();
      await stopped;
    }
  }
}

test('production health is minimal; dedicated internal key authorizes details', async () => {
  await verifyHealth({ NODE_ENV: 'production', HEALTH_DETAILS_KEY: 'test-only-health-key' });
});
test('unset environment fails closed without an internal key', async () => {
  await verifyHealth({});
});
test('Cloud Run never enables anonymous local diagnostics', async () => {
  await verifyHealth({ NODE_ENV: 'production', K_SERVICE: 'torico-backend' });
});
test('explicit local development preserves detailed health', async () => {
  await verifyHealth({ NODE_ENV: 'development', FIREBASE_PROJECT_ID: 'demo-healthz-local', FIREBASE_AUTH_EMULATOR_HOST: '127.0.0.1:19099', FIRESTORE_EMULATOR_HOST: '127.0.0.1:18891' }, true);
});
