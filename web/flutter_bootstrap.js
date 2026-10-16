{{flutter_js}}
{{flutter_build_config}}

// TORICO_IMMUTABLE_BOOTSTRAP_V1
// Relative engine/assets/entrypoint URLs stay in the same immutable snapshot.
const toricoReleaseBase = new URL('.', document.currentScript.src).href;
_flutter.loader.load({
  config: {
    entrypointBaseUrl: toricoReleaseBase,
    assetBase: toricoReleaseBase,
    canvasKitBaseUrl: new URL('canvaskit/', toricoReleaseBase).href,
  },
});
