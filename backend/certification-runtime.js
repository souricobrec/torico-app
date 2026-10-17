// Trusted process wiring only. No Firestore/config fallback and no production
// anchor adapter: until independently protected infrastructure is approved,
// an unconfigured backend MUST fail closed.
import { createPublicKey } from 'node:crypto';
const runtimes = new WeakMap();
export const anchorFailure = code => Object.assign(new Error(code), { status: 503, code });

export function createCertificationTrust({ projectId, publicKeys, clock = Date.now }) {
  if (typeof projectId !== 'string' || !projectId || typeof clock !== 'function' || !Array.isArray(publicKeys) || publicKeys.length !== 2) {
    throw anchorFailure('certification_trust_unconfigured');
  }
  let keys;
  try {
    keys = publicKeys.map(key => createPublicKey(key));
    if (keys.some(key => key.asymmetricKeyType !== 'ed25519') ||
        keys[0].export({ type: 'spki', format: 'der' }).equals(keys[1].export({ type: 'spki', format: 'der' }))) throw Error();
  } catch { throw anchorFailure('certification_trust_invalid'); }
  return Object.freeze({ projectId, publicKeys: Object.freeze(keys), clock });
}

// Must be invoked by reviewed server composition, never from persisted data,
// HTTP input, environment-supplied code or an untrusted marker.
export function configureCertificationRuntime(db, { trust, anchor }) {
  // No production anchor has been implemented/reviewed/approved. Deliberately
  // no env flag, marker field or fallback can enable production in this phase.
  if (typeof db.projectId !== 'string' || !/^demo-[a-z0-9-]+$/.test(db.projectId)) {
    throw anchorFailure('certification_production_anchor_not_approved');
  }
  if (!trust || trust.projectId !== db.projectId || typeof anchor?.withCurrent !== 'function') {
    throw anchorFailure('certification_anchor_unconfigured');
  }
  runtimes.set(db, Object.freeze({ trust, anchor }));
}

export async function withCertificationRuntime(db, work) {
  const runtime = runtimes.get(db);
  if (!runtime) throw anchorFailure('certification_anchor_unconfigured');
  try {
    // Adapter contract: linearizable shared lease held until work (including
    // Firestore commit/retries) completes; renewal/revocation requires exclusive
    // CAS. A get() followed by commit on another store is NOT sufficient.
    return await runtime.anchor.withCurrent(runtime.trust.projectId, async snapshot => {
      if (snapshot?.projectId !== runtime.trust.projectId || snapshot.state !== 'active' ||
          !Number.isSafeInteger(snapshot.generation) || snapshot.generation < 1 ||
          typeof snapshot.certificateId !== 'string' || !/^[a-f0-9]{64}$/.test(snapshot.certificateId)) {
        throw anchorFailure('certification_anchor_inactive');
      }
      return work(Object.freeze({ ...runtime.trust, anchor: Object.freeze({
        projectId: snapshot.projectId, state: snapshot.state,
        generation: snapshot.generation, certificateId: snapshot.certificateId,
      }) }));
    });
  } catch (error) {
    if (error?.status === 409 || (typeof error?.code === 'string' && /^(merchant_|authorization_|certification_)/.test(error.code))) throw error;
    throw anchorFailure('certification_anchor_unavailable');
  }
}
