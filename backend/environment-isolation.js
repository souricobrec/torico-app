export function validateEmulatorIsolation(env) {
  const project = env.FIREBASE_PROJECT_ID || env.GOOGLE_CLOUD_PROJECT || env.GCLOUD_PROJECT || '';
  if (env.APP_ENV && !['production', 'development', 'preview', 'demo', 'test'].includes(env.APP_ENV)) {
    throw new Error('Unknown APP_ENV; startup refused.');
  }
  if (env.NODE_ENV && !['production', 'development', 'test'].includes(env.NODE_ENV)) {
    throw new Error('Unknown NODE_ENV; startup refused.');
  }
  const localMode = ['development', 'preview', 'demo', 'test'].includes(env.APP_ENV) ||
    ['development', 'test'].includes(env.NODE_ENV);
  if ((env.APP_ENV === 'production' && localMode) ||
      (localMode && env.NODE_ENV === 'production') || (env.K_SERVICE && localMode)) {
    throw new Error('Inconsistent runtime modes; startup refused.');
  }
  if ([env.GOOGLE_CLOUD_PROJECT, env.GCLOUD_PROJECT].some(value => value && value !== project)) {
    throw new Error('Inconsistent Firebase project aliases; startup refused.');
  }
  const demo = project.startsWith('demo-');
  const emulator = Boolean(env.FIREBASE_AUTH_EMULATOR_HOST || env.FIRESTORE_EMULATOR_HOST);
  if ((env.APP_ENV === 'production' || env.NODE_ENV === 'production') && (demo || emulator)) {
    throw new Error('Production cannot use demo/emulators; startup refused.');
  }
  if (demo && !/^demo-[a-z0-9-]+$/.test(project)) throw new Error('Invalid demo project; startup refused.');
  if (localMode && !demo) {
    throw new Error('Unsafe non-production project; startup refused.');
  }
  if (!demo && !emulator) return;
  const local = value => {
    const match = /^(127\.0\.0\.1|localhost):([1-9][0-9]{0,4})$/.exec(value || '');
    return Boolean(match && Number(match[2]) <= 65535);
  };
  if (!demo || !local(env.FIREBASE_AUTH_EMULATOR_HOST) || !local(env.FIRESTORE_EMULATOR_HOST) ||
      env.K_SERVICE || env.GOOGLE_APPLICATION_CREDENTIALS || env.FIREBASE_SERVICE_ACCOUNT_PATH ||
      env.FIREBASE_TOKEN || env.MERCADO_PAGO_CLIENT_SECRET || env.PAGBANK_CLIENT_SECRET || env.TOKEN_ENCRYPTION_KEY ||
      [env.GOOGLE_CLOUD_PROJECT, env.GCLOUD_PROJECT].some(value => value && value !== project)) {
    throw new Error('Unsafe demo/emulator configuration; startup refused.');
  }
}
