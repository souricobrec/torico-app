import crypto from 'node:crypto';
import { canonicalMerchantId } from './mercado-pago-id.js';
import { verifiedMerchantEvidence } from './mp-index-certification.js';
export { canonicalMerchantId } from './mercado-pago-id.js';

export const securityFailure = (status, code) => Object.assign(new Error(code), { status, code });
const digest = value => crypto.createHash('sha256').update(value).digest('hex');
export const NONCE_TTL_MS = 600000;
export const NONCE_QUOTA = 5;
// Activation requires an independently verified, complete additive backfill.
export const MP_INDEX_VERSION = 1;
export const MP_INDEX_METADATA_PATH = 'mp_ownership_index/active';

export async function authenticatedUid(req, auth) {
  const match = /^Bearer ([^\s]+)$/i.exec(req.headers.authorization || '');
  if (!match) throw securityFailure(401, 'authentication_required');
  try {
    const token = await auth.verifyIdToken(match[1], true);
    if (typeof token.uid !== 'string' || !token.uid) throw new Error();
    return token.uid;
  } catch { throw securityFailure(401, 'invalid_authentication'); }
}

export function authorizationControlRef(db, userId, platform = 'mercado_pago') {
  if (!['mercado_pago', 'pagbank'].includes(platform) || typeof userId !== 'string' || !userId) {
    throw securityFailure(400, 'invalid_authorization_context');
  }
  return db.collection('oauth_authorization_controls').doc(digest(`${platform}\0${userId}`));
}

const generation = snapshot => {
  const value = snapshot.data()?.generation ?? 0;
  if (!Number.isSafeInteger(value) || value < 0) throw securityFailure(409, 'authorization_review_required');
  return value;
};

export async function assertAuthorizationGeneration(tx, db, authorization, userId, platform = 'mercado_pago') {
  if (!authorization || authorization.userId !== userId || authorization.platformId !== platform) {
    throw securityFailure(400, 'invalid_authorization_context');
  }
  const control = await tx.get(authorizationControlRef(db, userId, platform));
  if (!control.exists || generation(control) !== authorization.generation) {
    throw securityFailure(409, 'authorization_cancelled');
  }
}

// Fixed-size pool: five reusable slots per UID/platform. No deletion/TTL job.
export function oauthStateStore(db, now = Date.now, platform = 'mercado_pago') {
  return {
    async issue(userId) {
      const controlRef = authorizationControlRef(db, userId, platform);
      const secret = crypto.randomBytes(32).toString('hex');
      return db.runTransaction(async tx => {
        const control = await tx.get(controlRef);
        const data = control.data() || {};
        const time = now();
        const start = data.windowStartedAtMs ?? time;
        if (!Number.isFinite(start) || !Number.isSafeInteger(data.issued ?? 0) || (data.issued ?? 0) < 0) {
          throw securityFailure(409, 'authorization_review_required');
        }
        const sameWindow = time - start < NONCE_TTL_MS;
        if (time < start || (sameWindow && (data.issued ?? 0) >= NONCE_QUOTA)) {
          throw securityFailure(429, 'oauth_quota_exceeded');
        }
        const refs = Array.from({ length: NONCE_QUOTA }, (_, slot) =>
          db.collection('oauth_nonce_slots').doc(`${controlRef.id}_${slot}`));
        const slots = await tx.getAll(...refs);
        const slot = slots.findIndex(doc => !doc.exists || doc.data().consumed || doc.data().expiresAtMs <= time);
        if (slot < 0) throw securityFailure(429, 'oauth_quota_exceeded');
        const state = `v2.${controlRef.id}.${slot}.${secret}`;
        tx.set(controlRef, { generation: generation(control), windowStartedAtMs: sameWindow ? start : time,
          issued: sameWindow ? (data.issued ?? 0) + 1 : 1 }, { merge: true });
        tx.set(refs[slot], { userId, platformId: platform, generation: generation(control),
          digest: digest(state), expiresAtMs: time + NONCE_TTL_MS, consumed: false });
        return state;
      });
    },
    async consume(state) {
      const match = /^v2\.([a-f0-9]{64})\.([0-4])\.([a-f0-9]{64})$/.exec(state || '');
      if (!match) throw securityFailure(400, 'invalid_state');
      return db.runTransaction(async tx => {
        const ref = db.collection('oauth_nonce_slots').doc(`${match[1]}_${match[2]}`);
        const snapshot = await tx.get(ref);
        const data = snapshot.data();
        if (!snapshot.exists || data.consumed || data.platformId !== platform || data.digest !== digest(state) ||
            !Number.isFinite(data.expiresAtMs) || data.expiresAtMs <= now()) {
          throw securityFailure(400, 'invalid_or_consumed_state');
        }
        const control = authorizationControlRef(db, data.userId, platform);
        if (control.id !== match[1]) throw securityFailure(400, 'invalid_state');
        await assertAuthorizationGeneration(tx, db, data, data.userId, platform);
        tx.update(ref, { consumed: true, consumedAtMs: now() });
        return { userId: data.userId, platformId: platform, generation: data.generation };
      });
    },
  };
}

