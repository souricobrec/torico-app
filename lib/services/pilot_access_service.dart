import 'package:shared_preferences/shared_preferences.dart';

/// Public UI rollout configuration, not an API/Firestore authorization mechanism.
class PilotAccessService {
  static const storageKey = 'torico_pilot_requested';
  static const configuredUids = String.fromEnvironment('PILOT_ALLOWED_UIDS');
  static Set<String> parseUids(String value) => value
      .split(',')
      .map((uid) => uid.trim())
      .where((uid) => uid.isNotEmpty)
      .toSet();

  final Set<String> allowedUids;
  bool requested = false;

  PilotAccessService({Set<String>? allowedUids})
    : allowedUids = allowedUids ?? parseUids(configuredUids);

  bool allows(String? uid) =>
      requested && uid != null && allowedUids.contains(uid);

  Future<void> initialize(Uri uri) async {
    requested = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final flags = uri.queryParametersAll['pilot'];
      // Multiple or unknown values must not enable access.
      if (flags != null && (flags.length != 1 || flags.single != '1')) {
        await prefs.remove(storageKey);
        return;
      }
      if (allowedUids.isEmpty) {
        await prefs.remove(storageKey);
        return;
      }
      requested = flags?.single == '1' || prefs.getBool(storageKey) == true;
      if (requested) await prefs.setBool(storageKey, true);
    } catch (_) {
      // Storage unavailable: fail closed and keep pre-launch visible.
      requested = false;
    }
  }

  Future<void> clear() async {
    requested = false;
    try {
      await (await SharedPreferences.getInstance()).remove(storageKey);
    } catch (_) {
      // Remains blocked in memory even if the browser denies storage.
    }
  }
}
