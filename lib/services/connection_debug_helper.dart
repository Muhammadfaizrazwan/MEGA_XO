import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

class ConnectionDebugHelper {
  static final ConnectionDebugHelper _instance = ConnectionDebugHelper._internal();
  factory ConnectionDebugHelper() => _instance;
  ConnectionDebugHelper._internal();

  static void logConnectionInfo() {
    print("=== CONNECTION DEBUG INFO ===");
    print("Platform: ${Platform.operatingSystem}");
    print("Is Web: $kIsWeb");
    print("Is Debug Mode: $kDebugMode");
    print("Is Profile Mode: $kProfileMode");
    print("Is Release Mode: $kReleaseMode");
    
    if (!kIsWeb) {
      print("Platform Version: ${Platform.operatingSystemVersion}");
      print("Number of Processors: ${Platform.numberOfProcessors}");
    }
    
    print("=== END CONNECTION DEBUG INFO ===");
  }

  static Future<bool> testHttpConnection(String url) async {
    try {
      print("🔍 Testing HTTP connection to: $url");
      
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);
      
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      
      print("✅ HTTP connection successful. Status: ${response.statusCode}");
      client.close();
      return response.statusCode == 200;
      
    } catch (e) {
      print("❌ HTTP connection failed: $e");
      return false;
    }
  }

  static Future<void> testPocketBaseConnection(String baseUrl) async {
    print("🔍 Testing PocketBase connection...");
    
    // Test health endpoint
    final healthUrl = '$baseUrl/api/health';
    final healthOk = await testHttpConnection(healthUrl);
    
    if (healthOk) {
      print("✅ PocketBase health check passed");
    } else {
      print("❌ PocketBase health check failed");
    }

    // Test realtime endpoint
    final realtimeUrl = '$baseUrl/api/realtime';
    print("🔍 Testing realtime endpoint accessibility...");
    
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);
      
      final request = await client.getUrl(Uri.parse(realtimeUrl));
      request.headers.add('Accept', 'text/event-stream');
      request.headers.add('Cache-Control', 'no-cache');
      
      final response = await request.close();
      print("📡 Realtime endpoint response status: ${response.statusCode}");
      print("📡 Response headers: ${response.headers}");
      
      client.close();
      
    } catch (e) {
      print("❌ Realtime endpoint test failed: $e");
    }
  }

  static void logNetworkCapabilities() {
    print("=== NETWORK CAPABILITIES ===");
    
    if (!kIsWeb && Platform.isAndroid) {
      print("🤖 Android Network Info:");
      print("- Network Security Config should allow HTTPS connections");
      print("- Check if cleartext traffic is permitted for development");
    }
    
    if (!kIsWeb && Platform.isIOS) {
      print("🍎 iOS Network Info:");
      print("- App Transport Security (ATS) may restrict connections");
      print("- Check Info.plist for NSAppTransportSecurity settings");
    }
    
    print("=== END NETWORK CAPABILITIES ===");
  }
}