import test from 'node:test';
import assert from 'node:assert/strict';
import { canonicalIntegrationMatches, MP_INDEX_METADATA_PATH } from '../mercado-pago-security.js';

import { certificationFixture, fixtureTrust } from '../test-support/certification-fixture.mjs';

function fixture() {
  Object.assign(process.env, fixtureTrust);
  const certificate = certificationFixture([{id:'123',userId:'owner'}],{epoch:'test-v1'});
  const data = new Map([
    [MP_INDEX_METADATA_PATH, certificate.marker],
    [`mp_index_certificates/${certificate.marker.certificateId}`, certificate.certificate],
    ['mp_account_owners/123', { indexVersion: 1, indexEpoch: 'test-v1', state: 'owned', userId: 'owner' }],
    ['users/owner/integrations/mercado_pago', { platformId: 'mercado_pago', mercadoPagoUserId: ' 000123 ', status: 'connected' }],
  ]);
  for (const [prefix,shard] of Object.entries(certificate.shards)) if(Object.keys(shard.claims).length) data.set(`mp_index_evidence/${certificate.marker.certificateId}_${prefix}`,shard);
  const reads = [];
  const db = { projectId: 'demo-index-unit', collection: name => ({ doc: id => db.doc(`${name}/${id}`) }),
    runTransaction: fn => fn({ get: ref => ref.get() }),
    collectionGroup: () => { throw Error('No global inventory allowed'); },
    doc: path => ({ path, get: async () => { reads.push(path); return {
      exists: data.has(path), ref: { path }, data: () => data.get(path),
    }; } }),
  };
  return { db, data, reads };
}

test('501, 1000 and 2001 unrelated/invalid records do not affect targeted resolution or read count', async () => {
  for (const count of [501, 1000, 2001]) {
    const { db, data, reads } = fixture();
    for (let i = 0; i < count; i++) {
      data.set(`users/unrelated-${i}/integrations/${i % 2 ? 'rede' : 'mercado_pago'}`, { mercadoPagoUserId: 'invalid', status: 'disconnected' });
      data.set(`mp_account_owners/invalid-${i}`, { userId: 'legacy' });
    }
    assert.equal((await canonicalIntegrationMatches(db, 123)).length, 1);
    assert.equal(reads.length, 5);
    assert.ok(reads.every(path => !path.includes('unrelated') && !path.includes('invalid-')));
  }
});

test('missing/incomplete certification is never interpreted as merchant absence', async () => {
  for (const marker of [undefined, { version: 1, state: 'building', epoch: 'test-v1' }, { version: 2, state: 'ready', epoch: 'test-v1' }]) {
    const { db, data } = fixture();
    if (marker) data.set(MP_INDEX_METADATA_PATH, marker); else data.delete(MP_INDEX_METADATA_PATH);
    await assert.rejects(canonicalIntegrationMatches(db, 123), { status: 503, code: 'merchant_index_not_ready' });
  }
});

test('ambiguous, stale and unversioned owners block only the affected merchant; absence is certified', async () => {
  for (const owner of [
    { indexVersion: 1, indexEpoch: 'test-v1', state: 'conflict' },
    { indexVersion: 1, indexEpoch: 'old', state: 'owned', userId: 'other' },
    { userId: 'legacy-owner' },
  ]) {
    const { db, data } = fixture(); data.set('mp_account_owners/456', owner);
    await assert.rejects(canonicalIntegrationMatches(db, 456), { status: 409 });
    assert.equal((await canonicalIntegrationMatches(db, '000123')).length, 1);
    assert.deepEqual(await canonicalIntegrationMatches(db, '789'), []);
  }
});

test('invalid indexed integration is isolated; replacement credentials never route the former account', async () => {
  const { db, data } = fixture();
  data.set('mp_account_owners/456', { indexVersion: 1, indexEpoch: 'test-v1', state: 'owned', userId: 'bad' });
  data.set('users/bad/integrations/mercado_pago', { platformId: 'mercado_pago', mercadoPagoUserId: 'invalid' });
  await assert.rejects(canonicalIntegrationMatches(db, 456), { status: 409 });
  assert.equal((await canonicalIntegrationMatches(db, 123)).length, 1);
  data.set('users/owner/integrations/mercado_pago', { platformId: 'mercado_pago', mercadoPagoUserId: 789 });
  assert.deepEqual(await canonicalIntegrationMatches(db, 123), []);
});
