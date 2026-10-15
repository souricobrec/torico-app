// Intake only: no user/integration mutations, lifecycle, deletion or worker.
import express from 'express';
import { createHash, randomBytes } from 'node:crypto';

export const intakeNotice = 'intake-review-v1';
export function intakeParsingError(error, _req, res, _next) {
  res.set('Cache-Control', 'no-store');
  res.status(error.type === 'entity.too.large' ? 413 : 400).json({ ok: false, code: 'invalid_input' });
}
const digest = value => createHash('sha256').update(value).digest('hex');
const opaque = () => randomBytes(24).toString('hex');
const invalidAuth = new Set(['auth/id-token-expired', 'auth/id-token-revoked',
  'auth/argument-error', 'auth/invalid-argument', 'auth/invalid-id-token',
  'auth/user-disabled', 'auth/user-not-found']);
class IntakeError extends Error {
  constructor(status, code) { super(code); this.status = status; this.code = code; }
}

export function firestoreIntakeStore(db, { now = Date.now } = {}) {
  const ref = (collection, id) => db.collection(collection).doc(id);
  const index = uid => ref('account_deletion_uid_index', digest(uid));
  return {
    async consumeQuota(uid, operation, limit) {
      const quota = ref('account_deletion_rate_limits', digest(`${uid}:${operation}`));
      return db.runTransaction(async tx => {
        const previous = (await tx.get(quota)).data();
        const time = now();
        const active = previous && previous.resetAt > time;
        const count = active ? previous.count : 0;
        if (count >= limit) throw new IntakeError(429, 'rate_limited');
        tx.set(quota, { count: count + 1, resetAt: active ? previous.resetAt : time + 60000 });
      });
    },
    async register(uid, key, body) {
      const requestId = opaque(), subjectRef = opaque();
      const keyRef = ref('account_deletion_idempotency', digest(`${uid}:${key}`));
      const bodyDigest = digest(JSON.stringify(body));
      return db.runTransaction(async tx => {
        const keyData = (await tx.get(keyRef)).data();
        const owner = (await tx.get(index(uid))).data();
        if (keyData && keyData.bodyDigest !== bodyDigest) throw new IntakeError(409, 'idempotency_conflict');
        const existingId = keyData?.requestId ?? owner?.activeRequestId;
        if (existingId) {
          const existing = (await tx.get(ref('account_deletion_requests', existingId))).data();
          const subject = owner && (await tx.get(ref('account_deletion_subjects', owner.subjectRef))).data();
          if (!existing || !owner || subject?.uid !== uid || existing.subjectRef !== owner.subjectRef) throw new Error('Invalid intake index');
          if (!keyData) tx.set(keyRef, { requestId: existingId, bodyDigest, createdAt: now() });
          return existing;
        }
        const request = { requestId, protocol: `TORICO-${opaque()}`, subjectRef,
          status: 'received', receivedAt: new Date(now()).toISOString(), revision: 1,
          noticeVersion: body.noticeVersion, policyVersion: body.policyVersion,
          completedAt: null, schemaVersion: 1 };
        tx.set(ref('account_deletion_subjects', subjectRef), { uid, activeRequestId: requestId });
        tx.set(index(uid), { subjectRef, activeRequestId: requestId });
        tx.set(ref('account_deletion_requests', requestId), request);
        tx.set(keyRef, { requestId, bodyDigest, createdAt: now() });
        tx.set(ref('account_deletion_requests', requestId).collection('events').doc('received'), {
          eventType: 'received', at: request.receivedAt, revision: 1, actorType: 'owner' });
        // Audit/review signal only. No dispatcher or destructive consumer exists.
        tx.set(ref('account_deletion_outbox', requestId), {
          requestId, eventType: 'intake_received', executionAllowed: false, schemaVersion: 1 });
        return request;
      });
    },
    async current(uid) {
      const owner = (await index(uid).get()).data();
      if (!owner) return null;
      const subject = (await ref('account_deletion_subjects', owner.subjectRef).get()).data();
      if (subject?.uid !== uid) throw new Error('Invalid subject mapping');
      const request = (await ref('account_deletion_requests', owner.activeRequestId).get()).data();
      if (request && request.subjectRef !== owner.subjectRef) throw new Error('Invalid request mapping');
      return request ?? null;
    },
  };
}

