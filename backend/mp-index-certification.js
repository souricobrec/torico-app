// Pure reconciliation + read-only runtime verification. No signing keys,
// credential discovery, network collector, migration or certification writer.
import { createHash, createPublicKey, verify } from 'node:crypto';
import { canonicalMerchantId } from './mercado-pago-id.js';

export const CERT_MAX_AGE_MS = 86400000;
export const CERT_PROTOCOL = 'certified-index-v1';
const fail = code => Object.assign(new Error(code), { status: 503, code });
export function stableJSON(value) {
  if (Array.isArray(value)) return `[${value.map(stableJSON).join(',')}]`;
  if (value && typeof value === 'object') return `{${Object.keys(value).sort().map(k => `${JSON.stringify(k)}:${stableJSON(value[k])}`).join(',')}}`;
  return JSON.stringify(value);
}
export const evidenceHash = value => createHash('sha256').update(stableJSON(value)).digest('hex');
export const merchantPrefix = id => createHash('sha256').update(id).digest('hex').slice(0, 2);
const hex = value => typeof value === 'string' && /^[a-f0-9]{64}$/.test(value);
const validUid = value => typeof value === 'string' && value.length > 0 && value.length <= 128 && !value.includes('/');
const validEpoch = value => typeof value === 'string' && /^[a-zA-Z0-9_-]{1,80}$/.test(value);
export const emptyShard = () => ({ version: 1, claims: Object.create(null) });
const shardHash = shard => {
  if (Buffer.byteLength(stableJSON(shard)) > 512000) throw fail('certification_shard_capacity');
  return evidenceHash(shard);
};

// Inputs must come from a consistent, independently reviewed inventory, not
// from requests or a best-effort live scan. This function cannot prove capture
// completeness or the absence of uncoordinated external writers.
export function reconcileInventory({ sources, owners, epoch }) {
  if (!validEpoch(epoch) || !Array.isArray(sources) || !Array.isArray(owners)) throw fail('inventory_invalid');
  const groups = new Map(), paths = new Set(), normalized = [];
  for (const row of sources) {
    if (typeof row.path !== 'string' || paths.has(row.path)) throw fail('inventory_duplicate_path');
    paths.add(row.path);
    const integration = /^users\/([^/]+)\/integrations\/mercado_pago$/.exec(row.path);
    const alias = /^mp_account_owners\/([^/]+)$/.exec(row.path);
    if (!integration && !alias) {
      if (row.data?.platformId === 'mercado_pago') throw fail('inventory_unexpected_path');
      continue;
    }
    const uid = integration ? integration[1] : row.data?.userId;
    if (!validUid(uid)) throw fail('inventory_invalid_uid');
    let id;
    try { id = canonicalMerchantId(integration ? row.data?.mercadoPagoUserId : alias[1]); }
    catch { throw fail('inventory_unresolved_identifier'); }
    if (!groups.has(id)) groups.set(id, new Set());
    groups.get(id).add(uid);
    normalized.push({ path: row.path, id, uid });
  }
  const index = new Map();
  for (const row of owners) {
    let id;
    try { id = canonicalMerchantId(row.id); } catch { throw fail('inventory_index_invalid'); }
    if (row.id !== id || index.has(id)) throw fail('inventory_index_duplicate');
    index.set(id, row.data);
  }
  const shards = Object.fromEntries(Array.from({ length: 256 }, (_, n) => [n.toString(16).padStart(2, '0'), emptyShard()]));
  const expectedOwners = [];
  for (const [id, uids] of [...groups.entries()].sort(([a], [b]) => a < b ? -1 : a > b ? 1 : 0)) {
    const claim = uids.size === 1 ? { state: 'owned', userId: [...uids][0] } : { state: 'conflict' };
    const actual = index.get(id);
    if (!actual || actual.indexVersion !== 1 || actual.indexEpoch !== epoch || actual.state !== claim.state ||
        (claim.state === 'owned' && actual.userId !== claim.userId) || (actual.merchantId != null && actual.merchantId !== id)) {
      throw fail('inventory_index_incomplete_or_conflicting');
    }
    shards[merchantPrefix(id)].claims[id] = claim;
    expectedOwners.push({ id, ...claim });
  }
  if (index.size !== groups.size) throw fail('inventory_index_extra');
  return {
    shards,
    sourceDigest: evidenceHash(normalized.sort((a, b) => a.path < b.path ? -1 : a.path > b.path ? 1 : 0)),
    indexDigest: evidenceHash(expectedOwners), sourceCount: normalized.length, merchantCount: groups.size,
    shardDigests: Object.fromEntries(Object.entries(shards).map(([prefix, shard]) => [prefix, shardHash(shard)])),
  };
}

