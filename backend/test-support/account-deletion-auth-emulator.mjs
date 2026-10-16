// Explicit opt-in local integration. No production credentials, imports/exports or cleanup.
import assert from 'node:assert/strict';
import { remediationProbes } from './beta-remediation-probes.mjs';
import { betaSecurityProbes } from './beta-security-probes.mjs';
import { authenticatedUid } from '../mercado-pago-security.js';
import { createRequire } from 'node:module';
import { spawn } from 'node:child_process';
import { once } from 'node:events';
import { mkdirSync, openSync, closeSync } from 'node:fs';
import { resolve } from 'node:path';
import { createServer } from 'node:net';
import admin from 'firebase-admin';
import { Firestore } from '@google-cloud/firestore';
import express from 'express';
import { accountDeletionIntakeRouter, firestoreIntakeStore, intakeNotice } from '../account-deletion-intake.js';
import { intakeEnabled } from '../account-deletion-gate.js';
const env=process.env, projectId='demo-torico-intake';
assert.equal(env.TORICO_INTAKE_EMULATOR_TEST,projectId);
assert.equal(env.FIREBASE_AUTH_EMULATOR_HOST,'127.0.0.1:19099');
assert.equal(env.FIRESTORE_EMULATOR_HOST,'127.0.0.1:18891');
assert.ok(intakeEnabled(env));
for(const field of ['FIREBASE_TOKEN','TOKEN_ENCRYPTION_KEY','MERCADO_PAGO_CLIENT_SECRET'])assert.ok(!env[field]);
// Refuse occupied ports: never attach to or mutate a pre-existing emulator.
for(const port of [18891,19099]){
  await new Promise((ok,reject)=>{const probe=createServer();probe.once('error',reject);
    probe.listen(port,'127.0.0.1',()=>probe.close(ok));});
}
const require=createRequire(import.meta.url);
const {AuthEmulator}=require(resolve(process.argv[2]));
const emulator=new AuthEmulator({projectId,host:'127.0.0.1',port:19099,singleProjectMode:2});
mkdirSync('.tmp-deletion-hardening',{recursive:true});
const log=openSync('.tmp-deletion-hardening/firestore.log','a');
const firestore=spawn('java',['-jar',resolve(process.argv[3]),'--host','127.0.0.1','--port','18891','--project_id',projectId,
  '--single_project_mode','true','--single_project_mode_error','true','--rules',resolve('firestore.rules')],{stdio:['ignore',log,log],windowsHide:true});
let app,server,db;
try {
  let ready=false;
  for(let i=0;i<80;i++){
    if(firestore.exitCode!==null)throw Error('Firestore emulator exited');
    try {if((await fetch('http://127.0.0.1:18891/')).ok){ready=true;break;}}catch(_){}
    await new Promise(r=>setTimeout(r,250));
  }
  assert.ok(ready,'Firestore emulator ready');
  await emulator.start();
  app=admin.initializeApp({projectId,credential:{getAccessToken:async()=>({access_token:'owner',expires_in:3600})}},'isolated-intake');
  const auth=app.auth();
  db=new Firestore({projectId,host:env.FIRESTORE_EMULATOR_HOST,ssl:false});
  const store=firestoreIntakeStore(db);
  let clockOffset=0;
  const api=express();api.use('/v1/account-deletion',accountDeletionIntakeRouter({enabled:intakeEnabled(env),auth,store,projectId,now:()=>Date.now()+clockOffset,observe:()=>{}}));
  server=await new Promise(r=>{const x=api.listen(0,'127.0.0.1',()=>r(x));});
  const base=`http://127.0.0.1:${server.address().port}/v1/account-deletion/requests`;
  async function signup(name){
    const response=await fetch('http://127.0.0.1:19099/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-local-key',{
      method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({email:`${name}@example.invalid`,password:'local-fixture-only-123',returnSecureToken:true})});
    assert.equal(response.status,200);return response.json();
  }
  const a=await signup('fixture-a'),b=await signup('fixture-b');
  await betaSecurityProbes({ auth, db, a, b, projectId });
  await remediationProbes({ auth, db, a, b, projectId });
  const body={confirmation:'delete_account',noticeVersion:intakeNotice,policyVersion:intakeNotice};
  const call=(token,method='POST',suffix='',key='local_fixture_key_12345678901234567890')=>fetch(base+suffix,{
    method,headers:{Authorization:`Bearer ${token}`,'Content-Type':'application/json','Idempotency-Key':key},
    body:method==='POST'?JSON.stringify(body):undefined});
  assert.equal((await call('invalid-token')).status,401);
  const results=await Promise.all(Array.from({length:3},(_,i)=>call(a.idToken,'POST','',`local_fixture_key_12345678901234567890${i}`).then(async r=>{assert.equal(r.status,202);return r.json();})));
  assert.equal(new Set(results.map(r=>r.protocol)).size,1);
  assert.equal((await db.collection('account_deletion_idempotency').get()).size,3);
  assert.equal((await call(b.idToken,'GET','/'+results[0].requestId)).status,404);
  assert.equal((await call(a.idToken,'GET','/current')).status,200);
  // Advance only the router clock: SDK still validates an actual emulator-issued token.
  clockOffset=301000;
  assert.equal((await call(a.idToken)).status,403);
  clockOffset=0;
  await new Promise(r=>setTimeout(r,1100));
  await auth.revokeRefreshTokens(a.localId); // Fixture in the local Auth Emulator only.
  assert.equal((await call(a.idToken,'GET','/current')).status,401);
  await assert.rejects(authenticatedUid({ headers: { authorization: `Bearer ${a.idToken}` } }, auth), { status: 401 });
  const root=`http://127.0.0.1:18891/v1/projects/${projectId}/databases/(default)/documents/`;
  for(const user of [a,b]){
    const response=await fetch(root+'account_deletion_requests/'+results[0].requestId,{headers:{Authorization:`Bearer ${user.idToken}`}});
    assert.equal(response.status,403);
  }
  console.log('PASS Auth + Firestore Emulator: valid/invalid/revoked tokens, recent auth, UID isolation, concurrency, private Rules');
} finally {
  if(server)await new Promise(r=>{server.closeAllConnections();server.close(r);});
  if(db)await db.terminate();
  if(app)await app.delete();
  await emulator.stop();
  if(firestore.exitCode===null){const stopped=once(firestore,'exit');firestore.kill();await stopped;}
  closeSync(log);
}