export function accountDeletionIntakeRouter({ enabled = false, auth, store,
  projectId = 'torico-ca479', now = Date.now } = {}) {
  const router = express.Router();
  // Bounded, process-local coarse guard before expensive token verification.
  // Authenticated quotas below are transactional/shared through Firestore.
  const peers = new Map();
  router.use(async (req, res, next) => {
    res.set('Cache-Control', 'no-store');
    if (!enabled) return res.status(404).json({ ok: false, code: 'feature_disabled' });
    try {
      const time = now();
      for (const [key, value] of peers) if (value.resetAt <= time) peers.delete(key);
      const peerKey = req.ip || 'unknown'; // Never trust client X-Forwarded-For here.
      if (!peers.has(peerKey) && peers.size >= 10000) throw new IntakeError(503, 'service_unavailable');
      const peer = peers.get(peerKey) ?? { count: 0, resetAt: time + 60000 };
      if (++peer.count > 120) throw new IntakeError(429, 'rate_limited');
      peers.set(peerKey, peer);
      const match = /^Bearer (\S{1,8192})$/i.exec(req.headers.authorization || '');
      if (!match) throw new IntakeError(401, 'authentication_required');
      let token;
      try { token = await auth.verifyIdToken(match[1], true); }
      catch (error) { throw new IntakeError(invalidAuth.has(error.code) ? 401 : 503,
        invalidAuth.has(error.code) ? 'invalid_session' : 'service_unavailable'); }
      if (typeof token.uid !== 'string' || !token.uid || token.uid.length > 128 ||
          token.aud !== projectId || token.iss !== `https://securetoken.google.com/${projectId}` ||
          (token.sub && token.sub !== token.uid) || token.firebase?.tenant) {
        throw new IntakeError(401, 'invalid_session');
      }
      if (Object.keys(req.query).length) throw new IntakeError(400, 'invalid_input');
      if (req.get('x-user-id') || req.get('x-uid')) throw new IntakeError(400, 'invalid_input');
      req.intakeUid = token.uid;
      req.intakeAuthTime = token.auth_time;
      await store.consumeQuota(token.uid, req.method === 'POST' ? 'register' : 'read', req.method === 'POST' ? 5 : 30);
      next();
    } catch (error) { respond(error, res); }
  });
  router.post('/requests', async (req, res) => {
    try {
      const authTime = req.intakeAuthTime;
      const seconds = Math.floor(now() / 1000);
      if (!Number.isInteger(authTime) || authTime > seconds || seconds - authTime > 300) {
        throw new IntakeError(403, 'reauthentication_required');
      }
      const body = req.body;
      if (!req.is('application/json') || !body || Array.isArray(body) ||
          Object.keys(body).sort().join(',') !== 'confirmation,noticeVersion,policyVersion' ||
          JSON.stringify(body).length > 2048 || body.confirmation !== 'delete_account' ||
          body.noticeVersion !== intakeNotice || body.policyVersion !== intakeNotice) {
        throw new IntakeError(400, 'invalid_input');
      }
      const key = req.get('Idempotency-Key');
      if (!/^[A-Za-z0-9_-]{32,128}$/.test(key || '')) throw new IntakeError(400, 'invalid_idempotency_key');
      const request = await store.register(req.intakeUid, key, {
        confirmation: body.confirmation, noticeVersion: body.noticeVersion, policyVersion: body.policyVersion });
      res.status(202).json(project(request));
    } catch (error) { respond(error, res); }
  });
  const read = async (req, res) => {
    try {
      const request = await store.current(req.intakeUid);
      if (!request || (req.params.id && req.params.id !== request.requestId)) {
        throw new IntakeError(404, 'request_not_found');
      }
      res.status(200).json(project(request));
    } catch (error) { respond(error, res); }
  };
  router.get('/requests/current', read);
  router.get('/requests/:id', read);
  router.use((_req, res) => res.status(404).json({ ok: false, code: 'not_found' }));
  return router;
}

function project(request) {
  if (!['received', 'verifying', 'processing', 'completed', 'rejected'].includes(request.status)) throw new Error('Unknown state');
  if (request.status === 'completed' && !request.completedAt) throw new Error('Incomplete result');
  return { ok: true, requestId: request.requestId, protocol: request.protocol,
    status: request.status, receivedAt: request.receivedAt, revision: request.revision,
    completedAt: request.completedAt ?? null, message: request.status === 'received'
      ? 'Pedido recebido. Sua conta ainda não foi excluída.' : 'Consulte o estado do atendimento.' };
}
function respond(error, res) {
  const status = error instanceof IntakeError ? error.status : 503;
  if (status === 429) res.set('Retry-After', '60');
  return res.status(status).json({ ok: false,
    code: error instanceof IntakeError ? error.code : 'service_unavailable' });
}
