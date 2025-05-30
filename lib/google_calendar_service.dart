import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:credential_manager/credential_manager.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'services/token_manager.dart';
import 'package:flutter/foundation.dart';

class GoogleCalendarService {
  // Configuration
  static const String _webClientId = '1051329330296-l7so8o8bfdm4h1g1hj9ql30dmuq1514e.apps.googleusercontent.com';
  static const List<String> _scopes = [
    'email',
    'https://www.googleapis.com/auth/calendar',
  ];

  // Instance variables
  static final CredentialManager _credentialManager = CredentialManager();
  static http.Client? _currentHttpClient;
  static auth.AccessCredentials? _currentCredentials;
  static String? _currentUserEmail;
  static bool _isInitialized = false;

  /// Initialize the Google Calendar service
  static Future<void> initialize() async {
    try {
      print('[Debug Initialize] CredentialManager initializing...');
      _isInitialized = true;
      
      // Check if user has saved credentials
      if (await getLoginStatus()) {
        print('[Debug Initialize] User has saved login status. Attempting silent sign-in...');
        final success = await _attemptSilentSignIn();
        if (success != null) {
          print('[Debug Initialize] Silent sign-in successful');
        } else {
          print('[Debug Initialize] Silent sign-in failed');
        }
      } else {
        print('[Debug Initialize] No saved login status found');
      }
    } catch (e) {
      print('Failed to initialize CredentialManager: $e');
    }
  }
  
  /// Check if user is currently signed in
  static Future<bool> isSignedIn() async {
    try {
      // Check if we have valid credentials and they're not expired
      if (_currentCredentials == null) {
        return false;
      }
      
      // Check token expiration
      if (TokenManager.needsRefresh()) {
        print('Credentials expired, attempting refresh...');
        return await _refreshCredentials();
      }
      
      return true;
    } catch (e) {
      print('Error checking sign-in status: $e');
      return false;
    }
  }
  
