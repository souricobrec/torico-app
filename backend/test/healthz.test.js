import { test } from 'node:test';
import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { once } from 'node:events';
import { existsSync } from 'node:fs';

test('healthz serves the public liveness contract without cloud credentials', async () => {
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
    assert.deepEqual(await response.json(), {
      ok: true, service: 'torico-backend', status: 'healthy',
    });
  } finally {
    if (server.exitCode === null) {
      const stopped = once(server, 'exit');
      server.kill();
      await stopped;
    }
  }
});
