import 'dart:async';
import 'dart:convert'; // For jsonEncode and jsonDecode
import 'package:shared_preferences/shared_preferences.dart';

class TokenManager {
  // SharedPreferences keys
  static const String _keyCredentials = 'google_oauth_credentials';
  static const String _keyLoginStatus = 'google_login_status';
  static const String _keyUserEmail = 'google_user_email';
  static const String _keyTokenExpiry = 'google_token_expiry'; // Storing raw expiry for simplicity with AppAuth

  // In-memory state for timer (can be kept if proactive refresh is desired)
  static DateTime? _inMemoryTokenExpiration;
  static Timer? _refreshTimer;
  static const int _refreshThresholdMinutes = 5;

  // To ensure SharedPreferences is initialized
  static SharedPreferences? _prefs;

  static Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
    // Load in-memory expiration for timer logic if needed
    final expiryString = _prefs?.getString(_keyTokenExpiry);
    if (expiryString != null) {
      _inMemoryTokenExpiration = DateTime.tryParse(expiryString);
      if (_inMemoryTokenExpiration != null) {

        _scheduleRefresh();
      }
    }

  }

  static Future<void> saveLoginStatus(bool isLoggedIn) async {
    await _prefs?.setBool(_keyLoginStatus, isLoggedIn);

  }

  static Future<bool> getLoginStatus() async {
    return _prefs?.getBool(_keyLoginStatus) ?? false;
  }

  static Future<void> saveCredentials(Map<String, dynamic> credentialsMap, String email, DateTime? expiryDateTime) async {
    final String credentialsJson = jsonEncode(credentialsMap);
    await _prefs?.setString(_keyCredentials, credentialsJson);

    await saveUserEmail(email); // Save email alongside

    if (expiryDateTime != null) {
      _inMemoryTokenExpiration = expiryDateTime;
      await saveTokenExpiry(expiryDateTime.toIso8601String()); // also save to prefs
      _scheduleRefresh();
    } else if (credentialsMap.containsKey('accessTokenExpiry') && credentialsMap['accessTokenExpiry'] is String) {
      // Fallback if direct expiryDateTime is not provided but is in map
      _inMemoryTokenExpiration = DateTime.tryParse(credentialsMap['accessTokenExpiry'] as String);
      if (_inMemoryTokenExpiration != null) {
        await saveTokenExpiry(_inMemoryTokenExpiration!.toIso8601String());
        _scheduleRefresh();
      }
    }
  }

  static Future<Map<String, dynamic>?> getCredentials() async {
    final String? credentialsJson = _prefs?.getString(_keyCredentials);
    if (credentialsJson != null && credentialsJson.isNotEmpty) {
      try {
        return jsonDecode(credentialsJson) as Map<String, dynamic>;
      } catch (e) {

        return null;
      }
    }
    return null;
  }

  static Future<String?> getRefreshToken() async {
    final creds = await getCredentials();
    return creds?['refreshToken'] as String?;
  }

  static Future<String?> getIdToken() async {
    final creds = await getCredentials();
    return creds?['idToken'] as String?;
  }

  static Future<void> saveUserEmail(String email) async {
    await _prefs?.setString(_keyUserEmail, email);

  }

  static Future<String?> getUserEmail() async {
    return _prefs?.getString(_keyUserEmail);
  }

  static Future<void> clearUserEmail() async {
    await _prefs?.remove(_keyUserEmail);
  }

  static Future<void> saveTokenExpiry(String expiryIsoString) async {
    // This method is primarily called by GoogleCalendarService after successful token acquisition/refresh
    // It also updates the in-memory copy for the timer.
    await _prefs?.setString(_keyTokenExpiry, expiryIsoString);
    _inMemoryTokenExpiration = DateTime.tryParse(expiryIsoString);

    if (_inMemoryTokenExpiration != null) {
      _scheduleRefresh();
    }
  }

  static Future<String?> getTokenExpiry() async {
    // Provides the raw string, GoogleCalendarService can parse it.
    return _prefs?.getString(_keyTokenExpiry);
  }
  
  static Future<void> clearTokenExpiry() async {
    await _prefs?.remove(_keyTokenExpiry);
    _inMemoryTokenExpiration = null;
    _refreshTimer?.cancel();
  }

  static Future<void> clearAll() async {
    await _prefs?.remove(_keyCredentials);
    await _prefs?.setBool(_keyLoginStatus, false); // Explicitly set to false
    await _prefs?.remove(_keyUserEmail);
    await _prefs?.remove(_keyTokenExpiry);
    _inMemoryTokenExpiration = null;
    _refreshTimer?.cancel();

  }

  // Timer logic (kept from original)
  static bool needsRefresh() {
    if (_inMemoryTokenExpiration == null) return true; // If no expiry, assume refresh needed or auth first
    return DateTime.now().add(Duration(minutes: _refreshThresholdMinutes)).isAfter(_inMemoryTokenExpiration!);
  }

  static void _scheduleRefresh() {
    _refreshTimer?.cancel();
    if (_inMemoryTokenExpiration == null) return;

    final timeUntilRefresh = _inMemoryTokenExpiration!.difference(DateTime.now()) - Duration(minutes: _refreshThresholdMinutes);

    if (timeUntilRefresh.isNegative) {

      // Potentially trigger a refresh callback if GoogleCalendarService provides one
      // For now, GoogleCalendarService checks needsRefresh() or handles expired tokens.
      return;
    }


    _refreshTimer = Timer(timeUntilRefresh, () {

      // This timer's role is to ensure proactive refresh.
      // The actual refresh is initiated by GoogleCalendarService when it checks token validity.
      // Or, a callback mechanism could be added here if needed.
    });
  }

  static void dispose() { // Call when app is shutting down or service is no longer needed
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _inMemoryTokenExpiration = null;

  }
} 
