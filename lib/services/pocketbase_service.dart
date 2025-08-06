import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PocketBaseService {
  static final PocketBaseService _instance = PocketBaseService._internal();
  factory PocketBaseService() => _instance;
  PocketBaseService._internal();

  final pb = PocketBase('https://megaxo-dev.lightcodedigital.cloud');

  bool get isLoggedIn => pb.authStore.isValid;
  // ignore: deprecated_member_use
  String? get userId => pb.authStore.model?.id;
  // ignore: deprecated_member_use
  String? get username => pb.authStore.model?.data['username'];

  Future<void> init() async {
    try {
      await _loadAuth();

      pb.authStore.onChange.listen((AuthStoreEvent event) {
        if (event.token.isEmpty) {
          _clearAuth();
        } else {
          _saveAuth();
        }
      });

      await _testConnection();
    } catch (e) {
      print("Error initializing PocketBase service: $e");
    }
  }

  Future<void> _testConnection() async {
    try {
      await pb.health.check();
      print("PocketBase connection successful");
    } catch (e) {
      throw Exception("Tidak dapat terhubung ke server PocketBase.");
    }
  }

  Future<void> _loadAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('pb_auth');

      if (stored != null && stored.isNotEmpty) {
        final data = jsonDecode(stored);
        if (data['token'] != null && data['model'] != null) {
          pb.authStore.save(
            data['token'],
            RecordModel.fromJson(data['model']),
          );
        }
      }
    } catch (e) {
      _clearAuth();
    }
  }

  Future<void> _saveAuth() async {
    if (!pb.authStore.isValid) return;

    try {
      final data = jsonEncode({
        'token': pb.authStore.token,
        'model': pb.authStore.model?.toJson(),
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pb_auth', data);
    } catch (e) {
      print("Gagal simpan auth: $e");
    }
  }

  Future<void> _clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pb_auth');
  }

  Future<void> login(String email, String password) async {
    try {
      final record = await pb
          .collection('users')
          .authWithPassword(email, password);
      await _saveAuth();
    } catch (e) {
      String errorMessage = "Login gagal";
      final errorStr = e.toString().toLowerCase();

      if (errorStr.contains('invalid credentials') ||
          errorStr.contains('failed to authenticate')) {
        errorMessage = "Email atau password salah";
      } else if (errorStr.contains('network') ||
          errorStr.contains('connection')) {
        errorMessage = "Koneksi bermasalah";
      } else if (errorStr.contains('timeout')) {
        errorMessage = "Timeout koneksi";
      }

      throw Exception(errorMessage);
    }
  }

  Future<void> register(String username, String email, String password) async {
    try {
      await pb.collection('users').create(
        body: {
          "username": username,
          "email": email,
          "password": password,
          "passwordConfirm": password,
        },
      );

      await login(email, password);
    } catch (e) {
      String errorMessage = "Registrasi gagal";
      final errorStr = e.toString().toLowerCase();

      if (errorStr.contains('unique constraint') ||
          errorStr.contains('already exists')) {
        if (errorStr.contains('email')) {
          errorMessage = "Email sudah digunakan";
        } else if (errorStr.contains('username')) {
          errorMessage = "Username sudah digunakan";
        }
      } else if (errorStr.contains('validation')) {
        errorMessage = "Data tidak valid";
      }

      throw Exception(errorMessage);
    }
  }

  void logout() {
    pb.authStore.clear();
    _clearAuth();
  }

  Future<bool> checkAuthStatus() async {
    if (!isLoggedIn) return false;

    try {
      await pb.collection('users').authRefresh();
      await _saveAuth();
      return true;
    } catch (_) {
      logout();
      return false;
    }
  }

  String getCurrentUserInfo() {
    if (!isLoggedIn) return "Not logged in";
    return "User: ${username ?? 'Unknown'} (ID: ${userId ?? 'Unknown'})";
  }

  getCurrentUserId() {}
}
