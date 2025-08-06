import 'package:shared_preferences/shared_preferences.dart';

class AuthStorage {
  Future<String?> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('pb_auth');
  }

  Future<void> save(String data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pb_auth', data);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pb_auth');
  }
}
