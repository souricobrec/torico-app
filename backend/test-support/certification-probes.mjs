import assert from 'node:assert/strict';
import { writeFileSync, mkdirSync } from 'node:fs';
import { canonicalIntegrationMatches, oauthStateStore, persistOwnedIntegration } from '../mercado-pago-security.js';
import { evidenceHash, merchantPrefix } from '../mp-index-certification.js';
import { signFixturePayload } from './certification-fixture.mjs';
import { fixtureOwnershipIndex } from './ownership-index-fixtures.mjs';

export async function certificationProbes({ db, projectId }) {
  assert.match(projectId, /^demo-/);
  await fixtureOwnershipIndex(db, [{ id: 770001, userId: 'cert-owner' }]);
  const metadata = db.doc('mp_ownership_index/active'), owner = db.doc('mp_account_owners/770001');
  const integration = db.doc('users/cert-owner/integrations/mercado_pago');
  await integration.set({ platformId: 'mercado_pago', mercadoPagoUserId: 770001, status: 'connected' });
  await owner.set({ audit: { immutableProof: 'synthetic-proof' }, originalCreatedAt: 'synthetic-date' }, { merge: true });
  const marker = (await metadata.get()).data(), original = (await owner.get()).data();
  const certRef = db.doc(`mp_index_certificates/${marker.certificateId}`), certificate = (await certRef.get()).data();
  const evidence = [], pass = text => { evidence.push(text); console.log('PASS certification: ' + text); };
  await metadata.set({ version: 1, state: 'ready', epoch: marker.epoch });
  await assert.rejects(canonicalIntegrationMatches(db, 770001), { status: 503 });
  await metadata.set(marker);
  await owner.delete(); // Fictitious demo fixture only; never a real owner.
  const authorize = async uid => { const store = oauthStateStore(db); return store.consume(await store.issue(uid)); };
  await assert.rejects(persistOwnedIntegration(db, 'cert-attacker', 770001, [], await authorize('cert-attacker')), { status: 409 });
  assert.equal((await owner.get()).exists, false);
  await owner.set(original);
  pass('ready alone and missing certified legacy owner cannot authorize a takeover');

  const shardRef = db.doc(`mp_index_evidence/${marker.certificateId}_${merchantPrefix('770001')}`);
  const shard = (await shardRef.get()).data();
  await shardRef.delete();
  await assert.rejects(canonicalIntegrationMatches(db, 770001), { status: 503 });
  await shardRef.set(shard);
  const changed = structuredClone(certificate); changed.signatures[1] = changed.signatures[0];
  await certRef.set(changed);
  await assert.rejects(canonicalIntegrationMatches(db, 770001), { status: 503 });
  await certRef.set(certificate);
  const payload = { ...certificate.payload, capturedAtMs: Date.now() - 90000000 };
  const staleId = evidenceHash(payload);
  await db.doc(`mp_index_certificates/${staleId}`).set(signFixturePayload(payload));
  await metadata.set({ ...marker, certificateId: staleId });
  await assert.rejects(canonicalIntegrationMatches(db, 770001), { status: 503 });
  await metadata.set(marker);
  pass('missing evidence, repeated signer and signed stale certificate fail closed');

  const contexts = await Promise.all([authorize('cert-owner'), authorize('cert-owner')]);
  await Promise.all(contexts.map(auth => persistOwnedIntegration(db, 'cert-owner', '000770001', [], auth)));
  await persistOwnedIntegration(db, 'cert-owner', 770001, [], await authorize('cert-owner'));
  const after = (await owner.get()).data();
  assert.deepEqual(after.audit, original.audit); assert.equal(after.originalCreatedAt, original.originalCreatedAt);
  assert.equal(after.userId, 'cert-owner'); assert.equal(after.merchantId, '770001');
  await assert.rejects(persistOwnedIntegration(db, 'cert-attacker', 770001, [], await authorize('cert-attacker')), { status: 409 });
  assert.equal((await integration.get()).data().status, 'connected');
  pass('concurrent/repeated reconnection preserves audit fields and canonical ownership');
  mkdirSync('.tmp-certification-readiness', { recursive: true });
  writeFileSync('.tmp-certification-readiness/certification-results.json', JSON.stringify({ projectId, syntheticOnly: true, evidence }, null, 2));
}
