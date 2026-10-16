export function validateEmulatorIsolation(env) {
  const project = env.FIREBASE_PROJECT_ID || env.GOOGLE_CLOUD_PROJECT || env.GCLOUD_PROJECT || '';
  const demo = project.startsWith('demo-');
  const emulator = Boolean(env.FIREBASE_AUTH_EMULATOR_HOST || env.FIRESTORE_EMULATOR_HOST);
  if (['development', 'preview'].includes(env.APP_ENV) && !demo) {
    throw new Error('Unsafe non-production project; startup refused.');
  }
  if (!demo && !emulator) return;
  const local = value => /^(127\.0\.0\.1|localhost):[1-9][0-9]{0,4}$/.test(value || '');
  if (!demo || !local(env.FIREBASE_AUTH_EMULATOR_HOST) || !local(env.FIRESTORE_EMULATOR_HOST) ||
      env.K_SERVICE || env.GOOGLE_APPLICATION_CREDENTIALS || env.FIREBASE_SERVICE_ACCOUNT_PATH ||
      [env.GOOGLE_CLOUD_PROJECT, env.GCLOUD_PROJECT].some(value => value && value !== project)) {
    throw new Error('Unsafe demo/emulator configuration; startup refused.');
  }
}