// Trust anchors come only from deployment-controlled public configuration,
// never from certificate contents. Production provisioning is NOT implemented.
export function verifyCertificate(envelope, { projectId, epoch, sourceRevision, certificateId, now = Date.now(), env = process.env }) {
  try {
    const { payload, signatures } = envelope || {};
    if (!payload || payload.version !== 1 || payload.projectId !== projectId || payload.epoch !== epoch ||
        payload.sourceRevision !== sourceRevision || !hex(sourceRevision) || payload.writerProtocol !== CERT_PROTOCOL ||
        evidenceHash(payload) !== certificateId || !hex(payload.sourceDigest) || !hex(payload.indexDigest) ||
        !Number.isSafeInteger(payload.sourceCount) || payload.sourceCount < 0 ||
        !Number.isSafeInteger(payload.merchantCount) || payload.merchantCount < 0 || payload.merchantCount > payload.sourceCount ||
        !Number.isSafeInteger(payload.capturedAtMs) || !Number.isSafeInteger(payload.issuedAtMs) || !Number.isSafeInteger(payload.expiresAtMs) ||
        payload.capturedAtMs > payload.issuedAtMs || payload.issuedAtMs > now || payload.expiresAtMs <= now ||
        payload.expiresAtMs <= payload.issuedAtMs || payload.expiresAtMs - payload.capturedAtMs > CERT_MAX_AGE_MS ||
        !payload.shardDigests || Object.keys(payload.shardDigests).length !== 256 ||
        !Array.isArray(signatures) || signatures.length !== 2) throw Error();
    for (let n = 0; n < 256; n++) if (!hex(payload.shardDigests[n.toString(16).padStart(2, '0')])) throw Error();
    const anchors = [env.MP_INDEX_CERTIFIER_PUBLIC_KEY, env.MP_INDEX_REVIEWER_PUBLIC_KEY].map(pem => createPublicKey(pem));
    if (anchors.some(key => key.asymmetricKeyType !== 'ed25519') ||
        anchors[0].export({ type: 'spki', format: 'der' }).equals(anchors[1].export({ type: 'spki', format: 'der' }))) throw Error();
    anchors.forEach((key, i) => {
      if (typeof signatures[i] !== 'string' || !/^[A-Za-z0-9_-]{86}$/.test(signatures[i]) ||
          !verify(null, Buffer.from(stableJSON(payload)), key, Buffer.from(signatures[i], 'base64url'))) throw Error();
    });
    return payload;
  } catch { throw fail('merchant_certification_invalid_or_stale'); }
}

export async function verifiedMerchantEvidence(db, tx, id) {
  const marker = (await tx.get(db.doc('mp_ownership_index/active'))).data();
  if (marker?.version !== 1 || marker.state !== 'ready' || !validEpoch(marker.epoch) ||
      !hex(marker.certificateId) || !hex(marker.sourceRevision) || marker.writerProtocol !== CERT_PROTOCOL) {
    throw fail('merchant_index_not_ready');
  }
  const cert = (await tx.get(db.doc(`mp_index_certificates/${marker.certificateId}`))).data();
  const payload = verifyCertificate(cert, { ...marker, projectId: db.projectId });
  const prefix = merchantPrefix(id), expectedHash = payload.shardDigests[prefix];
  let shard = emptyShard();
  if (expectedHash !== evidenceHash(shard)) {
    shard = (await tx.get(db.doc(`mp_index_evidence/${marker.certificateId}_${prefix}`))).data();
    if (!shard || shard.version !== 1 || !shard.claims || typeof shard.claims !== 'object' ||
        Array.isArray(shard.claims) || shardHash(shard) !== expectedHash) {
      throw fail('merchant_certification_evidence_missing_or_changed');
    }
  }
  const hasExpected = Object.hasOwn(shard.claims, id);
  const expected = hasExpected ? shard.claims[id] : null;
  if (hasExpected && (!expected || typeof expected !== 'object' || !['owned', 'conflict'].includes(expected.state) ||
      (expected.state === 'owned' && !validUid(expected.userId)))) throw fail('merchant_certification_claim_invalid');
  return { epoch: marker.epoch, expected };
}
