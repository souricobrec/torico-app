// Only local demo emulators. A production rollout requires a separate review.
export function intakeEnabled(env = {}) {
  const local = value => {
    const match = /^(127\.0\.0\.1|localhost|\[::1\]):([1-9]\d{0,4})$/.exec(value || '');
    return Boolean(match && Number(match[2]) <= 65535);
  };
  const project = env.FIREBASE_PROJECT_ID;
  return env.ACCOUNT_DELETION_INTAKE_ENABLED === 'true' &&
    /^demo-[a-z0-9-]+$/.test(project || '') &&
    local(env.FIRESTORE_EMULATOR_HOST) && local(env.FIREBASE_AUTH_EMULATOR_HOST) &&
    !env.K_SERVICE && !env.FIREBASE_SERVICE_ACCOUNT_PATH && !env.GOOGLE_APPLICATION_CREDENTIALS &&
    [env.GOOGLE_CLOUD_PROJECT, env.GCLOUD_PROJECT].every(value => !value || value === project);
}

// Express has already decoded the mount path when this router is selected.
// Mount this dispatcher before the global JSON parser; non-intake APIs continue unchanged.
export function intakeDispatcher(resolveRouter) {
  return (req, res, next) => resolveRouter()(req, res, next);
}
