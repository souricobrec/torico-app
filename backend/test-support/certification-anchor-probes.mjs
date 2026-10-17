import assert from 'node:assert/strict';
import { mkdirSync, writeFileSync } from 'node:fs';
import { canonicalIntegrationMatches } from '../mercado-pago-security.js';
import { fixtureOwnershipIndex } from './ownership-index-fixtures.mjs';
import { certificationFixture, fixtureAnchor } from './certification-fixture.mjs';

export async function certificationAnchorProbes({ db, projectId }) {
  assert.match(projectId, /^demo-/);
  await fixtureOwnershipIndex(db, [{ id: 810001, userId: 'anchor-fixture-owner' }]);
  const markerRef = db.doc('mp_ownership_index/active'), markerA = (await markerRef.get()).data();
  const integration = db.doc('users/anchor-fixture-owner/integrations/mercado_pago');
  await integration.set({ platformId: 'mercado_pago', mercadoPagoUserId: 810001, status: 'connected' });
  const before = (await integration.get()).data(), evidence = [];
  const pass = text => { evidence.push(text); console.log('PASS anchor: ' + text); };
  for (const injected of [{ env: { MP_INDEX_CERTIFIER_PUBLIC_KEY: 'injected' } }, { now: 0 }, { projectId: 'other' }]) {
    await markerRef.set({ ...markerA, ...injected });
    await assert.rejects(canonicalIntegrationMatches(db, 810001), { status: 503 });
  }
  await markerRef.set(markerA);
  pass('persisted environment/clock/project injection rejected through actual Firestore reads');
  await fixtureOwnershipIndex(db);
  const markerB = (await markerRef.get()).data(), anchor = fixtureAnchor(db);
  assert.ok(markerB.generation > markerA.generation);
  await markerRef.set(markerA);
  await assert.rejects(canonicalIntegrationMatches(db, 810001), { status: 503 });
  await markerRef.set(markerB);
  assert.equal((await canonicalIntegrationMatches(db, 810001)).length, 1);
  pass('renewal advances independent generation; restoring an older still-valid marker rejects');

  const create = (generation, now = Date.now()) => certificationFixture([{ id: '810001', userId: 'anchor-fixture-owner' }], { projectId, generation, now });
  const stage = async cert => {
    for (const [prefix, shard] of Object.entries(cert.shards)) if (Object.keys(shard.claims).length) await db.doc(`mp_index_evidence/${cert.marker.certificateId}_${prefix}`).set(shard);
    await db.doc(`mp_index_certificates/${cert.marker.certificateId}`).set(cert.certificate);
  };
  const c = create(markerB.generation + 1), d = create(markerB.generation + 1, Date.now() - 1000);
  await stage(c); await stage(d);
  const race = await Promise.allSettled([c, d].map(cert => anchor.advance(markerB.generation, {
    projectId, state: 'active', generation: cert.marker.generation, certificateId: cert.marker.certificateId,
  })));
  assert.equal(race.filter(item => item.status === 'fulfilled').length, 1);
  const winnerId = race.find(item => item.status === 'fulfilled').value.certificateId;
  const winner = winnerId === c.marker.certificateId ? c : d;
  await markerRef.set(winner.marker);
  assert.equal((await canonicalIntegrationMatches(db, 810001)).length, 1);
  pass('concurrent renewals: one CAS winner; active certificate resolves merchant');

  let generation = winner.marker.generation;
  const expired = create(++generation, Date.now() - 7200000);
  await stage(expired);
  await anchor.advance(generation - 1, { projectId, state: 'active', generation, certificateId: expired.marker.certificateId });
  await markerRef.set({ ...expired.marker, now: expired.certificate.payload.issuedAtMs });
  await assert.rejects(canonicalIntegrationMatches(db, 810001), { status: 503 });
  await markerRef.set(expired.marker);
  await assert.rejects(canonicalIntegrationMatches(db, 810001), { status: 503 });
  pass('expired certificate rejects under current anchor; marker clock cannot restore validity');

  await anchor.advance(generation, { projectId, state: 'revoked', generation: ++generation, certificateId: expired.marker.certificateId });
  await markerRef.set(markerB);
  await assert.rejects(canonicalIntegrationMatches(db, 810001), { status: 503 });
  anchor.failReads(true);
  await assert.rejects(canonicalIntegrationMatches(db, 810001), { status: 503 });
  anchor.failReads(false);
  const recovered = create(++generation);
  await stage(recovered);
  await anchor.advance(generation - 1, { projectId, state: 'active', generation, certificateId: recovered.marker.certificateId });
  await markerRef.set(recovered.marker);
  assert.equal((await canonicalIntegrationMatches(db, 810001)).length, 1);
  assert.deepEqual((await integration.get()).data(), before);
  pass('revocation/outage fail closed; recovery requires newer generation; integration unchanged');
  mkdirSync('.tmp-certification-anchor-fix', { recursive: true });
  writeFileSync('.tmp-certification-anchor-fix/anchor-results.json', JSON.stringify({ projectId, syntheticOnly: true, evidence }, null, 2));
}