// No scans or legacy fallback: a certified complete index is required to prove
// absence. Only backend administrative tooling may certify it (not implemented).
function indexFailure(code, id, status = 409) {
  console.warn('mp_ownership_diagnostic', {
    code, ...(id ? { merchantKey: digest(id) } : {}),
  });
  return securityFailure(status, code);
}
async function indexContext(db, tx, id) {
  try { return await verifiedMerchantEvidence(db, tx, id); }
  catch (error) { throw indexFailure(error.code || 'merchant_certification_invalid', id, 503); }
}
function indexedOwner(snapshot, epoch, id, expected) {
  if (expected?.state === 'conflict' || (expected && !snapshot.exists)) {
    throw indexFailure('merchant_ownership_review_required', id);
  }
  if (!snapshot.exists) return null;
  const data = snapshot.data();
  if (data?.indexVersion !== MP_INDEX_VERSION || data.indexEpoch !== epoch ||
      data.state !== 'owned' || typeof data.userId !== 'string' || !data.userId ||
      data.userId.includes('/') || data.userId.length > 128 ||
      (expected && expected.userId !== data.userId) ||
      (data.merchantId != null && data.merchantId !== id)) {
    throw indexFailure('merchant_ownership_review_required', id);
  }
  return data.userId;
}

export async function canonicalIntegrationMatches(db, merchantId, tx) {
  const id = canonicalMerchantId(merchantId);
  // Keep epoch, ownership and credentials in one consistent transaction.
  if (!tx) return db.runTransaction(transaction => canonicalIntegrationMatches(db, id, transaction));
  const { epoch, expected } = await indexContext(db, tx, id);
  const ownerRef = db.collection('mp_account_owners').doc(id);
  const owner = tx ? await tx.get(ownerRef) : await ownerRef.get();
  const uid = indexedOwner(owner, epoch, id, expected);
  if (!uid) return [];
  const ref = db.doc(`users/${uid}/integrations/mercado_pago`);
  const integration = tx ? await tx.get(ref) : await ref.get();
  if (!integration.exists) return [];
  const data = integration.data();
  if (data?.platformId !== 'mercado_pago') throw indexFailure('merchant_integration_review_required', id);
  let actual;
  try { actual = canonicalMerchantId(data.mercadoPagoUserId); }
  catch { throw indexFailure('merchant_integration_review_required', id); }
  // A UID may explicitly replace its platform account. The old index remains
  // reserved, but must not route its events using the replacement credentials.
  return actual === id ? [integration] : [];
}

export async function persistOwnedIntegration(db, userId, merchantId, writes, authorization) {
  const id = canonicalMerchantId(merchantId);
  const ownerRef = db.collection('mp_account_owners').doc(id);
  await db.runTransaction(async tx => {
    await assertAuthorizationGeneration(tx, db, authorization, userId);
    const { epoch, expected } = await indexContext(db, tx, id);
    const owner = indexedOwner(await tx.get(ownerRef), epoch, id, expected);
    if (owner && owner !== userId) throw indexFailure('merchant_ownership_review_required', id);
    tx.set(ownerRef, { userId, merchantId: id, indexVersion: MP_INDEX_VERSION, indexEpoch: epoch, state: 'owned' }, { merge: true });
    for (const [ref, data] of writes) {
      tx.set(ref, ref.path.endsWith('/integrations/mercado_pago') ? { ...data, mercadoPagoUserId: id } : data, { merge: true });
    }
  });
}
