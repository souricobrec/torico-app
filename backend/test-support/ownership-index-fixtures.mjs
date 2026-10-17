import assert from 'node:assert/strict';
import { canonicalMerchantId, MP_INDEX_METADATA_PATH } from '../mercado-pago-security.js';

// Synthetic fixtures only. This is NOT migration/certification tooling.
export async function fixtureOwnershipIndex(db, entries = []) {
  assert.match(db.projectId, /^demo-/);
  for (const { id, userId, conflict = false } of entries) {
    await db.doc(`mp_account_owners/${canonicalMerchantId(id)}`).set({
      indexVersion: 1, indexEpoch: 'fixture-v1',
      state: conflict ? 'conflict' : 'owned', ...(userId ? { userId } : {}),
    });
  }
  await db.doc(MP_INDEX_METADATA_PATH).set({ version: 1, state: 'ready', epoch: 'fixture-v1' });
}
