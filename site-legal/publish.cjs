// Add legal files to a clone of the live Hosting version; never rebuild the PWA.
// Authentication stays in memory via the installed official Firebase CLI.
const fs=require('fs'),path=require('path'),crypto=require('crypto'),zlib=require('zlib');
const cli=process.env.FIREBASE_TOOLS_ROOT;
if(!cli)throw Error('Set FIREBASE_TOOLS_ROOT to the installed firebase-tools package');
const auth=require(path.join(cli,'lib/auth'));
const site='torico-ca479',base='https://firebasehosting.googleapis.com/v1beta1/';
const additions=['privacidade/index.html','termos/index.html','suporte/index.html','exclusao-de-conta/index.html','torico-legal/legal.css'];
const mode=process.argv[2],reportDir=process.argv[3];
if(!['inspect','publish'].includes(mode)||!reportDir)throw Error('Usage: node publish.cjs inspect|publish REPORT_DIRECTORY');
let token;
async function api(resource,method='GET',body){
 const r=await fetch(base+resource,{method,headers:{Authorization:'Bearer '+token,'Content-Type':'application/json'},body:body===undefined?undefined:JSON.stringify(body),signal:AbortSignal.timeout(60000)});
 if(!r.ok)throw Error(`Hosting ${method} failed: HTTP ${r.status} at ${resource.split('?')[0]}`);
 return r.json();
}
async function files(version){let result={},page='';do{const r=await api(version+'/files?pageSize=1000'+(page?'&pageToken='+encodeURIComponent(page):''));for(const f of r.files||[])result[f.path]=f.hash;page=r.nextPageToken||'';}while(page);return result;}
async function live(){const r=await api('sites/'+site+'/releases?pageSize=1');if(!r.releases?.[0]?.version)throw Error('No live version');return r.releases[0];}
async function main(){
 fs.mkdirSync(reportDir,{recursive:true});
 const account=auth.getGlobalDefaultAccount();if(!account?.tokens?.refresh_token)throw Error('Firebase CLI login required');
 const access=await auth.getAccessToken(account.tokens.refresh_token,['https://www.googleapis.com/auth/cloud-platform','https://www.googleapis.com/auth/firebase']);token=access.access_token;
 const previous=await live(),version=await api(previous.version.name),oldFiles=await files(previous.version.name);
 const backup={release:previous.name,version:previous.version.name,releaseTime:previous.releaseTime,config:version.config,files:oldFiles};
 fs.writeFileSync(path.join(reportDir,'hosting-before.json'),JSON.stringify(backup,null,2));
 console.log(JSON.stringify({previousRelease:backup.release,previousVersion:backup.version,existingFiles:Object.keys(oldFiles).length,configSaved:true}));
 if(mode==='inspect')return;
 const routes=additions.filter(p=>p.endsWith('/index.html')).map(p=>({glob:'/'+p.split('/')[0],path:'/'+p}));
 const expectedConfig={...version.config,rewrites:[...routes,...(version.config.rewrites||[])]};
 if((version.config.rewrites||[]).some(r=>routes.some(n=>n.glob===r.glob)))throw Error('Legal rewrite collision');
 for(const p of additions)if(oldFiles['/'+p])throw Error('Legal route collision: '+p);
 let operation=await api('sites/'+site+'/versions:clone','POST',{sourceVersion:previous.version.name,finalize:false});
 while(!operation.done){await new Promise(r=>setTimeout(r,2000));operation=await api(operation.name);}
 if(operation.error)throw Error('Clone operation failed');
 const next=operation.response?.name;if(!next)throw Error('Clone returned no version');
 await api(next+'?updateMask=config','PATCH',{config:expectedConfig});
 const zipped={},hashes={};for(const p of additions){const data=zlib.gzipSync(fs.readFileSync(path.join(__dirname,'public',p)));const hash=crypto.createHash('sha256').update(data).digest('hex');hashes['/'+p]=hash;zipped[hash]=data;}
 const pop=await api(next+':populateFiles','POST',{files:hashes});
 for(const hash of pop.uploadRequiredHashes||[]){const r=await fetch(pop.uploadUrl+'/'+hash,{method:'POST',headers:{Authorization:'Bearer '+token,'Content-Type':'application/octet-stream'},body:zipped[hash],signal:AbortSignal.timeout(60000)});if(!r.ok)throw Error('Legal upload failed: HTTP '+r.status);}
 const nextFiles=await files(next),nextVersion=await api(next);
 const normalized=c=>JSON.stringify(Object.fromEntries(Object.entries(c).sort(([a],[b])=>a.localeCompare(b))));
 if(normalized(nextVersion.config)!==normalized(expectedConfig))throw Error('Unexpected config change: release stopped');
 for(const [p,h] of Object.entries(oldFiles))if(nextFiles[p]!==h)throw Error('Original file changed: '+p);
 const changed=Object.keys(nextFiles).filter(p=>oldFiles[p]!==nextFiles[p]);
 if(changed.length!==additions.length||changed.some(p=>hashes[p]!==nextFiles[p]))throw Error('Unexpected file changes: release stopped');
 await api(next+'?updateMask=status','PATCH',{status:'FINALIZED'});
 if((await live()).version.name!==previous.version.name)throw Error('Concurrent live release: publish stopped');
 const release=await api('sites/'+site+'/releases?versionName='+encodeURIComponent(next),'POST',{message:'Add four public TORICO legal routes; preserve PWA files and config'});
 const report={previousRelease:previous.name,previousVersion:previous.version.name,newRelease:release.name,newVersion:next,changedFiles:changed,preservedOriginalFiles:Object.keys(oldFiles).length,originalConfigPreserved:true,addedExactLegalRewrites:routes};
 fs.writeFileSync(path.join(reportDir,'hosting-after.json'),JSON.stringify(report,null,2));console.log(JSON.stringify(report));
}
main().catch(e=>{console.error(e.message);process.exitCode=1;});
