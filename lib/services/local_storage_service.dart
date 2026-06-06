import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const String _platformKey = 'connected_platform';
  static const String _totalSoldKey = 'total_sold';

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

  Future<void> saveTotalSold(double total) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_totalSoldKey, total);
  }

  Future<double> getTotalSold() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_totalSoldKey) ?? 0.00;
  }

  Future<void> clearTotalSold() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_totalSoldKey);
  }
}
