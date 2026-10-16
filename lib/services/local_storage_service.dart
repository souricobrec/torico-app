import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  final String? Function() _identity;
  final String? _boundIdentity;
  LocalStorageService({String? Function()? identity})
    : _identity = identity ?? _firebaseIdentity,
      _boundIdentity = (identity ?? _firebaseIdentity)();

  static String? _firebaseIdentity() {
    try {
      final auth = FirebaseAuth.instance;
      final uid = auth.currentUser?.uid;
      return uid == null ? null : '${auth.app.options.projectId}/$uid';
    } catch (_) {
      return null;
    }
  }

  bool get isCurrentSession =>
      _boundIdentity != null && _identity() == _boundIdentity;
  String _key(String key) =>
      'torico_user_${Uri.encodeComponent(_boundIdentity ?? 'signed-out')}_$key';
  String get _platformKey => _key('connected_platform');
  String get _platformsKey => _key('connected_platforms');
  String get _totalSoldKey => _key('total_sold');
  String get _totalSoldDateKey => _key('total_sold_date_key');

  String _todayKey() {
    final now = DateTime.now();

    final year = now.year.toString().padLeft(4, '0');
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  Future<void> saveConnectedPlatform(String plataforma) async {
    await addConnectedPlatform(plataforma);
  }

  Future<void> addConnectedPlatform(String plataforma) async {
    if (!isCurrentSession) return;
    final prefs = await SharedPreferences.getInstance();

    final platforms = await getConnectedPlatforms();
    if (!isCurrentSession) return;

    if (!platforms.contains(plataforma)) {
      platforms.add(plataforma);
    }

    await prefs.setString(_platformKey, plataforma);
    await prefs.setString(_platformsKey, jsonEncode(platforms));
  }

  Future<void> saveConnectedPlatforms(List<String> plataformas) async {
    if (!isCurrentSession) return;
    final prefs = await SharedPreferences.getInstance();

    final platforms = plataformas
        .map((platform) => platform.trim())
        .where((platform) => platform.isNotEmpty)
        .toSet()
        .toList();

    if (platforms.isEmpty) {
      await clearConnectedPlatform();
      return;
    }

    if (!isCurrentSession) return;
    await prefs.setString(_platformKey, platforms.first);
    await prefs.setString(_platformsKey, jsonEncode(platforms));
  }

  Future<String?> getConnectedPlatform() async {
    if (!isCurrentSession) return null;
    final platforms = await getConnectedPlatforms();
    if (platforms.isEmpty) return null;

    final prefs = await SharedPreferences.getInstance();
    if (!isCurrentSession) return null;
    final lastPlatform = prefs.getString(_platformKey);

    if (lastPlatform != null && platforms.contains(lastPlatform)) {
      return lastPlatform;
    }

    return platforms.first;
  }

  Future<List<String>> getConnectedPlatforms() async {
    if (!isCurrentSession) return [];
    final prefs = await SharedPreferences.getInstance();

    if (!isCurrentSession) return [];
    final platformsJson = prefs.getString(_platformsKey);

    if (platformsJson != null && platformsJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(platformsJson);

        if (decoded is List) {
          return decoded
              .whereType<String>()
              .where((platform) => platform.trim().isNotEmpty)
              .toSet()
              .toList();
        }
      } catch (_) {
        return [];
      }
    }

    final oldPlatform = prefs.getString(_platformKey);

    if (oldPlatform != null && oldPlatform.isNotEmpty) {
      return [oldPlatform];
    }

    return [];
  }

  Future<String> getConnectedPlatformsLabel() async {
    final platforms = await getConnectedPlatforms();

    if (platforms.isEmpty) return 'Nenhuma plataforma';
    if (platforms.length == 1) return platforms.first;

    return platforms.join(' + ');
  }

  Future<bool> hasConnectedPlatform(String plataforma) async {
    final platforms = await getConnectedPlatforms();
    return platforms.contains(plataforma);
  }

  Future<void> clearConnectedPlatform() async {
    if (!isCurrentSession) return;
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_platformKey);
    await prefs.remove(_platformsKey);
  }

  Future<void> saveTotalSold(double total) async {
    if (!isCurrentSession) return;
    final prefs = await SharedPreferences.getInstance();

    if (!isCurrentSession) return;
    await prefs.setDouble(_totalSoldKey, total);
    await prefs.setString(_totalSoldDateKey, _todayKey());
  }

  Future<double> getTotalSold() async {
    if (!isCurrentSession) return 0;
    final prefs = await SharedPreferences.getInstance();

    if (!isCurrentSession) return 0;
    final savedDateKey = prefs.getString(_totalSoldDateKey);

    if (savedDateKey != _todayKey()) {
      return 0.00;
    }

    return prefs.getDouble(_totalSoldKey) ?? 0.00;
  }

  Future<void> clearTotalSold() async {
    if (!isCurrentSession) return;
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_totalSoldKey);
    await prefs.remove(_totalSoldDateKey);
  }

  Future<void> clearDeviceData() async {
    await clearConnectedPlatform();
    await clearTotalSold();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('sales_sound_enabled');
    for (final key in prefs.getKeys().toList()) {
      if (key.startsWith('torico_deletion_intake_key_') ||
          key.startsWith('torico_user_') ||
          [
            'connected_platform',
            'connected_platforms',
            'total_sold',
            'total_sold_date_key',
          ].contains(key)) {
        await prefs.remove(key);
      }
    }
  }
}
