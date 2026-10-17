import test from 'node:test';
import assert from 'node:assert/strict';
import { reconcileInventory, verifyCertificate, evidenceHash, merchantPrefix } from '../mp-index-certification.js';
import { canonicalIntegrationMatches, persistOwnedIntegration, authorizationControlRef } from '../mercado-pago-security.js';
import { certificationFixture, fixtureTrust, signFixturePayload, activateFixtureCertificate, fixtureTrustedContext } from '../test-support/certification-fixture.mjs';

const entry = { id: '123', userId: 'owner' };
async function fixture() {
  Object.assign(process.env, fixtureTrust);
  const cert = certificationFixture([entry]);
  const docs = new Map([
    ['mp_ownership_index/active', cert.marker],
    [`mp_index_certificates/${cert.marker.certificateId}`, cert.certificate],
    ['mp_account_owners/123', { ...cert.owners[0].data, audit: { original: 'keep' }, migrationProof: 'keep-too' }],
    ['users/owner/integrations/mercado_pago', { platformId: 'mercado_pago', mercadoPagoUserId: 123, status: 'connected' }],
  ]);
  for (const [prefix, shard] of Object.entries(cert.shards)) if (Object.keys(shard.claims).length) docs.set(`mp_index_evidence/${cert.marker.certificateId}_${prefix}`, structuredClone(shard));
  const db = { projectId: 'demo-index-unit', collection: c => ({ doc: id => db.doc(`${c}/${id}`) }),
    doc: path => ({ path }), runTransaction: async fn => {
      const writes = [];
      const result = await fn({ get: async ref => ({ exists: docs.has(ref.path), ref, data: () => docs.get(ref.path) }),
        set: (ref, data, options) => writes.push([ref.path, options?.merge ? { ...docs.get(ref.path), ...data } : data]) });
      for (const [path, data] of writes) docs.set(path, data);
      return result;
    } };
  await activateFixtureCertificate(db, cert.marker);
  return { db, docs, cert };
}

test('independent reconciliation rejects omitted owners, missing conflicts, duplicate paths and unresolved IDs', () => {
  const sources = [{ path: 'users/a/integrations/mercado_pago', data: { mercadoPagoUserId: 123 } },
    { path: 'mp_account_owners/000123', data: { userId: 'b' } }];
  assert.throws(() => reconcileInventory({ sources, owners: [], epoch: 'e' }), /incomplete/);
  assert.throws(() => reconcileInventory({ sources, owners: [{ id: '123', data: { indexVersion: 1, indexEpoch: 'e', state: 'owned', userId: 'a' } }], epoch: 'e' }), /incomplete/);
  const plan = reconcileInventory({ sources, owners: [{ id: '123', data: { indexVersion: 1, indexEpoch: 'e', state: 'conflict' } }], epoch: 'e' });
  assert.equal(plan.shards[merchantPrefix('123')].claims['123'].state, 'conflict');
  assert.throws(() => reconcileInventory({ sources: [...sources, sources[0]], owners: [], epoch: 'e' }), /duplicate_path/);
  assert.throws(() => reconcileInventory({ sources: [{ path: 'users/a/integrations/mercado_pago', data: { mercadoPagoUserId: Number.MAX_SAFE_INTEGER + 1 } }], owners: [], epoch: 'e' }), /unresolved_identifier/);
});

test('certificate verifies two pinned signers and server time, never options from the binding', () => {
  const cert = certificationFixture([entry]);
  const trust = fixtureTrustedContext(cert.marker);
  assert.equal(verifyCertificate(cert.certificate, cert.marker, trust).merchantCount, 1);
  for (const changed of [
    { ...trust, projectId: 'production-other' },
    { ...trust, clock: () => cert.certificate.payload.expiresAtMs },
    { ...trust, publicKeys: [trust.publicKeys[0], trust.publicKeys[0]] },
  ]) assert.throws(() => verifyCertificate(cert.certificate, cert.marker, changed), /invalid_or_stale/);
  assert.throws(() => verifyCertificate(cert.certificate, { ...cert.marker, sourceRevision: '0'.repeat(64) }, trust), /invalid_or_stale/);
  assert.throws(() => verifyCertificate({ ...cert.certificate, signatures: [cert.certificate.signatures[0], cert.certificate.signatures[0]] }, cert.marker, trust), /invalid_or_stale/);
  const altered = structuredClone(cert.certificate); altered.payload.sourceCount++;
  assert.throws(() => verifyCertificate(altered, cert.marker, trust), /invalid_or_stale/);
});

