import assert from 'node:assert/strict';
import { canonicalIntegrationMatches } from '../mercado-pago-security.js';
import { fixtureOwnershipIndex } from './ownership-index-fixtures.mjs';

export async function indexScaleProbes({ db, projectId }) {
  assert.match(projectId, /^demo-/);
  await fixtureOwnershipIndex(db, [{ id: 880001, userId: 'scale-valid' }, { id: 880002, conflict: true }]);
  const valid = db.doc('users/scale-valid/integrations/mercado_pago');
  await valid.set({ platformId: 'mercado_pago', mercadoPagoUserId: ' 000880001 ', status: 'connected' });
  let inserted = 0;
  for (const count of [501, 1000, 1501]) {
    while (inserted < count) {
      const batch = db.batch();
      for (let n = 0; n < 150 && inserted < count; n++, inserted++) {
        const platform = ['rede', 'pagbank', 'mercado_pago'][inserted % 3];
        batch.set(db.doc(`users/scale-other-${inserted}/integrations/${platform}`), {
          platformId: platform, mercadoPagoUserId: 'invalid-unrelated', status: 'disconnected',
        });
        batch.set(db.doc(`mp_account_owners/legacy-invalid-${inserted}`), { userId: 'synthetic-unindexed' });
      }
      await batch.commit();
    }
    assert.equal((await canonicalIntegrationMatches(db, 880001)).length, 1);
    await assert.rejects(canonicalIntegrationMatches(db, '000880002'), { status: 409 });
    console.log(`PASS index: ${count} synthetic unrelated integrations AND owner aliases; valid merchant resolves, conflict isolated`);
  }
  assert.equal((await valid.get()).data().mercadoPagoUserId, ' 000880001 ');
}
