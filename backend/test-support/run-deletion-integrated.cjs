// Explicit local opt-in launcher; no shell, credentials, dotenv or Firebase CLI.
const { spawnSync } = require('node:child_process');
const { resolve } = require('node:path');
const { mkdirSync, existsSync } = require('node:fs');
if (process.argv.length !== 5) throw Error('Provide installed Auth Emulator module, Firestore JAR and Flutter SDK root');
for (const file of ['.env', 'backend/.env']) if (existsSync(file)) throw Error('Refuse dotenv files');
const home = resolve('.tmp-deletion-integrated/isolated-home');
mkdirSync(home, { recursive: true });
const env = {
  PATH: process.env.PATH, PATHEXT: process.env.PATHEXT, ComSpec: process.env.ComSpec,
  SystemRoot: process.env.SystemRoot, TEMP: process.env.TEMP, TMP: process.env.TMP,
  HOME: home, USERPROFILE: home, APPDATA: home, LOCALAPPDATA: home, XDG_CONFIG_HOME: home,
  ANDROID_HOME: process.env.ANDROID_HOME || resolve(process.env.LOCALAPPDATA || home, 'Android/Sdk'),
  CI: 'true', FIREBASE_CLI_DISABLE_TELEMETRY: '1', DART_SUPPRESS_ANALYTICS: 'true', FLUTTER_SUPPRESS_ANALYTICS: 'true',
  ACCOUNT_DELETION_INTAKE_ENABLED: 'true', FIREBASE_PROJECT_ID: 'demo-torico-intake',
  TORICO_INTAKE_EMULATOR_TEST: 'demo-torico-intake', FIREBASE_AUTH_EMULATOR_HOST: '127.0.0.1:19099',
  FIRESTORE_EMULATOR_HOST: '127.0.0.1:18891', PORT: '18893',
};
// Public OS/tool-discovery paths only; never copy the complete parent environment.
for (const name of ['ProgramFiles', 'ProgramFiles(x86)', 'ProgramW6432', 'PROCESSOR_ARCHITECTURE',
  'NUMBER_OF_PROCESSORS', 'windir', 'SystemDrive', 'OS']) {
  if (process.env[name]) env[name] = process.env[name];
}
const result = spawnSync(process.execPath, [resolve('backend/test-support/account-deletion-integrated.mjs'),
  ...process.argv.slice(2)], { env, stdio: 'inherit', windowsHide: true });
if (result.error) throw result.error;
process.exitCode = result.status ?? 1;
