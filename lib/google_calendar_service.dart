import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:spdrivercalendar/services/token_manager.dart';
import 'dart:convert';
import 'dart:convert' show jsonDecode;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class GoogleCalendarService {
  // Static GoogleSignIn instance to be used across the app
  static GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/calendar',
    ],
    // Don't force code for refresh token every time as it causes extra auth prompts
    forceCodeForRefreshToken: false,
    // Add Web Client ID for token refresh functionality
    // serverClientId: "1051329330296-l7so8o8bfdm4h1g1hj9ql30dmuq1514e.apps.googleusercontent.com",
  );

  @visibleForTesting
  static void setGoogleSignInForTesting(GoogleSignIn mockSignIn) {
    _googleSignIn = mockSignIn;
  }

  /// Initialize the Google Calendar service
  static Future<void> initialize() async {
    // Pre-initialize Google Sign-In if needed
    try {
      final isSignedIn = await _googleSignIn.isSignedIn();
      print('[Debug Initialize] Google Sign-In initialized. Already signed in: $isSignedIn');
      
      // If signed in, verify access
      if (isSignedIn) {
        try {
          // Try silent sign in to refresh tokens
          print('[Debug Initialize] Attempting silent sign-in...');
          final account = await _googleSignIn.signInSilently();
          if (account != null) {
            print('[Debug Initialize] Silent sign-in successful: ${account.email}');
            final auth = await account.authentication;
            // Pass both accessToken and idToken. idToken can be null.
            _updateTokenExpiration(auth.accessToken, auth.idToken); 
            print('[Debug Initialize] Called _updateTokenExpiration from initialize(). Now checking TokenManager.needsRefresh(): ${TokenManager.needsRefresh()}');
          } else {
            print('[Debug Initialize] AccessToken from silent sign-in was null.');
          }
        } catch (e) {
          print('[Debug Initialize] Silent sign-in failed during initialize: $e');
        }
      }
    } catch (e) {
      print('Failed to initialize Google Sign-In: $e');
    }
  }
  
  // Check if user is currently signed in
  static Future<bool> isSignedIn() async {
    try {
      final signedIn = await _googleSignIn.isSignedIn();
      print('Google Sign-In status: $signedIn');
      return signedIn;
    } catch (e) {
      print('Error checking sign-in status: $e');
      return false;
    }
  }
  
  // Save login status to SharedPreferences
  static Future<void> saveLoginStatus(bool status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasCompletedGoogleLogin', status);
      print('Saved Google login status: $status');
    } catch (error) {
      print('Error saving login status: $error');
    }
  }
  
  // Get login status from shared preferences
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
  
  // Clear all login data
  static Future<void> clearLoginData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('hasCompletedGoogleLogin');
      await _googleSignIn.signOut();
      print('Cleared all login data');
    } catch (error) {
      print('Error clearing login data: $error');
    }
  }
  
  // Get the current signed-in user
  static Future<GoogleSignInAccount?> getCurrentUser() async {
    try {
      // Check if user is already signed in
      final currentUser = _googleSignIn.currentUser;
      
      if (currentUser != null) {
        print('Current user found: ${currentUser.email}');
        return currentUser;
      }
      
      // Try silent sign in if no current user
      final silentUser = await _googleSignIn.signInSilently();
      if (silentUser != null) {
        print('Retrieved user via silent sign-in: ${silentUser.email}');
        return silentUser;
      }
      
      print('No current user found and silent sign-in failed');
      
      // Check stored login status
      final hasCompletedLogin = await getLoginStatus();
      if (hasCompletedLogin) {
        print('User previously completed login but session expired');
      }
      
      return null;
    } catch (error) {
      print('Error getting current user: $error');
      return null;
    }
  }
  
  // Handle Google sign-in
  static Future<GoogleSignInAccount?> signIn() async {
    try {
      print('[DEBUG] Starting Google Sign-In process...');
      
      // Check if already signed in
      if (await _googleSignIn.isSignedIn()) {
        final currentUser = _googleSignIn.currentUser;
        if (currentUser != null) {
          print('[DEBUG] User is already signed in: ${currentUser.email}');
          final auth = await currentUser.authentication;
          _updateTokenExpiration(auth.accessToken, auth.idToken);
          await saveLoginStatus(true);
          return currentUser;
        }
      }
      
      print('[DEBUG] Not currently signed in, attempting silent sign-in...');
      
      // First, try silent sign in
      final silentUser = await _googleSignIn.signInSilently();
      if (silentUser != null) {
        print('[DEBUG] Silent sign-in successful: ${silentUser.email}');
        final auth = await silentUser.authentication;
        _updateTokenExpiration(auth.accessToken, auth.idToken);
        await saveLoginStatus(true);
        return silentUser;
      }
      
      print('[DEBUG] Silent sign-in failed, trying interactive sign-in...');
      print('[DEBUG] GoogleSignIn configuration:');
      print('[DEBUG] - Scopes: ${_googleSignIn.scopes}');
      print('[DEBUG] - ServerClientId: ${_googleSignIn.serverClientId}');
      
      // If silent sign in fails, try interactive sign in
      final account = await _googleSignIn.signIn();
      
      if (account != null) {
        print('[DEBUG] Interactive sign-in successful: ${account.email}');
        print('[DEBUG] Account details:');
        print('[DEBUG] - ID: ${account.id}');
        print('[DEBUG] - Display Name: ${account.displayName}');
        print('[DEBUG] - Photo URL: ${account.photoUrl}');
        
        final auth = await account.authentication;
        if (auth.accessToken == null) {
          print('[ERROR] No access token received from interactive sign-in.');
          await saveLoginStatus(false);
          return null;
        }
        print('[DEBUG] Access Token received (first 20 chars): ${auth.accessToken!.substring(0, auth.accessToken!.length > 20 ? 20 : auth.accessToken!.length)}...');
        
        _updateTokenExpiration(auth.accessToken, auth.idToken); 
        print('[DEBUG] Token expiration updated. TokenManager.needsRefresh(): ${TokenManager.needsRefresh()}');

        await saveLoginStatus(true);
        return account;
      } else {
        print('[DEBUG] Interactive sign-in returned null - user canceled or sign-in failed');
        await saveLoginStatus(false);
        return null;
      }
    } catch (error) {
      print('[ERROR] Exception during sign in: $error');
      print('[ERROR] Error type: ${error.runtimeType}');
      if (error is PlatformException) {
        print('[ERROR] Platform Exception details:');
        print('[ERROR] - Code: ${error.code}');
        print('[ERROR] - Message: ${error.message}');
        print('[ERROR] - Details: ${error.details}');
      }
      await saveLoginStatus(false);
      return null;
    }
  }
  
  // Sign out the current user
  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await saveLoginStatus(false);
      print('User signed out successfully');
    } catch (error) {
      print('Error signing out: $error');
    }
  }

  // Get the Calendar API client using the signed-in user
  static Future<calendar.CalendarApi?> getCalendarApi() async {
    try {
      if (!await _googleSignIn.isSignedIn()) {
        print('User is not signed in - trying to sign in silently');
        final silentUser = await _googleSignIn.signInSilently();
        if (silentUser == null) {
          print('Silent sign in failed');
          return null;
        } else {
          // Signed in silently, update token expiration
          final auth = await silentUser.authentication;
          _updateTokenExpiration(auth.accessToken, auth.idToken);
        }
      }

      // Check if token needs refresh according to TokenManager
      if (TokenManager.needsRefresh()) {
        print('TokenManager indicates refresh needed. Attempting silent sign-in to refresh...');
        final account = await _googleSignIn.signInSilently();
        if (account != null) {
          final auth = await account.authentication;
          print('[Debug getCalendarApi] Silent sign-in successful after needsRefresh was true.');
          _updateTokenExpiration(auth.accessToken, auth.idToken); // Update with latest tokens
        } else {
          print('[Debug getCalendarApi] Silent sign-in failed after needsRefresh was true. Interactive sign-in might be required.');
          // Optionally, trigger interactive sign-in here or let it fail to be handled by caller
          // For now, we'll proceed and try to get the client; it might still work or fail gracefully.
        }
      }

      // Get the auth client
      final httpClient = await getAuthenticatedClient();
      
      if (httpClient == null) {
        print('Failed to get authenticated client in getCalendarApi.');
        
        // Try to re-authenticate with interactive sign-in as a last resort
        print('Attempting to re-authenticate interactively...');
        final interactiveAccount = await signIn(); // signIn already calls _updateTokenExpiration
        if (interactiveAccount == null) {
          print('Re-authentication failed in getCalendarApi.');
          return null;
        }
        
        // Try again to get authenticated client
        final retryClient = await getAuthenticatedClient();
        if (retryClient == null) {
          print('Failed to get authenticated client after re-authentication in getCalendarApi.');
          return null;
        }
        print('[Debug getCalendarApi] Successfully got client after interactive re-authentication.');
        return calendar.CalendarApi(retryClient);
      }
      print('[Debug getCalendarApi] Successfully got httpClient.');
      return calendar.CalendarApi(httpClient);
    } catch (error) {
      print('Error getting Calendar API: $error');
      return null;
    }
  }

  // Add event to Google Calendar
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

  // Get events from Google Calendar
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
  
  // Check if calendar access is still valid
  static Future<bool> checkCalendarAccess(http.Client? httpClientFromCaller) async {
    print('[Debug CheckCalendarAccess] Entered.');
    try {
      if (httpClientFromCaller == null) {
        print('[Debug CheckCalendarAccess] httpClientFromCaller is null. Cannot perform first check.');
      } else {
        print('[Debug CheckCalendarAccess] Attempting API call with httpClientFromCaller...');
        try {
          final calendarApiWithCallerClient = calendar.CalendarApi(httpClientFromCaller);
          await calendarApiWithCallerClient.calendarList.list(maxResults: 1);
          print('[Debug CheckCalendarAccess] Calendar access verified successfully with httpClientFromCaller.');
          return true; // Success with the provided client
        } catch (e) {
          print('[Debug CheckCalendarAccess] API call with httpClientFromCaller FAILED: $e');
          // Proceed to try with manually fetched token if this fails
        }
      }

      print('[Debug CheckCalendarAccess] Attempting API call with manually fetched accessToken...');
      final currentUser = _googleSignIn.currentUser;
      if (currentUser == null) {
        print('[Debug CheckCalendarAccess] No current user for GoogleSignIn. Cannot fetch manual token.');
        return false;
      }

      final auth = await currentUser.authentication;
      final accessToken = auth.accessToken;

      if (accessToken == null) {
        print('[Debug CheckCalendarAccess] Manually fetched accessToken is null.');
        return false;
      }

      print('[Debug CheckCalendarAccess] Manually fetched accessToken (first 20 chars): ${accessToken.substring(0, accessToken.length > 20 ? 20 : accessToken.length)}...');
      // Log claims of this manually fetched token for comparison
      try {
        final parts = accessToken.split('.');
        if (parts.length == 3) {
          final payload = parts[1];
          final normalized = base64Url.normalize(payload);
          final decoded = utf8.decode(base64Url.decode(normalized));
          final claims = jsonDecode(decoded);
          print('[Debug CheckCalendarAccess] Manually fetched accessToken Claims: $claims');
          if (claims['exp'] != null && claims['exp'] is int) {
            final expiration = DateTime.fromMillisecondsSinceEpoch(claims['exp'] * 1000);
            print('[Debug CheckCalendarAccess] Manually fetched accessToken Expiration: $expiration (Is Expired: ${DateTime.now().isAfter(expiration)})');
          }
        } else {
            print('[Debug CheckCalendarAccess] Manually fetched accessToken does not appear to be a valid JWT. Parts: ${parts.length}');
        }
      } catch (e) {
        print('[Debug CheckCalendarAccess] Error decoding manually fetched accessToken: $e');
      }

      final manualClient = http.Client();
      try {
        final calendarApiWithManualToken = calendar.CalendarApi(
          AuthenticatedHttpClient(manualClient, () async => accessToken)
        );
        await calendarApiWithManualToken.calendarList.list(maxResults: 1);
        print('[Debug CheckCalendarAccess] Calendar access verified successfully with MANUALLY fetched accessToken.');
        return true;
      } catch (e) {
        print('[Debug CheckCalendarAccess] API call with MANUALLY fetched accessToken FAILED: $e');
        return false;
      } finally {
        manualClient.close();
      }
    } catch (error) {
      print('[Debug CheckCalendarAccess] Outer error: $error');
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

      // Explicitly try to refresh tokens if TokenManager says it's needed,
      // before getting the authenticatedClient. This is to ensure the client
      // is created with the freshest possible tokens.
      if (TokenManager.needsRefresh()) {
        print('[Debug getAuthenticatedClient] TokenManager needs refresh. Attempting signInSilently...');
        final account = await _googleSignIn.signInSilently();
        if (account != null) {
          final auth = await account.authentication;
          _updateTokenExpiration(auth.accessToken, auth.idToken);
          print('[Debug getAuthenticatedClient] signInSilently successful, token expiration updated.');
        } else {
          print('[Debug getAuthenticatedClient] signInSilently failed during explicit refresh attempt.');
          // It might be okay to proceed, authenticatedClient might still work or handle it.
        }
      }

      // Get the authenticated client from GoogleSignIn
      // This client should handle token refreshes automatically if serverClientId is set.
      print('[Debug getAuthenticatedClient] Calling _googleSignIn.authenticatedClient()...');
      final client = await _googleSignIn.authenticatedClient();
      
      if (client == null) {
        print('[Debug getAuthenticatedClient] _googleSignIn.authenticatedClient() returned null.');
        return null;
      }
      
      print('[Debug getAuthenticatedClient] Successfully obtained client from _googleSignIn.authenticatedClient().');
      return client;
    } catch (e) {
      print('Error getting authenticated client: $e');
      return null;
    }
  }

  // Helper method to update token expiration
  static void _updateTokenExpiration(String? accessToken, String? idToken) {
    // We primarily use idToken for expiration as it's a guaranteed JWT.
    // accessToken is passed along but not directly used for 'exp' here.
    if (idToken == null) {
      print('[Debug _updateTokenExpiration] idToken is null. Cannot parse for expiration.');
      return;
    }

    print('[Debug _updateTokenExpiration] Attempting to parse idToken (first 20 chars): ${idToken.substring(0, idToken.length > 20 ? 20 : idToken.length)}...');
    try {
      final parts = idToken.split('.');
      if (parts.length != 3) {
        print('[Debug _updateTokenExpiration] idToken does not appear to be a valid JWT. Parts count: ${parts.length}');
        return;
      }
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final resp = utf8.decode(base64Url.decode(normalized));
      final payloadMap = json.decode(resp);

      if (payloadMap is Map<String, dynamic> && payloadMap.containsKey('exp')) {
        final dynamic expClaim = payloadMap['exp']; // Use dynamic type for safety before checking
        if (expClaim is int) {
          final expirationDateTime = DateTime.fromMillisecondsSinceEpoch(expClaim * 1000);
          TokenManager.setTokenExpiration(expirationDateTime);
          print('[Debug _updateTokenExpiration] Token expiration set from idToken to: $expirationDateTime');
        } else {
          print('[Debug _updateTokenExpiration] \'exp\' claim in idToken is not an integer. Actual type: ${expClaim.runtimeType}');
        }
      } else {
        print('[Debug _updateTokenExpiration] \'exp\' claim not found in idToken or payload is not a map.');
      }
    } catch (e) {
      print('[Debug _updateTokenExpiration] Error parsing idToken: $e');
    }
  }

  // Complete reset - disconnect from Google services entirely
  static Future<void> completeReset() async {
    try {
      print('Starting complete Google authentication reset...');
      
      // Clear shared preferences first
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('hasCompletedGoogleLogin');
      print('✓ Cleared shared preferences');
      
      // Clear token manager
      TokenManager.dispose();
      print('✓ Cleared token manager');
      
      // Sign out first (this usually works even if disconnect fails)
      try {
        await _googleSignIn.signOut();
        print('✓ Signed out successfully');
      } catch (signOutError) {
        print('⚠ Sign out failed: $signOutError');
      }
      
      // Try to disconnect completely (this may fail, but that's okay)
      try {
        await _googleSignIn.disconnect();
        print('✓ Disconnected successfully');
      } catch (disconnectError) {
        print('⚠ Disconnect failed (this is common): $disconnectError');
        print('ℹ Don\'t worry - other cleanup steps were successful');
      }
      
      // Additional cleanup - clear any cached authentication state
      try {
        // Force a new GoogleSignIn instance to clear any cached state
        _googleSignIn = GoogleSignIn(
          scopes: [
            'email',
            'https://www.googleapis.com/auth/calendar',
          ],
          forceCodeForRefreshToken: false,
          // serverClientId: "1051329330296-1240ki2jq18dv9jtfjt01m6ggkcv4jli.apps.googleusercontent.com", // Commented out for testing
        );
        print('✓ Recreated GoogleSignIn instance');
      } catch (recreateError) {
        print('⚠ Failed to recreate GoogleSignIn instance: $recreateError');
      }
      
      print('Complete Google authentication reset finished (some steps may have failed but that\'s normal)');
    } catch (error) {
      print('Error during complete reset: $error');
      // Even if there are errors, try to clear what we can
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('hasCompletedGoogleLogin');
        TokenManager.dispose();
      } catch (fallbackError) {
        print('Fallback cleanup also failed: $fallbackError');
      }
    }
  }

  // Simple reset - avoids disconnect() which often fails
  static Future<void> simpleReset() async {
    try {
      print('Starting simple Google authentication reset...');
      
      // Clear shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('hasCompletedGoogleLogin');
      print('✓ Cleared shared preferences');
      
      // Clear token manager
      TokenManager.dispose();
      print('✓ Cleared token manager');
      
      // Sign out only (don't try to disconnect)
      try {
        await _googleSignIn.signOut();
        print('✓ Signed out successfully');
      } catch (signOutError) {
        print('⚠ Sign out failed: $signOutError');
      }
      
      // Recreate GoogleSignIn instance to clear cached state
      _googleSignIn = GoogleSignIn(
        scopes: [
          'email',
          'https://www.googleapis.com/auth/calendar',
        ],
        forceCodeForRefreshToken: false,
        // serverClientId: "1051329330296-1240ki2jq18dv9jtfjt01m6ggkcv4jli.apps.googleusercontent.com", // Commented out for testing
      );
      print('✓ Recreated GoogleSignIn instance');
      
      print('Simple Google authentication reset completed successfully');
    } catch (error) {
      print('Error during simple reset: $error');
    }
  }
}

// Helper class for manually injecting token, now top-level and public
class AuthenticatedHttpClient extends http.BaseClient {
  final http.Client _inner;
  final Future<String?> Function() _getAccessToken;

  AuthenticatedHttpClient(this._inner, this._getAccessToken);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final token = await _getAccessToken();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
  }
}