import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const String _platformKey = 'connected_platform';
  static const String _platformsKey = 'connected_platforms';
  static const String _totalSoldKey = 'total_sold';
  static const String _totalSoldDateKey = 'total_sold_date_key';

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
    final prefs = await SharedPreferences.getInstance();

    final platforms = await getConnectedPlatforms();

    if (!platforms.contains(plataforma)) {
      platforms.add(plataforma);
    }

    await prefs.setString(_platformKey, plataforma);
    await prefs.setString(_platformsKey, jsonEncode(platforms));
  }

  Future<String?> getConnectedPlatform() async {
    final prefs = await SharedPreferences.getInstance();

    final lastPlatform = prefs.getString(_platformKey);
    if (lastPlatform != null && lastPlatform.isNotEmpty) {
      return lastPlatform;
    }

    final platforms = await getConnectedPlatforms();
    if (platforms.isEmpty) return null;

    return platforms.first;
  }

  Future<List<String>> getConnectedPlatforms() async {
    final prefs = await SharedPreferences.getInstance();

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
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_platformKey);
    await prefs.remove(_platformsKey);
  }

  Future<void> saveTotalSold(double total) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setDouble(_totalSoldKey, total);
    await prefs.setString(_totalSoldDateKey, _todayKey());
  }

  Future<double> getTotalSold() async {
    final prefs = await SharedPreferences.getInstance();

    final savedDateKey = prefs.getString(_totalSoldDateKey);

    if (savedDateKey != _todayKey()) {
      return 0.00;
    }

    return prefs.getDouble(_totalSoldKey) ?? 0.00;
  }

  Future<void> clearTotalSold() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_totalSoldKey);
    await prefs.remove(_totalSoldDateKey);
  }
}
