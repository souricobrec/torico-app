// Local post-build only. No Firebase CLI, credentials, deployment or data access.
import { readFileSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { pathToFileURL } from 'node:url';
import { createHash } from 'node:crypto';
export function versionWebShell(root) {
  const hash = value => createHash('sha256').update(value).digest('hex');
  const main = readFileSync(resolve(root, 'main.dart.js'));
  const bootPath = resolve(root, 'flutter_bootstrap.js');
  const indexPath = resolve(root, 'index.html');
  const boot = readFileSync(bootPath, 'utf8');
  const index = readFileSync(indexPath, 'utf8');
  const worker = readFileSync(resolve(root, 'flutter_service_worker.js'), 'utf8');
  if (worker.includes('RESOURCES') || worker.includes('cache.addAll')) {
    throw new Error('Caching service worker needs a separate upgrade review. Use a non-caching Flutter worker.');
  }
  const entry = /"mainJsPath"\s*:\s*"main\.dart\.js(?:\?v=[a-f0-9]+)?"/g;
  if (!boot.match(entry) || !/src="flutter_bootstrap\.js(?:\?v=[a-f0-9]+)?"/.test(index)) {
    throw new Error('Unknown Flutter bootstrap structure; no files changed.');
  }
  const updated = boot.replace(entry, `"mainJsPath":"main.dart.js?v=${hash(main)}"`);
  const shell = index.replace(/src="flutter_bootstrap\.js(?:\?v=[a-f0-9]+)?"/,
    `src="flutter_bootstrap.js?v=${hash(updated)}"`);
  writeFileSync(bootPath, updated);
  writeFileSync(indexPath, shell);
  return { mainSha256: hash(main), bootstrapSha256: hash(updated) };
}
if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  console.log(JSON.stringify(versionWebShell(resolve(process.argv[2] || 'build/web'))));
}
