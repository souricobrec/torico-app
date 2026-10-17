import assert from 'node:assert/strict';
import { canonicalMerchantId, MP_INDEX_METADATA_PATH } from '../mercado-pago-security.js';
import { certificationFixture, fixtureTrust, fixtureAnchor, activateFixtureCertificate } from './certification-fixture.mjs';

// Synthetic fixtures only. This is NOT migration/certification tooling.
export async function fixtureOwnershipIndex(db, entries = []) {
  assert.match(db.projectId, /^demo-/);
  Object.assign(process.env, fixtureTrust); // Public anchors only; private fixture keys stay in memory.
  for (const { id, userId, conflict = false } of entries) {
    await db.doc(`mp_account_owners/${canonicalMerchantId(id)}`).set({
      indexVersion: 1, indexEpoch: 'fixture-v1',
      state: conflict ? 'conflict' : 'owned', ...(userId ? { userId } : {}),
    });
  }
  const known = (await db.collection('mp_account_owners').get()).docs.filter(doc =>
    /^[1-9][0-9]*$/.test(doc.id) && doc.data().indexVersion === 1).map(doc => ({
      id: doc.id, userId: doc.data().userId, conflict: doc.data().state === 'conflict',
    }));
  const current = await fixtureAnchor(db).read();
  const fixture = certificationFixture(known, { projectId: db.projectId, generation: (current?.generation ?? 0) + 1 });
  for (const [prefix, shard] of Object.entries(fixture.shards)) {
    if (Object.keys(shard.claims).length) await db.doc(`mp_index_evidence/${fixture.marker.certificateId}_${prefix}`).set(shard);
  }
  await db.doc(`mp_index_certificates/${fixture.marker.certificateId}`).set(fixture.certificate);
  await db.doc(MP_INDEX_METADATA_PATH).set(fixture.marker);
  await activateFixtureCertificate(db, fixture.marker);
}
