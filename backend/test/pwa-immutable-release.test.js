import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, writeFileSync, readFileSync, mkdirSync, existsSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { createServer } from 'node:http';
import { versionWebShell } from '../../scripts/version-web-shell.mjs';

function buildFixture(main, engine = 'engine') {
  const root = mkdtempSync(join(tmpdir(), 'torico-release-fixture-'));
  mkdirSync(join(root, 'assets')); mkdirSync(join(root, 'canvaskit'));
  writeFileSync(join(root, 'index.html'), '<script src="flutter_bootstrap.js" async></script>');
  writeFileSync(join(root, 'flutter_bootstrap.js'), '/* TORICO_IMMUTABLE_BOOTSTRAP_V1 */ const base = new URL(".", document.currentScript.src);');
  writeFileSync(join(root, 'main.dart.js'), main);
  writeFileSync(join(root, 'flutter_service_worker.js'), 'self.registration.unregister();');
  writeFileSync(join(root, 'assets', 'fixture.json'), main);
  writeFileSync(join(root, 'canvaskit', 'fixture.wasm'), engine);
  return root;
}

test('old/new bootstrap bundles, assets and engine remain in their own immutable snapshots', async () => {
  const first = buildFixture('release-one', 'engine-one');
  const a = versionWebShell(first);
  const second = buildFixture('release-two', 'engine-two');
  const b = versionWebShell(second, { previousRoots: [first] });
  assert.notEqual(a.releaseId, b.releaseId);
  assert.deepEqual(versionWebShell(second, { previousRoots: [first] }), b);
  const server = createServer((req, res) => {
    const path = new URL(req.url, 'http://localhost').pathname;
    if (!/^\/releases\/[a-f0-9]{64}\/(main\.dart\.js|assets\/fixture\.json|canvaskit\/fixture\.wasm)$/.test(path)) {
      res.writeHead(404).end(); return;
    }
    res.end(readFileSync(join(second, path)));
  });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  try {
    for (const [release, main, engine] of [[a, 'release-one', 'engine-one'], [b, 'release-two', 'engine-two']]) {
      for (const [path, expected] of [['main.dart.js', main], ['assets/fixture.json', main], ['canvaskit/fixture.wasm', engine]]) {
        const response = await fetch(`http://127.0.0.1:${server.address().port}${release.basePath}${path}`);
        assert.equal(response.status, 200); assert.equal(await response.text(), expected);
      }
    }
    // Restore only the old shell; the complete old dependency graph is present.
    writeFileSync(join(second, 'index.html'), readFileSync(join(first, 'index.html')));
    assert.ok(readFileSync(join(second, 'index.html'), 'utf8').includes(a.releaseId));
  } finally { await new Promise(resolve => server.close(resolve)); }
});

test('tampered previous artifact or unknown bootstrap blocks assembly before switching the shell', () => {
  const first = buildFixture('release-one');
  const a = versionWebShell(first);
  writeFileSync(join(first, 'releases', a.releaseId, 'main.dart.js'), 'tampered');
  const second = buildFixture('release-two');
  const before = readFileSync(join(second, 'index.html'), 'utf8');
  assert.throws(() => versionWebShell(second, { previousRoots: [first] }), /mismatch/);
  assert.equal(readFileSync(join(second, 'index.html'), 'utf8'), before);
  writeFileSync(join(second, 'flutter_bootstrap.js'), 'unknown');
  assert.throws(() => versionWebShell(second), /Rebuild/);
  assert.equal(existsSync(join(second, 'torico-release.json')), false);
});

test('official bootstrap config pins all engine and asset base URLs to the current script snapshot', () => {
  const source = readFileSync(new URL('../../web/flutter_bootstrap.js', import.meta.url), 'utf8');
  assert.match(source, /document\.currentScript\.src/);
  for (const key of ['entrypointBaseUrl', 'assetBase', 'canvasKitBaseUrl']) assert.ok(source.includes(key));
  assert.doesNotMatch(source, /serviceWorkerSettings/);
});
