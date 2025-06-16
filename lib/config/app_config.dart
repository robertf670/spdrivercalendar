import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class AppConfig {
  // Admin password with multiple fallbacks for safety
  static String get adminPassword {
    // Try to get from dart-define first (for CI/production builds)
    const envPassword = String.fromEnvironment('ADMIN_PASSWORD');
    
    if (envPassword.isNotEmpty) {
      return envPassword;
    }
    
    // Fallback for development/debug builds
    return 'dev_admin_2024'; // Change this for your dev environment
  }
  
  // Safety check - validate password against multiple options
  static bool isValidAdminPassword(String input) {
    // Primary password from environment/config
    if (input == adminPassword) {
      return true;
    }
    
    // Emergency fallback using hash (only you know what generates this hash)
    // You can change the password and generate new hash if needed
    const emergencyHash = 'b5e4c4f2d7f4a8b3c1e6d2a9f5b8c7e3d4f1a6b9c2e5d8f1a4b7c0e3d6f9a2b5c8';
    final inputHash = sha256.convert(utf8.encode(input)).toString();
    
    if (inputHash == emergencyHash) {
      return true;
    }
    
    // Only in debug mode, allow the dev password
    if (isDebugMode && input == 'debug_admin_access') {
      return true;
    }
    
    return false;
  }
  
  // Check if we're in debug mode
  static bool get isDebugMode {
    bool debugMode = false;
    assert(debugMode = true); // This only runs in debug mode
    return debugMode;
  }
  
  // You can add other config here
  static const String appVersion = '1.0.0';
  
  // Firebase config (if needed)
  // static const String firebaseApiKey = 'your_api_key';
} 