import test from 'node:test';
import assert from 'node:assert/strict';
import express from 'express';
import { readFileSync } from 'node:fs';
import { intakeEnabled, intakeDispatcher } from '../account-deletion-gate.js';
import { accountDeletionIntakeRouter, firestoreIntakeStore, intakeNotice, intakeParsingError } from '../account-deletion-intake.js';

const time = 1800000000000;
const body = { confirmation:'delete_account', noticeVersion:intakeNotice, policyVersion:intakeNotice };
const key = 'fixture_key_1234567890123456789012345';
function memoryDb() {
  const data = new Map(); let queue = Promise.resolve();
  const db = { data, failBefore:false, failAfter:false,
    collection: name => ({ doc:id => reference(`${name}/${id}`) }),
    runTransaction(fn) {
      const run = queue.then(async()=>{
        if(db.failBefore)throw Error('fixture unavailable');
        const writes=[];
        const result=await fn({ get:async r=>({ data:()=>structuredClone(data.get(r.path)) }),set:(r,v)=>writes.push([r.path,structuredClone(v)]) });
        for(const [p,v] of writes)data.set(p,v);
        if(db.failAfter){db.failAfter=false;throw Error('fixture lost response');}
        return result;
      }); queue=run.catch(()=>{});return run;
    },
  };
  function reference(path){ return { path, collection:n=>({doc:id=>reference(`${path}/${n}/${id}`)}),get:async()=>({data:()=>structuredClone(data.get(path))}) }; }
  return db;
}
async function fixture(t,{enabled=true,tokenPatch={},authError=null,observe=()=>{},trustProxy=false}={}) {
  const db=memoryDb();let clock=time,verifyCalls=0;
  const store=firestoreIntakeStore(db,{now:()=>clock});
  const auth={verifyIdToken:async(token,revoked)=>{
    verifyCalls++;assert.equal(revoked,true);
    if(authError)throw Object.assign(Error('not logged'),{code:authError});
    if(!['owner-a','owner-b'].includes(token))throw Object.assign(Error('bad'),{code:'auth/invalid-id-token'});
    return {uid:token,sub:token,aud:'demo-torico-intake',iss:'https://securetoken.google.com/demo-torico-intake',auth_time:Math.floor(clock/1000),...tokenPatch};
  }};
  const app=express();app.set('trust proxy',trustProxy);
  app.use('/v1/account-deletion',accountDeletionIntakeRouter({enabled,auth,store,projectId:'demo-torico-intake',now:()=>clock,observe}));
  const server=await new Promise(resolve=>{const s=app.listen(0,'127.0.0.1',()=>resolve(s));});t.after(()=>new Promise(resolve=>{server.closeAllConnections();server.close(resolve);}));
  const url=`http://127.0.0.1:${server.address().port}/v1/account-deletion`;
  async function call(path='/requests',{method='POST',token='owner-a',payload=body,idem=key,headers={}}={}){
    const h={'Content-Type':'application/json','Idempotency-Key':idem,...headers};if(token)h.Authorization=`Bearer ${token}`;
    const r=await fetch(url+path,{method,headers:h,body:method==='POST'?JSON.stringify(payload):undefined});
    return {status:r.status,body:await r.json(),cache:r.headers.get('cache-control'),retry:r.headers.get('retry-after')};
  }
  return {db,store,call,get verifies(){return verifyCalls;},tick:()=>{clock+=61000;}};
}