test('ready alone, deleted certified owner, absent shard and modified evidence fail safely', async () => {
  for (const change of [
    (docs, cert) => docs.set('mp_ownership_index/active', { version: 1, state: 'ready', epoch: 'fixture-v1' }),
    (docs, cert) => docs.delete('mp_account_owners/123'),
    (docs, cert) => docs.delete(`mp_index_evidence/${cert.marker.certificateId}_${merchantPrefix('123')}`),
    (docs, cert) => { docs.get(`mp_index_evidence/${cert.marker.certificateId}_${merchantPrefix('123')}`).claims['123'].userId = 'intruder'; },
  ]) {
    const { db, docs, cert } = await fixture(); change(docs, cert);
    await assert.rejects(canonicalIntegrationMatches(db, 123));
    assert.equal(docs.get('users/owner/integrations/mercado_pago').status, 'connected');
  }
});

test('same-owner reconnections preserve audit metadata; unsigned UID change and missing legacy owner cannot claim', async () => {
  const { db, docs } = await fixture();
  docs.set(authorizationControlRef(db, 'owner').path, { generation: 0 });
  const auth = { userId: 'owner', platformId: 'mercado_pago', generation: 0 };
  for (let i = 0; i < 3; i++) await persistOwnedIntegration(db, 'owner', '000123', [], auth);
  assert.deepEqual(docs.get('mp_account_owners/123').audit, { original: 'keep' });
  assert.equal(docs.get('mp_account_owners/123').migrationProof, 'keep-too');
  assert.equal(docs.get('mp_account_owners/123').merchantId, '123');
  docs.get('mp_account_owners/123').userId = 'intruder';
  await assert.rejects(canonicalIntegrationMatches(db, 123), { status: 409 });
  docs.delete('mp_account_owners/123');
  docs.set(authorizationControlRef(db, 'intruder').path, { generation: 0 });
  await assert.rejects(persistOwnedIntegration(db, 'intruder', 123, [], { ...auth, userId: 'intruder' }), { status: 409 });
});

test('even properly signed stale or inconsistent certification cannot be activated', async () => {
  const { db, docs, cert } = await fixture();
  const payload = { ...cert.certificate.payload, capturedAtMs: Date.now() - 90000000 };
  const id = evidenceHash(payload);
  docs.set(`mp_index_certificates/${id}`, signFixturePayload(payload));
  docs.set('mp_ownership_index/active', { ...cert.marker, certificateId: id });
  await assert.rejects(canonicalIntegrationMatches(db, 123), { status: 503 });
});

test('signed malformed claims cannot be interpreted as certified merchant absence', async () => {
  for (const invalidClaim of [null, false, 0, 'owned', { state: 'unknown' }]) {
    const { db, docs, cert } = await fixture();
    const prefix = merchantPrefix('123');
    const shard = { version: 1, claims: { 123: invalidClaim } };
    const payload = { ...cert.certificate.payload, shardDigests: { ...cert.certificate.payload.shardDigests, [prefix]: evidenceHash(shard) } };
    const id = evidenceHash(payload);
    docs.set(`mp_index_certificates/${id}`, signFixturePayload(payload));
    docs.set(`mp_index_evidence/${id}_${prefix}`, shard);
    docs.set('mp_ownership_index/active', { ...cert.marker, certificateId: id });
    await assert.rejects(canonicalIntegrationMatches(db, 123), { status: 503 });
  }
});
