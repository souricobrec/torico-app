import crypto from 'node:crypto';

export const securityFailure = (status, code) => Object.assign(new Error(code), { status, code });
const digest = value => crypto.createHash('sha256').update(value).digest('hex');
export const NONCE_TTL_MS = 600000;
export const NONCE_QUOTA = 5;
export const LEGACY_SCAN_LIMIT = 500;

export async function authenticatedUid(req, auth) {
  const match = /^Bearer ([^\s]+)$/i.exec(req.headers.authorization || '');
  if (!match) throw securityFailure(401, 'authentication_required');
  try {
    const token = await auth.verifyIdToken(match[1], true);
    if (typeof token.uid !== 'string' || !token.uid) throw new Error();
    return token.uid;
  } catch { throw securityFailure(401, 'invalid_authentication'); }
}

export function canonicalMerchantId(value) {
  if (typeof value === 'number') {
    if (!Number.isSafeInteger(value) || value <= 0) throw securityFailure(409, 'merchant_id_review_required');
    return String(value);
  }
  if (typeof value !== 'string' || !/^\d{1,64}$/.test(value.trim())) {
    throw securityFailure(409, 'merchant_id_review_required');
  }
  const canonical = BigInt(value.trim()).toString();
  if (canonical === '0' || canonical.length > 30) throw securityFailure(409, 'merchant_id_review_required');
  return canonical;
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

// Bounded complete inventory: numbers, padded strings and legacy aliases are
// compared without rewriting records. Truncated results never prove absence.
export async function canonicalIntegrationMatches(db, merchantId, tx) {
  const id = canonicalMerchantId(merchantId);
  const query = db.collectionGroup('integrations').limit(LEGACY_SCAN_LIMIT + 1);
  const snapshot = tx ? await tx.get(query) : await query.get();
  if (snapshot.size > LEGACY_SCAN_LIMIT) throw securityFailure(503, 'legacy_inventory_required');
  return snapshot.docs.filter(doc => {
    const data = doc.data();
    if (doc.id !== 'mercado_pago' && data.platformId !== 'mercado_pago') return false;
    if (!/^users\/[^/]+\/integrations\/mercado_pago$/.test(doc.ref.path)) {
      throw securityFailure(409, 'legacy_path_review_required');
    }
    if (data.mercadoPagoUserId == null && data.status !== 'connected') return false;
    return canonicalMerchantId(data.mercadoPagoUserId) === id;
  });
}

export async function persistOwnedIntegration(db, userId, merchantId, writes, authorization) {
  const id = canonicalMerchantId(merchantId);
  const ownerRef = db.collection('mp_account_owners').doc(id);
  await db.runTransaction(async tx => {
    await assertAuthorizationGeneration(tx, db, authorization, userId);
    const canonicalOwner = await tx.get(ownerRef);
    if (canonicalOwner.exists && canonicalOwner.data().userId !== userId) {
      throw securityFailure(409, 'merchant_ownership_review_required');
    }
    const owners = await tx.get(db.collection('mp_account_owners').limit(LEGACY_SCAN_LIMIT + 1));
    if (owners.size > LEGACY_SCAN_LIMIT) throw securityFailure(503, 'legacy_inventory_required');
    const existing = await canonicalIntegrationMatches(db, id, tx);
    if (owners.docs.some(doc => canonicalMerchantId(doc.id) === id && doc.data().userId !== userId) ||
        existing.some(doc => doc.ref.parent.parent.id !== userId)) {
      throw securityFailure(409, 'merchant_ownership_review_required');
    }
    tx.set(ownerRef, { userId }, { merge: false });
    for (const [ref, data] of writes) {
      tx.set(ref, ref.path.endsWith('/integrations/mercado_pago') ? { ...data, mercadoPagoUserId: id } : data, { merge: true });
    }
  });
}
