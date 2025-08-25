import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class PocketBaseService {
  static final PocketBaseService _instance = PocketBaseService._internal();
  factory PocketBaseService() => _instance;
  PocketBaseService._internal();

  SharedPreferences? _prefs;
  PocketBase? _pb;

  // Lazy initialization of SharedPreferences
  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // Lazy initialization of PocketBase
  Future<PocketBase> get pb async {
    if (_pb != null) return _pb!;

    final prefsInstance = await prefs;

    final store = AsyncAuthStore(
      save: (String data) async => prefsInstance.setString('pb_auth', data),
      initial: prefsInstance.getString('pb_auth'),
    );

    _pb = PocketBase(
      'https://megaxo-dev.lightcodedigital.cloud',
      authStore: store,
    );
    return _pb!;
  }

  bool get isLoggedIn => _pb?.authStore.isValid ?? false;
  // ignore: deprecated_member_use
  String? get userId => _pb?.authStore.model?.id;
  // ignore: deprecated_member_use
  String? get username => _pb?.authStore.model?.data['username'];
  // ignore: deprecated_member_use
  String? get email => _pb?.authStore.model?.data['email'];

  Future<void> init() async {
    try {
      // Initialize PocketBase
      final pocketbase = await pb;

      await _loadAuth();

      pocketbase.authStore.onChange.listen((AuthStoreEvent event) {
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
      final pocketbase = await pb;
      await pocketbase.health.check();
      print("PocketBase connection successful");
    } catch (e) {
      throw Exception("Tidak dapat terhubung ke server PocketBase.");
    }
  }

  Future<void> _loadAuth() async {
    try {
      final prefsInstance = await prefs;
      final stored = prefsInstance.getString('pb_auth');

      if (stored != null && stored.isNotEmpty) {
        final data = jsonDecode(stored);
        if (data['token'] != null && data['model'] != null) {
          final pocketbase = await pb;
          pocketbase.authStore.save(
            data['token'],
            RecordModel.fromJson(data['model']),
          );

          // Also update SharedPreferences login state
          await prefsInstance.setBool('isLoggedIn', true);
          await prefsInstance.setString(
            'userEmail',
            data['model']['email'] ?? '',
          );
          await prefsInstance.setString(
            'userName',
            data['model']['name'] ?? data['model']['username'] ?? '',
          );
          await prefsInstance.setString('userId', data['model']['id'] ?? '');
        }
      }
    } catch (e) {
      print("Error loading auth: $e");
      _clearAuth();
    }
  }

  Future<void> _saveAuth() async {
    final pocketbase = await pb;
    if (!pocketbase.authStore.isValid) return;

    try {
      final data = jsonEncode({
        'token': pocketbase.authStore.token,
        // ignore: deprecated_member_use
        'model': pocketbase.authStore.model?.toJson(),
      });

      final prefsInstance = await prefs;
      await prefsInstance.setString('pb_auth', data);

      // Also update SharedPreferences login state
      // ignore: deprecated_member_use
      final model = pocketbase.authStore.model;
      if (model != null) {
        await prefsInstance.setBool('isLoggedIn', true);
        await prefsInstance.setString('userEmail', model.data['email'] ?? '');
        await prefsInstance.setString(
          'userName',
          model.data['name'] ?? model.data['username'] ?? '',
        );
        await prefsInstance.setString('userId', model.id);
      }
    } catch (e) {
      print("Gagal simpan auth: $e");
    }
  }

  Future<void> _clearAuth() async {
    try {
      final prefsInstance = await prefs;
      await prefsInstance.remove('pb_auth');
      await prefsInstance.setBool('isLoggedIn', false);
      await prefsInstance.remove('userEmail');
      await prefsInstance.remove('userName');
      await prefsInstance.remove('userId');
    } catch (e) {
      print("Error clearing auth: $e");
    }
  }

  Future<Map<String, dynamic>> loginWithGoogle() async {
    try {
      final pocketbase = await pb;
      final authData = await pocketbase.collection('users').authWithOAuth2(
        'google',
        (url) async {
          if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
            throw Exception('Could not launch $url');
          }
        },
      );

      // Save the auth data
      await _saveAuth();

      // Update user data after login
      await pocketbase
          .collection('users')
          .update(authData.record.id, body: {'emailVisibility': true});

      // Return user data
      return {
        'email': authData.record.data['email'] ?? '',
        'name':
            authData.record.data['name'] ??
            authData.record.data['username'] ??
            '',
        'id': authData.record.id,
      };
    } catch (e) {
      String errorMessage = "Google login failed";
      final errorStr = e.toString().toLowerCase();
      print(errorStr);

      if (errorStr.contains('cancelled')) {
        errorMessage = "Login dibatalkan";
      } else if (errorStr.contains('network') ||
          errorStr.contains('connection')) {
        errorMessage = "Koneksi bermasalah";
      } else if (errorStr.contains('timeout')) {
        errorMessage = "Timeout koneksi";
      }

      throw Exception(errorMessage);
    }
  }

  Future<void> logout() async {
    try {
      final pocketbase = await pb;
      pocketbase.authStore.clear();
      await _clearAuth();
    } catch (e) {
      print("Error during logout: $e");
      // Force clear even if there's an error
      await _clearAuth();
    }
  }

  Future<bool> checkAuthStatus() async {
    try {
      final pocketbase = await pb;
      if (!pocketbase.authStore.isValid) return false;

      await pocketbase.collection('users').authRefresh();
      await _saveAuth();
      return true;
    } catch (e) {
      print("Auth refresh failed: $e");
      await logout();
      return false;
    }
  }

  // Check if user is logged in from SharedPreferences (faster check)
  Future<bool> isUserLoggedIn() async {
    try {
      final prefsInstance = await prefs;
      final isLoggedIn = prefsInstance.getBool('isLoggedIn') ?? false;
      final userEmail = prefsInstance.getString('userEmail');

      // Double check with PocketBase auth if SharedPreferences says logged in
      if (isLoggedIn && userEmail != null) {
        return await checkAuthStatus();
      }

      return false;
    } catch (e) {
      print("Error checking login status: $e");
      return false;
    }
  }

  // Get user info from SharedPreferences (faster)
  Future<Map<String, String?>> getUserInfo() async {
    try {
      final prefsInstance = await prefs;
      return {
        'email': prefsInstance.getString('userEmail'),
        'name': prefsInstance.getString('userName'),
        'id': prefsInstance.getString('userId'),
      };
    } catch (e) {
      print("Error getting user info: $e");
      return {'email': null, 'name': null, 'id': null};
    }
  }

  String getCurrentUserInfo() {
    if (!isLoggedIn) return "Not logged in";
    return "User: ${username ?? 'Unknown'} (Email: ${email ?? 'Unknown'}, ID: ${userId ?? 'Unknown'})";
  }

  String? getCurrentUserId() {
    return userId;
  }

  Future<void> register(String email, String password, String username) async {
    try {
      final body = <String, dynamic>{
        "email": email,
        "password": password,
        "passwordConfirm": password,
        "username": username,
        "emailVisibility": true,
      };

      final pocketbase = await pb;
      final record = await pocketbase.collection('users').create(body: body);

      // Auto login after registration
      await pocketbase.collection('users').authWithPassword(email, password);
      await _saveAuth();
    } catch (e) {
      String errorMessage = "Registration failed";
      final errorStr = e.toString().toLowerCase();

      if (errorStr.contains('email')) {
        errorMessage = "Email sudah digunakan atau tidak valid";
      } else if (errorStr.contains('password')) {
        errorMessage = "Password terlalu lemah";
      } else if (errorStr.contains('username')) {
        errorMessage = "Username sudah digunakan";
      }

      throw Exception(errorMessage);
    }
  }
}
