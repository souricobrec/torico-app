// Opt-in local integration: existing emulator only. Never starts server.js/ADC.
import assert from 'node:assert/strict';
import { randomBytes } from 'node:crypto';
import { Firestore } from '@google-cloud/firestore';
import { firestoreIntakeStore, intakeNotice } from '../account-deletion-intake.js';
const host=process.env.FIRESTORE_EMULATOR_HOST;
assert.equal(host,'127.0.0.1:18891','Only the explicit loopback emulator is allowed');
assert.equal(process.env.TORICO_INTAKE_EMULATOR_TEST,'demo-torico-intake','Explicit demo opt-in required');
assert.equal(Boolean(process.env.K_SERVICE),false,'Never run on Cloud Run');
const projectId='demo-torico-intake';
const db=new Firestore({projectId,host,ssl:false});
try {
  const uid='fixture-owner-'+randomBytes(8).toString('hex');
  const store=firestoreIntakeStore(db);
  const body={confirmation:'delete_account',noticeVersion:intakeNotice,policyVersion:intakeNotice};
  await db.collection('users').doc(uid).set({displayName:'fixture'});
  const requests=await Promise.all([store.register(uid,'key-a',body),store.register(uid,'key-a',body),store.register(uid,'key-b',body)]);
  assert.equal(new Set(requests.map(r=>r.protocol)).size,1);
  assert.equal((await store.current(uid)).protocol,requests[0].protocol);
  assert.equal((await db.collection('users').doc(uid).get()).data().displayName,'fixture');
  assert.equal((await db.collection('account_lifecycle').doc(uid).get()).exists,false);
  console.log('PASS real emulator transactions: one protocol, profile preserved, no lifecycle');
  const root=`http://${host}/v1/projects/${projectId}/databases/(default)/documents`;
  function token(sub){const now=Math.floor(Date.now()/1000);return [
    Buffer.from(JSON.stringify({alg:'none',typ:'JWT'})).toString('base64url'),
    Buffer.from(JSON.stringify({sub,user_id:sub,aud:projectId,iss:`https://securetoken.google.com/${projectId}`,iat:now,exp:now+3600,auth_time:now,firebase:{sign_in_provider:'password'}})).toString('base64url'),''
  ].join('.');}
  async function read(path,sub){return fetch(root+'/'+path,{headers:{Authorization:'Bearer '+token(sub)}});}
  assert.equal((await read('users/'+uid,uid)).status,200,'Positive control: fixture owner can read own profile under Rules');
  for(const sub of [uid,'fixture-other']){
    for(const path of ['account_deletion_requests/'+requests[0].requestId,'account_deletion_requests','account_deletion_subjects/'+requests[0].subjectRef]){
      assert.equal((await read(path,sub)).status,403,'Private intake denied to clients');
    }
  }
  const denied=await fetch(root+'/account_deletion_requests/'+requests[0].requestId,{method:'PATCH',headers:{Authorization:'Bearer '+token(uid),'Content-Type':'application/json'},body:JSON.stringify({fields:{probe:{stringValue:'must-not-write'}}})});
  assert.equal(denied.status,403);
  assert.equal((await store.current(uid)).status,'received');
  console.log('PASS existing Rules: own-profile positive control, own/other private read/list/write denied');
} finally {
  await db.terminate(); // Close local SDK resources; no account/document deletion.
}