test('default OFF performs no auth or writes',async t=>{
  const f=await fixture(t,{enabled:false});assert.equal((await f.call()).status,404);assert.equal(f.verifies,0);assert.equal([...f.db.data.keys()].filter(p=>!p.startsWith('account_deletion_rate_limits/')).length,0);
  assert.equal(accountDeletionIntakeRouter().stack.length>0,true);
});
test('missing/invalid/revoked tokens and Auth outage never register',async t=>{
  const f=await fixture(t);for(const token of [null,'invalid'])assert.equal((await f.call('/requests',{token})).status,401);assert.equal([...f.db.data.keys()].filter(p=>!p.startsWith('account_deletion_rate_limits/')).length,0);
  for(const [authError,status] of [['auth/id-token-revoked',401],['auth/user-disabled',401],['auth/internal-error',503]]){
    const x=await fixture(t,{authError});assert.equal((await x.call()).status,status);assert.equal([...x.db.data.keys()].filter(p=>!p.startsWith('account_deletion_rate_limits/')).length,0);
  }
});
test('wrong audience/issuer/tenant/UID are rejected',async t=>{
  for(const tokenPatch of [{aud:'other'},{iss:'other'},{firebase:{tenant:'other'}},{uid:''},{sub:'victim'}]){
    const f=await fixture(t,{tokenPatch});assert.equal((await f.call()).status,401);assert.equal([...f.db.data.keys()].filter(p=>!p.startsWith('account_deletion_rate_limits/')).length,0);
  }
});
test('auth_time missing, stale or future does not mean recent login',async t=>{
  for(const auth_time of [undefined,Math.floor(time/1000)-301,Math.floor(time/1000)+1]){
    const f=await fixture(t,{tokenPatch:{auth_time,iat:Math.floor(time/1000)}});assert.equal((await f.call()).status,403);
    assert.equal([...f.db.data.keys()].some(p=>p.startsWith('account_deletion_requests/')),false);
  }
});
test('closed schema, UID injection, query and idempotency key validation',async t=>{
  for(const payload of [{...body,uid:'victim'},{...body,status:'completed'},{...body,confirmation:'no'},[],null]){
    const f=await fixture(t);assert.equal((await f.call('/requests',{payload})).status,400);
  }
  const f=await fixture(t);assert.equal((await f.call('/requests?userId=victim')).status,400);
  assert.equal((await f.call('/requests',{headers:{'x-user-id':'victim'}})).status,400);
  assert.equal((await f.call('/requests',{idem:'short'})).status,400);
});
test('durable received protocol, only private control writes and no data mutation',async t=>{
  const f=await fixture(t);f.db.data.set('users/owner-a',{fixture:true});
  f.db.data.set('users/owner-a/sales/fixture',{amount:1,status:'approved'});
  f.db.data.set('users/owner-a/daily_totals/fixture',{totalSold:1});
  const result=await f.call();
  assert.equal(result.status,202);assert.equal(result.cache,'no-store');assert.equal(result.body.status,'received');assert.equal(result.body.completedAt,null);
  assert.match(result.body.protocol,/^TORICO-[a-f0-9]{48}$/);assert.equal('uid' in result.body,false);assert.equal('subjectRef' in result.body,false);
  assert.deepEqual(f.db.data.get('users/owner-a'),{fixture:true});
  assert.deepEqual(f.db.data.get('users/owner-a/sales/fixture'),{amount:1,status:'approved'});
  assert.deepEqual(f.db.data.get('users/owner-a/daily_totals/fixture'),{totalSold:1});
  for(const p of f.db.data.keys())if(!p.startsWith('users/'))assert.match(p,/^account_deletion_(rate_limits|subjects|uid_index|requests|idempotency|outbox)\//);
  assert.equal([...f.db.data.keys()].some(p=>p.startsWith('account_lifecycle/')),false);
  assert.equal([...f.db.data.values()].some(v=>v.executionAllowed===false),true);
});
test('parallel duplicate requests and new keys produce one protocol',async t=>{
  const f=await fixture(t);const results=await Promise.all([f.call(),f.call(),f.call('/requests',{idem:key+'two'})]);
  assert.equal(new Set(results.map(r=>r.body.protocol)).size,1);assert.ok(results.every(r=>r.status===202));
  assert.equal([...f.db.data.keys()].filter(p=>/^account_deletion_requests\/[^/]+$/.test(p)).length,1);
  await assert.rejects(f.store.register('owner-a',key,{...body,noticeVersion:'changed'}),e=>e.status===409);
});
test('owner only: current/ID reads never disclose other owner or nonexistent request',async t=>{
  const f=await fixture(t);const a=await f.call();const b=await f.call('/requests',{token:'owner-b'});assert.notEqual(a.body.protocol,b.body.protocol);
  const own=await f.call('/requests/current',{method:'GET'});assert.equal(own.body.protocol,a.body.protocol);
  for(const id of [b.body.requestId,'does-not-exist'])assert.equal((await f.call('/requests/'+id,{method:'GET'})).status,404);
  assert.equal((await f.call('/requests/'+a.body.requestId,{method:'GET'})).status,200);
});
test('no request, outages, uncertain commit and repeated key',async t=>{
  const f=await fixture(t);assert.equal((await f.call('/requests/current',{method:'GET'})).status,404);
  f.db.failBefore=true;assert.equal((await f.call()).status,503);f.db.failBefore=false;
  const original=f.store.register;let first=true;f.store.register=async(...args)=>{const r=await original(...args);if(first){first=false;throw Error('response lost');}return r;};
  assert.equal((await f.call()).status,503);const retry=await f.call();assert.equal(retry.status,202);
  assert.equal((await f.call('/requests/current',{method:'GET'})).body.protocol,retry.body.protocol);
});
test('shared transactional rate limit and window reset',async t=>{
  const f=await fixture(t);for(let i=0;i<5;i++)assert.equal((await f.call()).status,202);
  const otherInstance = firestoreIntakeStore(f.db, {now:()=>time});
  await assert.rejects(otherInstance.consumeQuota('owner-a','register',5), e=>e.status===429);
  assert.equal((await f.call('/requests',{token:'owner-b'})).status,202);
  const limited=await f.call();assert.equal(limited.status,429);assert.equal(limited.retry,'60');f.tick();assert.equal((await f.call()).status,202);
});
test('no destructive capabilities or production activation in this phase',()=>{
  const source=readFileSync(new URL('../account-deletion-intake.js',import.meta.url),'utf8');
  assert.doesNotMatch(source.replaceAll('peers.delete(', 'peerEvict('),/\.delete\(|deleteUser\(|revokeRefreshTokens\(|\.disableUser\(|\.updateUser\(|account_lifecycle\//);
  const server=readFileSync(new URL('../server.js',import.meta.url),'utf8');
  assert.match(server,/enabled: intakeEnabled\(process.env\)/);
  const rules=readFileSync(new URL('../../firestore.rules',import.meta.url),'utf8');assert.match(rules,/match \/\{document=\*\*\}[\s\S]*allow read, write: if false/);
});


test('gate configuration matrix fails closed',()=>{
  const safe={ACCOUNT_DELETION_INTAKE_ENABLED:'true',FIREBASE_PROJECT_ID:'demo-torico-intake',FIRESTORE_EMULATOR_HOST:'127.0.0.1:18891',FIREBASE_AUTH_EMULATOR_HOST:'127.0.0.1:19099'};
  assert.equal(intakeEnabled(safe),true);
  for(const field of Object.keys(safe))assert.equal(intakeEnabled({...safe,[field]:undefined}),false);
  for(const patch of [{K_SERVICE:'backend'},{FIREBASE_PROJECT_ID:'torico-ca479'},{GOOGLE_CLOUD_PROJECT:'torico-ca479'},
    {GCLOUD_PROJECT:'real'},{GOOGLE_APPLICATION_CREDENTIALS:'file.json'},{FIREBASE_SERVICE_ACCOUNT_PATH:'file.json'},
    {FIRESTORE_EMULATOR_HOST:'example.com:8080'},{FIREBASE_AUTH_EMULATOR_HOST:'127.0.0.1:99999'},
    {FIREBASE_AUTH_EMULATOR_HOST:'127.0.0.1:0'},{ACCOUNT_DELETION_INTAKE_ENABLED:'TRUE'}]){
    assert.equal(intakeEnabled({...safe,...patch}),false,JSON.stringify(patch));
  }
});

test('many different keys remain bounded and recover the original request',async()=>{
  const db=memoryDb(),store=firestoreIntakeStore(db);
  const results=await Promise.all(Array.from({length:60},(_,i)=>store.register('fixture',key+i,body)));
  assert.equal(new Set(results.map(r=>r.protocol)).size,1);
  assert.equal([...db.data.keys()].filter(p=>p.startsWith('account_deletion_idempotency/')).length,16);
  assert.equal((await store.current('fixture')).protocol,results[0].protocol);
});

test('spoofed proxy headers cannot bypass the socket limiter even if app trusts proxies',async t=>{
  const f=await fixture(t,{trustProxy:true});
  for(let i=0;i<120;i++)await f.call('/requests',{token:null,headers:{'X-Forwarded-For':`192.0.2.${i}`}});
  assert.equal((await f.call('/requests',{headers:{'X-Forwarded-For':'203.0.113.1'}})).status,429);
  f.tick();assert.equal((await f.call()).status,202);
});

test('shared ingress quota works across store instances and fails closed',async()=>{
  const db=memoryDb(),a=firestoreIntakeStore(db),b=firestoreIntakeStore(db);
  await Promise.all(Array.from({length:10},(_,i)=>(i%2?a:b).consumeQuota('intake-ingress','ingress',10)));
  await assert.rejects(b.consumeQuota('intake-ingress','ingress',10),e=>e.status===429);
  db.failBefore=true;await assert.rejects(a.consumeQuota('intake-ingress','ingress',10));
});

test('structured events are sanitized even if dependency errors contain secrets',async t=>{
  const events=[],f=await fixture(t,{observe:e=>events.push(e)});
  await f.call('/requests',{token:'SECRET-invalid-token'});await f.call();await f.call();
  f.db.failBefore=true;await f.call();
  assert.ok(events.some(e=>e.event==='authentication_failed'));
  assert.ok(events.some(e=>e.event==='duplicate_request'));
  assert.ok(events.some(e=>e.event==='service_unavailable'));
  assert.ok(events.some(e=>e.event==='storage_operation_failed'));
  f.db.failBefore=false;for(let i=0;i<8;i++)await f.call();
  assert.ok(events.some(e=>e.event==='rate_limited'));
  for(const e of events)assert.deepEqual(Object.keys(e).sort(),['component','event','stage','status']);
  assert.doesNotMatch(JSON.stringify(events),/SECRET|owner-a|Bearer|fixture unavailable/);
});

test('specific parser precedes global parser; oversized JSON returns 413 without auth',async t=>{
  let authCalls=0;
  const router=accountDeletionIntakeRouter({enabled:true,store:firestoreIntakeStore(memoryDb()),auth:{verifyIdToken:async()=>{authCalls++;throw Error('must not run');}},observe:()=>{}});
  const app=express();app.use('/v1/account-deletion',intakeDispatcher(()=>router));
  app.use(express.json({limit:'1mb'}));app.post('/existing',(req,res)=>res.json({size:req.body.value.length}));
  const server=await new Promise(resolve=>{const x=app.listen(0,'127.0.0.1',()=>resolve(x));});
  t.after(()=>new Promise(resolve=>{server.closeAllConnections();server.close(resolve);}));
  const root=`http://127.0.0.1:${server.address().port}`;
  const send=path=>fetch(root+path,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({value:'a'.repeat(3000)})});
  assert.equal((await send('/v1/account-deletion/requests')).status,413);assert.equal(authCalls,0);
  assert.equal((await send('/existing')).status,200);
});