  /// Save login status to SharedPreferences
  static Future<void> saveLoginStatus(bool status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasCompletedGoogleLogin', status);
      if (status && _currentUserEmail != null) {
        await prefs.setString('lastSignedInEmail', _currentUserEmail!);
      }
      print('Saved Google login status: $status');
    } catch (error) {
      print('Error saving login status: $error');
    }
  }
  
  /// Get login status from shared preferences
  static Future<bool> getLoginStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final status = prefs.getBool('hasCompletedGoogleLogin') ?? false;
      print('Retrieved Google login status: $status');
      return status;
    } catch (error) {
      print('Error getting login status: $error');
      return false;
    }
  }
  
  /// Clear all login data
  static Future<void> clearLoginData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('hasCompletedGoogleLogin');
      await prefs.remove('lastSignedInEmail');
      await prefs.remove('credentialManagerToken');
      await prefs.remove('refreshToken');
      
      // Clear current session
      _currentCredentials = null;
      _currentUserEmail = null;
      _currentHttpClient?.close();
      _currentHttpClient = null;
      
      print('Cleared all login data');
    } catch (error) {
      print('Error clearing login data: $error');
    }
  }
  
  /// Get the current signed-in user email
  static Future<String?> getCurrentUserEmail() async {
    try {
      if (_currentUserEmail != null) {
        return _currentUserEmail;
      }
      
      // Try to get from saved preferences
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('lastSignedInEmail');
      if (savedEmail != null) {
        _currentUserEmail = savedEmail;
        return savedEmail;
      }
      
      return null;
    } catch (error) {
      print('Error getting current user email: $error');
      return null;
    }
  }

  /// Sign in with Google using Credential Manager
  static Future<String?> signInWithGoogle() async {
    try {
      print('[DEBUG] Starting Credential Manager Google Sign-In process...');
      
      // First try silent sign-in for returning users
      print('[DEBUG] Attempting silent sign-in first...');
      final silentResult = await _attemptSilentSignIn();
      if (silentResult != null) {
        return silentResult;
      }
      
      print('[DEBUG] Silent sign-in failed, trying interactive sign-in...');
      
      // Initialize credential manager if needed
      if (_credentialManager.isSupportedPlatform) {
        await _credentialManager.init(
          preferImmediatelyAvailableCredentials: true,
          googleClientId: _webClientId,
        );
      }
      
      // For interactive sign-in, use the saveGoogleCredential method
      final result = await _credentialManager.saveGoogleCredential();
      
      if (result != null) {
        print('[DEBUG] Interactive sign-in successful');
        print('[DEBUG] ID Token received (first 20 chars): ${result.idToken?.substring(0, 20)}...');
        
        // Extract user info from ID token
        final userInfo = _parseIdToken(result.idToken!);
        print('[DEBUG] User email: ${userInfo['email']}');
        print('[DEBUG] User display name: ${userInfo['name']}');
        
        // Store the user email
        _currentUserEmail = userInfo['email'];
        
        // Now we need to exchange this ID token for access tokens using OAuth2
        final credentials = await _exchangeIdTokenForAccessToken(result.idToken!);
        
        if (credentials != null) {
          _currentCredentials = credentials;
          await _saveCredentials(credentials);
          
          // Update token expiration tracking
          _updateTokenExpiration(result.idToken!);
          
          // Save login state
          await saveLoginStatus(true);
          
          print('[DEBUG] Sign-in completed successfully');
          return userInfo['email'];
        } else {
          print('[DEBUG] Using simplified credentials (ID token as access token)');
          
          // Fallback: Use ID token as access token (limited functionality)
          final fallbackCredentials = _createFallbackCredentials(result.idToken!);
          _currentCredentials = fallbackCredentials;
          await _saveCredentials(fallbackCredentials);
          
          // Update token expiration tracking
          _updateTokenExpiration(result.idToken!);
          
          // Save login state
          await saveLoginStatus(true);
          
          print('[DEBUG] Sign-in completed successfully');
          return userInfo['email'];
        }
      }
      
      print('[ERROR] Failed to get credential from Credential Manager');
      return null;
    } catch (e) {
      print('[ERROR] Sign-in failed: $e');
      return null;
    }
  }
  
  /// Exchange ID token for proper access tokens using Google OAuth2
  static Future<auth.AccessCredentials?> _exchangeIdTokenForAccessToken(String idToken) async {
    try {
      print('[DEBUG] Exchanging ID token for access tokens...');
      
      // Method 1: Try OAuth2 token endpoint with authorization code grant
      final credentials = await _tryAuthorizationCodeExchange(idToken);
      if (credentials != null) {
        return credentials;
      }
      
      // Method 2: Try using Google OAuth2 service account flow
      final serviceCredentials = await _tryServiceAccountFlow(idToken);
      if (serviceCredentials != null) {
        return serviceCredentials;
      }
      
      print('[DEBUG] Token exchange failed, will use fallback approach');
      return null;
    } catch (e) {
      print('[DEBUG] Token exchange error: $e');
      return null;
    }
  }
  
  /// Try authorization code exchange for access tokens
  static Future<auth.AccessCredentials?> _tryAuthorizationCodeExchange(String idToken) async {
    try {
      final client = http.Client();
      
      try {
        // Extract authorization code from ID token if available
        final userInfo = _parseIdToken(idToken);
        
        // Use OAuth2 device flow approach
        final response = await client.post(
          Uri.parse('https://oauth2.googleapis.com/token'),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: {
            'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
            'assertion': idToken,
            'scope': _scopes.join(' '),
          },
        );
        
        print('[DEBUG] Token exchange response: ${response.statusCode}');
        
        if (response.statusCode == 200) {
          final tokenData = jsonDecode(response.body);
          
          final accessToken = auth.AccessToken(
            'Bearer',
            tokenData['access_token'],
            DateTime.now().toUtc().add(Duration(seconds: tokenData['expires_in'] ?? 3600)),
          );
          
          print('[DEBUG] Successfully obtained access token for Calendar API');
          
          return auth.AccessCredentials(
            accessToken,
            tokenData['refresh_token'],
            _scopes,
          );
        } else {
          print('[DEBUG] Token exchange failed: ${response.statusCode} - ${response.body}');
          return null;
        }
      } finally {
        client.close();
      }
    } catch (e) {
      print('[DEBUG] Authorization code exchange error: $e');
      return null;
    }
  }
  
  /// Try service account flow for access tokens
  static Future<auth.AccessCredentials?> _tryServiceAccountFlow(String idToken) async {
    try {
      // This would require service account credentials
      // For now, we'll skip this and use fallback
      print('[DEBUG] Service account flow not implemented yet');
      return null;
    } catch (e) {
      print('[DEBUG] Service account flow error: $e');
      return null;
    }
  }
  
  /// Create fallback credentials using ID token (limited functionality)
  static auth.AccessCredentials _createFallbackCredentials(String idToken) {
    try {
      // Parse token to get expiration
      final userInfo = _parseIdToken(idToken);
      
      // Calculate proper expiration time from the token
      DateTime expiration;
      if (userInfo['exp'] != null && userInfo['exp'] is int) {
        expiration = DateTime.fromMillisecondsSinceEpoch(userInfo['exp'] * 1000);
      } else {
        expiration = DateTime.now().toUtc().add(const Duration(hours: 1));
      }
      
      // Create access token using the ID token
      final accessToken = auth.AccessToken(
        'Bearer',
        idToken,
        expiration,
      );
      
      print('[DEBUG] Created fallback credentials with expiration: $expiration');
      
      return auth.AccessCredentials(
        accessToken,
        null, // No refresh token available with this approach
        _scopes,
      );
    } catch (e) {
      print('[DEBUG] Fallback credentials error: $e');
      
      // Last resort: basic credentials with 1 hour expiration
      final accessToken = auth.AccessToken(
        'Bearer',
        idToken,
        DateTime.now().toUtc().add(const Duration(hours: 1)),
      );
      
      return auth.AccessCredentials(
        accessToken,
        null,
        _scopes,
      );
    }
  }

  /// Sign out the current user
  static Future<void> signOut() async {
    try {
      await clearLoginData();
      print('User signed out successfully');
    } catch (error) {
      print('Error signing out: $error');
    }
  }

  /// Get the Calendar API client
  static Future<calendar.CalendarApi?> getCalendarApi() async {
    try {
      if (!await isSignedIn()) {
        print('User is not signed in - trying to sign in silently');
        final success = await _attemptSilentSignIn();
        if (success == null) {
          print('Silent sign in failed');
          return null;
        }
      }

      // Check if token needs refresh
      if (TokenManager.needsRefresh()) {
        print('Token needs refresh, attempting refresh...');
        final refreshed = await _refreshCredentials();
        if (!refreshed) {
          print('Token refresh failed');
          return null;
        }
      }

      // Get the authenticated HTTP client
      final httpClient = await getAuthenticatedClient();
      
      if (httpClient == null) {
        print('Failed to get authenticated client in getCalendarApi.');
        return null;
      }
      
      print('[Debug getCalendarApi] Successfully got httpClient.');
      return calendar.CalendarApi(httpClient);
    } catch (error) {
      print('Error getting Calendar API: $error');
      return null;
    }
  }

  /// Add event to Google Calendar
  static Future<bool> addEvent({
    required String summary,
    required String description,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final calendarApi = await getCalendarApi();
      
      if (calendarApi == null) {
        print('Failed to get Calendar API client');
        return false;
      }

      // Create start and end time properly
      final eventStartTime = calendar.EventDateTime()..dateTime = startTime..timeZone = 'UTC';
      final eventEndTime = calendar.EventDateTime()..dateTime = endTime..timeZone = 'UTC';
      
      // Create the event with proper assignment
      final event = calendar.Event();
      event.summary = summary;
      event.description = description;
      event.start = eventStartTime;
      event.end = eventEndTime;

      // Insert event to primary calendar
      await calendarApi.events.insert(event, 'primary');
      print('Event added successfully: $summary');
      return true;
    } catch (e) {
      print('Error adding event: $e');
      return false;
    }
  }

  /// Get events from Google Calendar
  static Future<List<calendar.Event>> getEvents() async {
    try {
      final calendarApi = await getCalendarApi();
      
      if (calendarApi == null) {
        return [];
      }

      // Get events from primary calendar
      final eventList = await calendarApi.events.list(
        'primary',
        timeMin: DateTime.now().subtract(const Duration(days: 7)),
        timeMax: DateTime.now().add(const Duration(days: 30)),
        singleEvents: true,
        orderBy: 'startTime',
      );

      return eventList.items ?? [];
    } catch (e) {
      print('Error getting events: $e');
      return [];
    }
  }
  
  /// Check if calendar access is still valid
  static Future<bool> checkCalendarAccess(http.Client? httpClientFromCaller) async {
    print('[Debug CheckCalendarAccess] Entered.');
    try {
      if (httpClientFromCaller == null) {
        print('[Debug CheckCalendarAccess] httpClientFromCaller is null. Getting new client...');
        final newClient = await getAuthenticatedClient();
        if (newClient == null) {
          print('[Debug CheckCalendarAccess] Failed to get authenticated client.');
          return false;
        }
        httpClientFromCaller = newClient;
      }

      print('[Debug CheckCalendarAccess] Attempting API call...');
      final calendarApi = calendar.CalendarApi(httpClientFromCaller);
      await calendarApi.calendarList.list(maxResults: 1);
      print('[Debug CheckCalendarAccess] Calendar access verified successfully.');
      return true;
    } catch (error) {
      print('[Debug CheckCalendarAccess] Error: $error');
      return false;
    }
  }

  /// Get an authenticated HTTP client
  static Future<http.Client?> getAuthenticatedClient() async {
    try {
      if (!await isSignedIn()) {
        print('[Debug getAuthenticatedClient] Not signed in.');
        return null;
      }

      // Check if we need to refresh credentials
      if (TokenManager.needsRefresh()) {
        print('[Debug getAuthenticatedClient] Token needs refresh...');
        final refreshed = await _refreshCredentials();
        if (!refreshed) {
          print('[Debug getAuthenticatedClient] Token refresh failed.');
          return null;
        }
      }

      if (_currentCredentials == null) {
        print('[Debug getAuthenticatedClient] No current credentials available.');
        return null;
      }

      // Create or reuse authenticated client
      if (_currentHttpClient == null) {
        _currentHttpClient = auth.authenticatedClient(
          http.Client(),
          _currentCredentials!,
        );
        print('[Debug getAuthenticatedClient] Created new authenticated client.');
      } else {
        print('[Debug getAuthenticatedClient] Reusing existing authenticated client.');
      }
      
      return _currentHttpClient;
    } catch (e) {
      print('Error getting authenticated client: $e');
      return null;
    }
  }

  // Private helper methods

  /// Attempt silent sign-in using saved credentials
  static Future<String?> _attemptSilentSignIn() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      // Try to get saved credentials first
      final savedCredentials = await _getSavedCredentials();
      if (savedCredentials != null && !TokenManager.needsRefresh()) {
        _currentCredentials = savedCredentials;
        print('[Debug _attemptSilentSignIn] Using saved credentials.');
        return _currentUserEmail;
      }

      print('[Debug _attemptSilentSignIn] No valid saved credentials found.');
      return null;
    } catch (e) {
      print('[Debug _attemptSilentSignIn] Error: $e');
      return null;
    }
  }

  /// Refresh credentials when they expire
  static Future<bool> _refreshCredentials() async {
    try {
      if (_currentCredentials?.refreshToken == null) {
        print('[Debug _refreshCredentials] No refresh token available.');
        return false;
      }

      print('[Debug _refreshCredentials] Attempting to refresh credentials...');
      final newCredentials = await auth.refreshCredentials(
        auth.ClientId(_webClientId),
        _currentCredentials!,
        http.Client(),
      );

      _currentCredentials = newCredentials;
      await _saveCredentials(newCredentials);
      
      // Update token expiration based on new access token
      if (newCredentials.accessToken.data.isNotEmpty) {
        final tokenInfo = _parseAccessToken(newCredentials.accessToken.data);
        if (tokenInfo['exp'] != null) {
          final expirationDateTime = DateTime.fromMillisecondsSinceEpoch(tokenInfo['exp'] * 1000);
          TokenManager.setTokenExpiration(expirationDateTime);
        }
      }
      
      // Close old client and create new one
      _currentHttpClient?.close();
      _currentHttpClient = null;
      
      print('[Debug _refreshCredentials] Credentials refreshed successfully.');
      return true;
    } catch (e) {
      print('[Debug _refreshCredentials] Error: $e');
      return false;
    }
  }

  /// Parse ID token to extract user information
  static Map<String, dynamic> _parseIdToken(String idToken) {
    try {
      final parts = idToken.split('.');
      if (parts.length != 3) {
        throw Exception('Invalid ID token format');
      }
      
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      return jsonDecode(decoded);
    } catch (e) {
      print('Error parsing ID token: $e');
      return {};
    }
  }

  /// Parse access token to extract information
  static Map<String, dynamic> _parseAccessToken(String accessToken) {
    try {
      final parts = accessToken.split('.');
      if (parts.length != 3) {
        return {}; // Not a JWT, return empty map
      }
      
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      return jsonDecode(decoded);
    } catch (e) {
      print('Error parsing access token: $e');
      return {};
    }
  }

  /// Generate a secure nonce for authentication
  static String _generateNonce() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    final nonce = base64Url.encode(values);
    
    // Hash the nonce with SHA-256
    final bytes = utf8.encode(nonce);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Update token expiration in TokenManager
  static void _updateTokenExpiration(String idToken) {
    try {
      final userInfo = _parseIdToken(idToken);
      if (userInfo['exp'] != null && userInfo['exp'] is int) {
        final expirationDateTime = DateTime.fromMillisecondsSinceEpoch(userInfo['exp'] * 1000);
        TokenManager.setTokenExpiration(expirationDateTime);
        print('[Debug _updateTokenExpiration] Token expiration set to: $expirationDateTime');
      }
    } catch (e) {
      print('[Debug _updateTokenExpiration] Error: $e');
    }
  }

  /// Save credentials to SharedPreferences for persistence
  static Future<void> _saveCredentials(auth.AccessCredentials credentials) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('accessToken', credentials.accessToken.data);
      if (credentials.refreshToken != null) {
        await prefs.setString('refreshToken', credentials.refreshToken!);
      }
      await prefs.setStringList('scopes', credentials.scopes);
      print('[Debug _saveCredentials] Credentials saved.');
    } catch (e) {
      print('Error saving credentials: $e');
    }
  }

  /// Get saved credentials from SharedPreferences
  static Future<auth.AccessCredentials?> _getSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessTokenData = prefs.getString('accessToken');
      final refreshToken = prefs.getString('refreshToken');
      final scopes = prefs.getStringList('scopes');

      if (accessTokenData == null || scopes == null) {
        return null;
      }

      final accessToken = auth.AccessToken(
        'Bearer',
        accessTokenData,
        DateTime.now().toUtc().add(const Duration(hours: 1)),
      );

      return auth.AccessCredentials(
        accessToken,
        refreshToken,
        scopes,
      );
    } catch (e) {
      print('Error getting saved credentials: $e');
      return null;
    }
  }

  /// Complete reset - disconnect from Google services entirely
  static Future<void> completeReset() async {
    try {
      print('Starting complete Google authentication reset...');
      await clearLoginData();
      print('Complete Google authentication reset finished');
    } catch (error) {
      print('Error during complete reset: $error');
    }
  }

  /// Simple reset - same as complete reset for Credential Manager
  static Future<void> simpleReset() async {
    try {
      print('Starting simple Google authentication reset...');
      await clearLoginData();
      print('Simple Google authentication reset completed successfully');
    } catch (error) {
      print('Error during simple reset: $error');
    }
  }
}