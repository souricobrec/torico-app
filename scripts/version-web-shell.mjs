// Local release assembly only: no deploy, credentials, deletion or network.
import { readFileSync, writeFileSync, readdirSync, lstatSync, mkdirSync, existsSync, renameSync } from 'node:fs';
import { resolve, dirname, sep } from 'node:path';
import { pathToFileURL } from 'node:url';
import { createHash } from 'node:crypto';
const hash = value => createHash('sha256').update(value).digest('hex');
const releaseHash = files => hash(JSON.stringify(Object.entries(files).sort(([a], [b]) => a < b ? -1 : a > b ? 1 : 0)));
const shellPattern = /src="(?:\/?releases\/[a-f0-9]{64}\/)?flutter_bootstrap\.js(?:\?v=[a-f0-9]+)?"/;

function child(root, path) {
  const target = resolve(root, path);
  if (!target.startsWith(resolve(root) + sep)) throw Error('Invalid snapshot path.');
  let current = target;
  while (current !== resolve(root)) {
    if (existsSync(current) && lstatSync(current).isSymbolicLink()) throw Error('Symlinks are forbidden in releases.');
    current = dirname(current);
  }
  if (existsSync(root) && lstatSync(root).isSymbolicLink()) throw Error('Symlinks are forbidden in releases.');
  return target;
}
function inventory(root, prefix = '', sealed = false) {
  const files = {};
  for (const entry of readdirSync(resolve(root, prefix), { withFileTypes: true })) {
    const name = prefix ? `${prefix}/${entry.name}` : entry.name;
    if ((!prefix && !sealed && ['releases', 'torico-release.json'].includes(name)) || name === 'release-manifest.json') continue;
    const path = child(root, name);
    if (lstatSync(path).isSymbolicLink()) throw Error('Symlinks are forbidden in releases.');
    if (entry.isDirectory()) Object.assign(files, inventory(root, name, sealed));
    else if (entry.isFile()) {
      const data = readFileSync(path);
      files[name] = !sealed && name === 'index.html' ? Buffer.from(data.toString('utf8').replace(shellPattern, 'src="flutter_bootstrap.js"')) : data;
    }
  }
  return files;
}
function verifySnapshot(root, id) {
  const manifest = JSON.parse(readFileSync(child(root, 'release-manifest.json'), 'utf8'));
  if (manifest.version !== 1 || manifest.id !== id || releaseHash(manifest.files) !== id) throw Error('Invalid immutable manifest.');
  const files = inventory(root, '', true);
  if (Object.keys(files).length !== Object.keys(manifest.files).length) throw Error('Unexpected immutable files.');
  for (const [name, digest] of Object.entries(manifest.files)) {
    if (!files[name] || hash(files[name]) !== digest) throw Error('Immutable snapshot content mismatch.');
  }
  return files;
}
function preserveSnapshot(source, destination, id) {
  const files = verifySnapshot(source, id);
  if (existsSync(destination)) { verifySnapshot(destination, id); return; }
  for (const [name, data] of Object.entries(files)) {
    const path = child(destination, name); mkdirSync(dirname(path), { recursive: true });
    writeFileSync(path, data, { flag: 'wx' });
  }
  writeFileSync(child(destination, 'release-manifest.json'), readFileSync(child(source, 'release-manifest.json')), { flag: 'wx' });
}

export function versionWebShell(root, { previousRoots = [] } = {}) {
  root = resolve(root);
  const files = inventory(root);
  const boot = files['flutter_bootstrap.js']?.toString('utf8') || '';
  const index = files['index.html']?.toString('utf8') || '';
  const worker = files['flutter_service_worker.js']?.toString('utf8') || '';
  if (!files['main.dart.js'] || !boot.includes('TORICO_IMMUTABLE_BOOTSTRAP_V1') || !shellPattern.test(index)) {
    throw Error('Rebuild with the TORICO immutable bootstrap before release assembly.');
  }
  if (worker.includes('RESOURCES') || worker.includes('cache.addAll')) throw Error('Caching worker requires a separate upgrade review.');
  const digests = Object.fromEntries(Object.entries(files).map(([name, data]) => [name, hash(data)]));
  const id = releaseHash(digests);
  const destination = child(root, `releases/${id}`);
  const retained = child(root, 'releases');
  if (existsSync(retained)) {
    for (const item of readdirSync(retained, { withFileTypes: true })) {
      if (!item.isDirectory() || !/^[a-f0-9]{64}$/.test(item.name)) throw Error('Invalid retained release directory.');
      verifySnapshot(child(root, `releases/${item.name}`), item.name);
    }
  }
  // Keep every supplied previous snapshot. Never prune or overwrite a version.
  for (const previous of previousRoots) {
    for (const item of readdirSync(resolve(previous, 'releases'), { withFileTypes: true })) {
      if (!item.isDirectory() || !/^[a-f0-9]{64}$/.test(item.name)) throw Error('Invalid previous release directory.');
      preserveSnapshot(resolve(previous, 'releases', item.name), child(root, `releases/${item.name}`), item.name);
    }
  }
  if (existsSync(destination)) verifySnapshot(destination, id);
  else {
    for (const [name, data] of Object.entries(files)) {
      const path = child(destination, name); mkdirSync(dirname(path), { recursive: true });
      writeFileSync(path, data, { flag: 'wx' });
    }
    writeFileSync(child(destination, 'release-manifest.json'), JSON.stringify({ version: 1, id, files: digests }, null, 2), { flag: 'wx' });
  }
  const shell = index.replace(shellPattern, `src="/releases/${id}/flutter_bootstrap.js"`);
  const next = child(root, 'index.html.next');
  writeFileSync(next, shell, { flag: 'wx' }); renameSync(next, child(root, 'index.html'));
  const result = { releaseId: id, basePath: `/releases/${id}/`, mainSha256: digests['main.dart.js'], bootstrapSha256: digests['flutter_bootstrap.js'] };
  writeFileSync(child(root, 'torico-release.json'), JSON.stringify(result, null, 2));
  return result;
}
if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  const args = process.argv.slice(3);
  if (!args.length || (args.includes('--initial') && args.length !== 1)) {
    throw Error('Provide previous staging roots, or explicitly --initial for the coordinated first immutable release.');
  }
  console.log(JSON.stringify(versionWebShell(resolve(process.argv[2] || 'build/web'), { previousRoots: args[0] === '--initial' ? [] : args })));
}
