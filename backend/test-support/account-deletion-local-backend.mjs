// Test-only launcher of the actual backend. Never imported by production.
import assert from 'node:assert/strict';
import { existsSync } from 'node:fs';
import { Server } from 'node:net';
import { Server as HttpServer } from 'node:http';
assert.equal(process.env.FIREBASE_PROJECT_ID, 'demo-torico-intake');
assert.equal(process.env.FIREBASE_AUTH_EMULATOR_HOST, '127.0.0.1:19099');
assert.equal(process.env.FIRESTORE_EMULATOR_HOST, '127.0.0.1:18891');
for (const key of ['GOOGLE_APPLICATION_CREDENTIALS', 'FIREBASE_SERVICE_ACCOUNT_PATH',
  'FIREBASE_TOKEN', 'MERCADO_PAGO_CLIENT_SECRET', 'TOKEN_ENCRYPTION_KEY']) assert.ok(!process.env[key]);
assert.equal(existsSync('.env'), false, 'Refuse dotenv before importing the backend');
// server.js normally binds 0.0.0.0. Override ONLY this test process, without
// introducing a new production flag or exposing the integration test on LAN.
const listen = Server.prototype.listen;
Server.prototype.listen = function (port, host, callback) {
  assert.equal(String(port), '18893');
  assert.equal(host, '0.0.0.0');
  return listen.call(this, port, '127.0.0.1', callback);
};
// Prevent accidental invocation of unrelated integrations in this test process.
const emit = HttpServer.prototype.emit;
HttpServer.prototype.emit = function (event, ...args) {
  if (event === 'request') {
    const [req, res] = args;
    const path = new URL(req.url, 'http://127.0.0.1').pathname;
    if (!['/health', '/healthz', '/v1/account-deletion'].includes(path) &&
        !path.startsWith('/v1/account-deletion/')) {
      res.writeHead(404, { 'Content-Type': 'application/json' });
      res.end('{"ok":false,"code":"test_route_blocked"}');
      return true;
    }
  }
  return emit.call(this, event, ...args);
};
await import('../server.js');
