import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'connection_debug_helper.dart';

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
      if (kDebugMode) {
        ConnectionDebugHelper.logConnectionInfo();
        ConnectionDebugHelper.logNetworkCapabilities();
        await ConnectionDebugHelper.testPocketBaseConnection(pb.baseUrl);
      }

      await _loadAuth();
      _configureMobileSettings();

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

  void _configureMobileSettings() {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      // Configure mobile-specific settings for better SSE connections
      pb.httpClientFactory = () {
        final client = HttpClient();
        client.connectionTimeout = const Duration(seconds: 30);
        client.idleTimeout = const Duration(seconds: 90);
        // Disable HTTP/2 for better mobile compatibility
        client.autoUncompress = true;
        return client;
      };
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

  /// Enhanced subscribe method with retry logic for mobile
  Future<void> subscribeWithRetry(
    String collection,
    String recordId,
    Function(RealtimeSubscriptionEvent) callback, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
  }) async {
    int retryCount = 0;
    
    while (retryCount < maxRetries) {
      try {
        await pb.collection(collection).subscribe(recordId, callback);
        print("✅ SSE subscription established successfully for $collection/$recordId");
        return;
      } catch (e) {
        retryCount++;
        print("❌ SSE subscription failed (attempt $retryCount/$maxRetries): $e");
        
        if (retryCount < maxRetries) {
          print("⏳ Retrying in ${retryDelay.inSeconds} seconds...");
          await Future.delayed(retryDelay);
          // Exponential backoff
          retryDelay = Duration(seconds: retryDelay.inSeconds * 2);
        } else {
          print("🚨 All SSE connection attempts failed. Using polling fallback.");
          throw Exception("Failed to establish SSE connection after $maxRetries attempts: $e");
        }
      }
    }
  }

  /// Polling fallback for when SSE fails
  StreamController<Map<String, dynamic>>? _pollingController;
  Timer? _pollingTimer;

  Stream<Map<String, dynamic>> subscribeWithPollingFallback(
    String collection,
    String recordId, {
    Duration pollingInterval = const Duration(seconds: 2),
  }) {
    _pollingController?.close();
    _pollingTimer?.cancel();
    
    _pollingController = StreamController<Map<String, dynamic>>.broadcast();
    
    // Try SSE first
    subscribeWithRetry(collection, recordId, (e) {
      if (e.action == 'update' && e.record != null) {
        _pollingController?.add(e.record!.data);
      }
    }).catchError((error) {
      // Fallback to polling
      print("🔄 Falling back to polling for $collection/$recordId");
      _startPolling(collection, recordId, pollingInterval);
    });
    
    return _pollingController!.stream;
  }

  void _startPolling(String collection, String recordId, Duration interval) {
    _pollingTimer = Timer.periodic(interval, (timer) async {
      try {
        final record = await pb.collection(collection).getOne(recordId);
        _pollingController?.add(record.data);
      } catch (e) {
        print("Polling error: $e");
      }
    });
  }

  void stopPolling() {
    _pollingController?.close();
    _pollingTimer?.cancel();
    _pollingController = null;
    _pollingTimer = null;
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
}
