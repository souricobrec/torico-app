import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const String _platformKey = 'connected_platform';

  Future<void> saveConnectedPlatform(String plataforma) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_platformKey, plataforma);
  }

  Future<String?> getConnectedPlatform() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_platformKey);
  }

  Future<void> clearConnectedPlatform() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_platformKey);
  }
}
