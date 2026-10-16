// Sanitized child environment: never inherit ADC, Firebase CLI tokens or backend secrets.
const {spawnSync}=require('node:child_process');
const {resolve}=require('node:path');
const {mkdirSync}=require('node:fs');
const isolatedHome=resolve('.tmp-deletion-hardening/isolated-home');
mkdirSync(isolatedHome,{recursive:true});
const env={HOME:isolatedHome,USERPROFILE:isolatedHome,APPDATA:isolatedHome,XDG_CONFIG_HOME:isolatedHome,PATH:process.env.PATH,SystemRoot:process.env.SystemRoot,TEMP:process.env.TEMP,TMP:process.env.TMP,
  ACCOUNT_DELETION_INTAKE_ENABLED:'true',FIREBASE_PROJECT_ID:'demo-torico-intake',
  TORICO_INTAKE_EMULATOR_TEST:'demo-torico-intake',FIREBASE_AUTH_EMULATOR_HOST:'127.0.0.1:19099',FIRESTORE_EMULATOR_HOST:'127.0.0.1:18891',
  CI:'true',FIREBASE_CLI_DISABLE_TELEMETRY:'1'};
if(process.argv.length!==4)throw Error('Provide installed firebase-tools Auth module and official Firestore emulator JAR paths');
const result=spawnSync(process.execPath,[resolve('backend/test-support/account-deletion-auth-emulator.mjs'),...process.argv.slice(2)],{env,stdio:'inherit',windowsHide:true});
if(result.error)throw result.error;
process.exitCode=result.status??1;
