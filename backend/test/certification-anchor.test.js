import test from 'node:test';
import assert from 'node:assert/strict';
import { canonicalIntegrationMatches } from '../mercado-pago-security.js';
import { verifyCertificate, evidenceHash } from '../mp-index-certification.js';
import { certificationFixture, fixtureTrust, activateFixtureCertificate, fixtureTrustedContext, signFixturePayload } from '../test-support/certification-fixture.mjs';
import { configureCertificationRuntime, createCertificationTrust } from '../certification-runtime.js';

function install(docs, cert) {
  docs.set('mp_ownership_index/active', structuredClone(cert.marker));
  docs.set(`mp_index_certificates/${cert.marker.certificateId}`, cert.certificate);
  for (const [prefix, shard] of Object.entries(cert.shards)) if (Object.keys(shard.claims).length) docs.set(`mp_index_evidence/${cert.marker.certificateId}_${prefix}`, shard);
}
async function fixture() {
  const cert = certificationFixture([{ id: '123', userId: 'owner' }]);
  const docs = new Map(), stats = { reads: 0, commits: 0 };
  install(docs, cert);
  docs.set('mp_account_owners/123', cert.owners[0].data);
  docs.set('users/owner/integrations/mercado_pago', { platformId: 'mercado_pago', mercadoPagoUserId: 123 });
  let commitGate = async () => {};
  const db = { projectId: 'demo-index-unit', doc: path => ({ path }), collection: c => ({ doc: id => ({ path: `${c}/${id}` }) }),
    runTransaction: async fn => {
      const result = await fn({ get: async ref => { stats.reads++; return { exists: docs.has(ref.path), ref, data: () => docs.get(ref.path) }; } });
      await commitGate(); stats.commits++; return result;
    } };
  const anchor = await activateFixtureCertificate(db, cert.marker);
  return { db, cert, docs, anchor, stats, gate: fn => { commitGate = fn; } };
}
test('persisted env/now cannot replace trusted keys or server clock; expired certificate rejects', async () => {
  for (const extra of [{ env: fixtureTrust }, { now: 0 }, { projectId: 'another-project' }]) {
    const { db, docs, cert } = await fixture();
    docs.set('mp_ownership_index/active', { ...cert.marker, ...extra });
    await assert.rejects(canonicalIntegrationMatches(db, 123), { status: 503 });
  }
  const now = Date.now(), old = certificationFixture([{ id: '123', userId: 'owner' }], { now: now - 7200000 });
  assert.throws(() => verifyCertificate(old.certificate, { ...old.marker, now: now - 7200000, env: fixtureTrust }, fixtureTrustedContext(old.marker, { clock: () => now })), /invalid_or_stale/);
  // Different signer pair cannot be introduced through the marker.
  const other = await import('../test-support/certification-fixture.mjs?untrusted-anchor-test');
  const { db, docs, anchor } = await fixture();
  const forged = other.certificationFixture([{ id: '123', userId: 'owner' }], { generation: 2 });
  install(docs, forged);
  await anchor.advance(1, { projectId: db.projectId, state: 'active', generation: 2, certificateId: forged.marker.certificateId });
  await assert.rejects(canonicalIntegrationMatches(db, 123), { status: 503 });
  docs.get('mp_ownership_index/active').env = other.fixtureTrust;
  await assert.rejects(canonicalIntegrationMatches(db, 123), { status: 503 });
});

test('renewals use exclusive monotonic CAS; old marker cannot reactivate a replaced certificate', async () => {
  const { db, docs, anchor, cert } = await fixture();
  const next = certificationFixture([{ id: '123', userId: 'owner' }], { generation: 2 });
  const attempts = await Promise.allSettled([next.marker.certificateId, 'f'.repeat(64)].map(certificateId =>
    anchor.advance(1, { projectId: db.projectId, state: 'active', generation: 2, certificateId })));
  assert.equal(attempts.filter(item => item.status === 'fulfilled').length, 1);
  install(docs, next);
  assert.equal((await canonicalIntegrationMatches(db, 123)).length, 1);
  docs.set('mp_ownership_index/active', cert.marker);
  await assert.rejects(canonicalIntegrationMatches(db, 123), { status: 503 });
  await assert.rejects(anchor.advance(2, { projectId: db.projectId, state: 'active', generation: 1, certificateId: cert.marker.certificateId }), { status: 409 });
  await anchor.advance(2, { projectId: db.projectId, state: 'revoked', generation: 3, certificateId: next.marker.certificateId });
  install(docs, next);
  await assert.rejects(canonicalIntegrationMatches(db, 123), { status: 503 });
});

test('read lease spans Firestore commit; queued renewal cannot overtake in-flight transaction', async () => {
  const { db, anchor, gate } = await fixture();
  let release, reached;
  const entered = new Promise(resolve => { reached = resolve; });
  const blocked = new Promise(resolve => { release = resolve; });
  gate(async () => { reached(); await blocked; });
  const operation = canonicalIntegrationMatches(db, 123);
  await entered;
  let advanced = false;
  const renewal = anchor.advance(1, { projectId: db.projectId, state: 'active', generation: 2, certificateId: 'a'.repeat(64) }).then(() => { advanced = true; });
  await new Promise(resolve => setTimeout(resolve, 10));
  assert.equal(advanced, false);
  release(); await operation; await renewal;
  assert.equal(advanced, true);
});

test('missing/unavailable anchor and project mismatch fail closed without database processing', async () => {
  const { db, anchor, stats } = await fixture();
  anchor.failReads(true);
  await assert.rejects(canonicalIntegrationMatches(db, 123), { status: 503 });
  assert.equal(stats.reads, 0); assert.equal(stats.commits, 0);
  const unconfigured = { ...db };
  await assert.rejects(canonicalIntegrationMatches(unconfigured, 123), { code: 'certification_anchor_unconfigured' });
  assert.throws(() => configureCertificationRuntime(db, { trust: createCertificationTrust({ projectId: 'demo-other', publicKeys: Object.values(fixtureTrust) }), anchor }), /unconfigured/);
  assert.throws(() => configureCertificationRuntime({ ...db, projectId: 'production-fixture' }, {
    trust: createCertificationTrust({ projectId: 'production-fixture', publicKeys: Object.values(fixtureTrust) }), anchor,
  }), { code: 'certification_production_anchor_not_approved' });
});

test('time tolerance: issuance permits 30 seconds only; expiry has zero grace', () => {
  const now = Date.now(), cert = certificationFixture([{ id: '123', userId: 'owner' }]);
  for (const skew of [30000, 30001]) {
    const payload = { ...cert.certificate.payload, capturedAtMs: now, issuedAtMs: now + skew };
    const marker = { ...cert.marker, certificateId: evidenceHash(payload) };
    const trust = fixtureTrustedContext(marker, { clock: () => now });
    if (skew === 30000) assert.equal(verifyCertificate(signFixturePayload(payload), marker, trust).issuedAtMs, now + skew);
    else assert.throws(() => verifyCertificate(signFixturePayload(payload), marker, trust), /invalid_or_stale/);
  }
  assert.throws(() => verifyCertificate(cert.certificate, cert.marker, fixtureTrustedContext(cert.marker, { clock: () => cert.certificate.payload.expiresAtMs })), /invalid_or_stale/);
});
