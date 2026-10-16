import crypto from 'node:crypto';

const failure = (status, code) => Object.assign(new Error(code), { status, code });
export async function authenticatedUid(req, auth) {
  const match = /^Bearer ([^\s]+)$/.exec(req.headers.authorization || '');
  if (!match) throw failure(401, 'authentication_required');
  try {
    const token = await auth.verifyIdToken(match[1], true);
    if (!token.uid) throw new Error();
    return token.uid;
  } catch { throw failure(401, 'invalid_authentication'); }
}

// Only a digest is stored. Transactionally burn the nonce BEFORE token exchange.
export function oauthStateStore(db, now = Date.now) {
  const ref = state => db.collection('mp_oauth_nonces').doc(
    crypto.createHash('sha256').update(state).digest('hex'));
  return {
    async issue(userId) {
      const state = crypto.randomBytes(32).toString('hex');
      await ref(state).create({ userId, expiresAtMs: now() + 600000, consumed: false });
      return state;
    },
    async consume(state) {
      if (!/^[a-f0-9]{64}$/.test(state)) throw failure(400, 'invalid_state');
      return db.runTransaction(async tx => {
        const doc = ref(state);
        const snapshot = await tx.get(doc);
        const data = snapshot.data();
        if (!snapshot.exists || data.consumed || data.expiresAtMs <= now() ||
            !Number.isFinite(data.expiresAtMs) || typeof data.userId !== 'string') {
          throw failure(400, 'invalid_or_consumed_state');
        }
        tx.update(doc, { consumed: true, consumedAtMs: now() });
        return { userId: data.userId };
      });
    },
  };
}

// The registry serializes competing callbacks. Existing integrations are checked
// before any writes; ambiguity is a review case, never an automatic transfer.
export async function persistOwnedIntegration(db, userId, merchantId, writes) {
  if (!/^[0-9]{1,30}$/.test(merchantId || '')) throw failure(400, 'invalid_merchant');
  const ownerRef = db.collection('mp_account_owners').doc(merchantId);
  await db.runTransaction(async tx => {
    const owner = await tx.get(ownerRef);
    const existing = await tx.get(db.collectionGroup('integrations')
      .where('mercadoPagoUserId', '==', merchantId));
    if ((owner.exists && owner.data().userId !== userId) || existing.docs.some(doc =>
      doc.id === 'mercado_pago' && doc.ref.parent.parent?.id !== userId)) {
      throw failure(409, 'merchant_ownership_review_required');
    }
    tx.set(ownerRef, { userId }, { merge: false });
    for (const [ref, data] of writes) tx.set(ref, data, { merge: true });
  });
}
