// Ephemeral in-memory keys and fictitious inventory. Never production tooling.
import { createCertificationTrust, configureCertificationRuntime } from '../certification-runtime.js';
import { memoryCertificationAnchor } from './memory-certification-anchor.mjs';
import { generateKeyPairSync, sign } from 'node:crypto';
import { CERT_PROTOCOL, reconcileInventory, evidenceHash, stableJSON } from '../mp-index-certification.js';

const keys = [generateKeyPairSync('ed25519'), generateKeyPairSync('ed25519')];
export const fixtureTrust = Object.freeze({
  MP_INDEX_CERTIFIER_PUBLIC_KEY: keys[0].publicKey.export({ type: 'spki', format: 'pem' }),
  MP_INDEX_REVIEWER_PUBLIC_KEY: keys[1].publicKey.export({ type: 'spki', format: 'pem' }),
});
export const signFixturePayload = payload => ({ payload, signatures: keys.map(key => sign(null, Buffer.from(stableJSON(payload)), key.privateKey).toString('base64url')) });

export function certificationFixture(entries, { projectId = 'demo-index-unit', epoch = 'fixture-v1', now = Date.now(), generation = 1 } = {}) {
  if (!projectId.startsWith('demo-')) throw Error('Synthetic project only');
  const sources = [], owners = [];
  for (const { id, userId, conflict = false } of entries) {
    owners.push({ id, data: { indexVersion: 1, indexEpoch: epoch, state: conflict ? 'conflict' : 'owned', ...(userId ? { userId } : {}) } });
    if (conflict) {
      sources.push({ path: `mp_account_owners/${id}`, data: { userId: 'fixture-conflict-a' } },
        { path: `mp_account_owners/00${id}`, data: { userId: 'fixture-conflict-b' } });
    } else sources.push({ path: `mp_account_owners/${id}`, data: { userId } });
  }
  const plan = reconcileInventory({ sources, owners, epoch });
  const sourceRevision = evidenceHash({ fixture: true, sourceDigest: plan.sourceDigest });
  const payload = { version: 1, generation, projectId, epoch, sourceRevision, writerProtocol: CERT_PROTOCOL,
    capturedAtMs: now - 1000, issuedAtMs: now - 500, expiresAtMs: now + 3600000,
    sourceDigest: plan.sourceDigest, indexDigest: plan.indexDigest, sourceCount: plan.sourceCount,
    merchantCount: plan.merchantCount, shardDigests: plan.shardDigests };
  const certificateId = evidenceHash(payload);
  return { owners, shards: plan.shards, certificate: signFixturePayload(payload),
    marker: { version: 1, generation, state: 'ready', epoch, certificateId, sourceRevision, writerProtocol: CERT_PROTOCOL } };
}

export function fixtureTrustedContext(marker, { projectId = 'demo-index-unit', clock = Date.now, publicKeys = Object.values(fixtureTrust) } = {}) {
  return { ...createCertificationTrust({ projectId, publicKeys, clock }),
    anchor: { projectId, generation: marker.generation, certificateId: marker.certificateId, state: 'active' } };
}
const anchors = new WeakMap();
export function fixtureAnchor(db) {
  if (!db.projectId.startsWith('demo-')) throw Error('Demo project required');
  if (!anchors.has(db)) anchors.set(db, memoryCertificationAnchor(db.projectId));
  return anchors.get(db);
}
export async function activateFixtureCertificate(db, marker, { clock = Date.now } = {}) {
  const anchor = fixtureAnchor(db);
  const previous = await anchor.read();
  await anchor.advance(previous?.generation ?? 0, { projectId: db.projectId,
    generation: marker.generation, certificateId: marker.certificateId, state: 'active' });
  configureCertificationRuntime(db, { trust: createCertificationTrust({ projectId: db.projectId,
    publicKeys: Object.values(fixtureTrust), clock }), anchor });
  return anchor;
}
