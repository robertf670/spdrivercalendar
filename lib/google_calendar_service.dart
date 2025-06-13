import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GoogleCalendarService {
  // Google Sign-In configuration
  static late GoogleSignIn _googleSignIn;
  static GoogleSignInAccount? _currentUser;
  static calendar.CalendarApi? _calendarApi;
  static bool _isInitialized = false;

  // Scopes required for calendar access
  static const List<String> _scopes = [
    'email',
    'openid',
    'profile',
    'https://www.googleapis.com/auth/calendar.readonly',
    'https://www.googleapis.com/auth/calendar.events',
  ];

  // Token management constants
  static const Duration _apiTimeout = Duration(seconds: 30); // API call timeout
  static DateTime? _lastTokenRefresh;

  /// Initialize the Google Calendar service
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {

      
      // Configure GoogleSignIn
      _googleSignIn = GoogleSignIn(
        scopes: _scopes,
        // Use Web OAuth client ID - doesn't require SHA-1 fingerprints
        serverClientId: '1051329330296-l7so8o8bfdm4h1g1hj9ql30dmuq1514e.apps.googleusercontent.com',
        // For Android, use the client ID from google-services.json
        // For web builds, you can specify serverClientId if needed
      );

      // Load token refresh timestamp from previous session
      await _loadTokenRefreshTimestamp();

      // Check if user was previously signed in
      final bool isSignedIn = await _googleSignIn.isSignedIn();
      if (isSignedIn) {

        _currentUser = await _googleSignIn.signInSilently();
        if (_currentUser != null) {

          await _initializeCalendarApi();
        } else {

        }
      } else {

      }

      _isInitialized = true;

    } catch (e) {
      _isInitialized = true; // Mark as initialized even if failed to prevent retry loops
    }
  }

  /// Initialize the Calendar API with authenticated client
  static Future<void> _initializeCalendarApi() async {
    if (_currentUser == null) return;

    try {
      final auth.AccessCredentials credentials = await _getAccessCredentials();
      final auth.AuthClient authClient = auth.authenticatedClient(
        http.Client(),
        credentials,
      );
      
      _calendarApi = calendar.CalendarApi(authClient);

    } catch (e) {

      _calendarApi = null;
    }
  }

  /// Get access credentials from Google Sign-In
  static Future<auth.AccessCredentials> _getAccessCredentials() async {
    if (_currentUser == null) {
      throw Exception('User not signed in');
    }

    final GoogleSignInAuthentication googleAuth = await _currentUser!.authentication;
    
    if (googleAuth.accessToken == null) {
      throw Exception('Access token is null');
    }

    // Use a shorter expiry time to force more frequent validation
    // This helps catch token expiry issues early
    final expiryTime = DateTime.now().toUtc().add(const Duration(minutes: 50));

    return auth.AccessCredentials(
      auth.AccessToken(
        'Bearer',
        googleAuth.accessToken!,
        expiryTime,
      ),
      googleAuth.idToken, // refresh token
      _scopes,
    );
  }

  /// Sign in with Google
  static Future<String?> signInWithGoogle({bool interactive = true}) async {
    try {

      
      if (!interactive) {
        // Try silent sign-in first
        _currentUser = await _googleSignIn.signInSilently();
      } else {
        // Interactive sign-in
        _currentUser = await _googleSignIn.signIn();
      }

      if (_currentUser != null) {

        await _initializeCalendarApi();
        await _saveLoginStatus(true);
        return _currentUser!.email;
      } else {

        await _saveLoginStatus(false);
        return null;
      }
    } catch (e) {
      await _saveLoginStatus(false);
      return null;
    }
  }

  /// Sign out from Google
  static Future<void> signOut() async {
    try {

      await _googleSignIn.signOut();
      _currentUser = null;
      _calendarApi = null;
      await _saveLoginStatus(false);

    } catch (e) {
      // Failed to sign out, ignore error
    }
  }

  /// Check if user is currently signed in
  static Future<bool> isSignedIn() async {
    try {
      return await _googleSignIn.isSignedIn();
    } catch (e) {
      // Failed to check sign in status, assume false
      return false;
    }
  }

  /// Get current user email
  static Future<String?> getCurrentUserEmail() async {
    try {
      if (_currentUser != null) {
        return _currentUser!.email;
      }
      
      // Try to get from saved preferences
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('lastSignedInEmail');
    } catch (e) {
      // Failed to get current user email, return null
      return null;
    }
  }

  /// Save login status to SharedPreferences
  static Future<void> _saveLoginStatus(bool status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasCompletedGoogleLogin', status);
      
      if (status && _currentUser != null) {
        await prefs.setString('lastSignedInEmail', _currentUser!.email);
        // Save current timestamp for token refresh tracking
        await prefs.setInt('lastTokenRefreshTimestamp', DateTime.now().millisecondsSinceEpoch);
      } else {
        await prefs.remove('lastSignedInEmail');
        await prefs.remove('lastTokenRefreshTimestamp');
      }
      

    } catch (e) {
      // Failed to initialize Google sign-in, ignore error
    }
  }

  /// Save token refresh timestamp to SharedPreferences
  static Future<void> _saveTokenRefreshTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('lastTokenRefreshTimestamp', DateTime.now().millisecondsSinceEpoch);
      _lastTokenRefresh = DateTime.now();
    } catch (e) {
      // Failed to save timestamp, ignore error
    }
  }

  /// Load token refresh timestamp from SharedPreferences
  static Future<void> _loadTokenRefreshTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt('lastTokenRefreshTimestamp');
      if (timestamp != null) {
        _lastTokenRefresh = DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
    } catch (e) {
      // Failed to load timestamp, ignore error
    }
  }

  /// Get login status from SharedPreferences
  static Future<bool> getLoginStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('hasCompletedGoogleLogin') ?? false;
    } catch (e) {

      return false;
    }
  }

  /// Clear all login data
  static Future<void> clearLoginData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('hasCompletedGoogleLogin');
      await prefs.remove('lastSignedInEmail');
      
      _currentUser = null;
      _calendarApi = null;
      

    } catch (e) {
      // Failed to clear login data, ignore error
    }
  }

  /// List calendar events for a date range
  static Future<List<calendar.Event>> listEvents({
    required DateTime startTime,
    required DateTime endTime,
    String? calendarId,
  }) async {
    try {
      if (_calendarApi == null) {
        throw Exception('Calendar API not initialized. Please sign in first.');
      }

      // Proactively validate authentication
      final isValid = await _validateAuthentication();
      if (!isValid) {
        throw Exception('Authentication validation failed. Please sign in again.');
      }

      final calendar.Events events = await _calendarApi!.events.list(
        calendarId ?? 'primary',
        timeMin: startTime,
        timeMax: endTime,
        singleEvents: true,
        orderBy: 'startTime',
      );

      return events.items ?? [];
    } catch (e) {
      // Failed to list events, handle authentication errors
      
      // If authentication error, try to refresh
      if (e.toString().contains('401') || e.toString().contains('403')) {

        final refreshSuccess = await _refreshAuthentication();
        
        if (refreshSuccess && _calendarApi != null) {
          // Retry once with refreshed authentication
          try {
            final calendar.Events events = await _calendarApi!.events.list(
              calendarId ?? 'primary',
              timeMin: startTime,
              timeMax: endTime,
              singleEvents: true,
              orderBy: 'startTime',
            );
            return events.items ?? [];
          } catch (retryError) {
            // Retry failed, re-throw error
            rethrow;
          }
        } else {
          throw Exception('Authentication refresh failed. Please sign in again.');
        }
      }
      
      rethrow;
    }
  }

  /// Create a calendar event
  static Future<calendar.Event?> createEvent({
    required calendar.Event event,
    String? calendarId,
  }) async {
    if (_calendarApi == null) {
      throw Exception('Calendar API not initialized. Please sign in first.');
    }
    
    return await _apiCallWithTimeout<calendar.Event>(
      () async {
        final calendar.Event createdEvent = await _calendarApi!.events.insert(
          event,
          calendarId ?? 'primary',
        );
        return createdEvent;
      },
      'Create Event',
    );
  }

  /// Update a calendar event
  static Future<calendar.Event?> updateEvent({
    required String eventId,
    required calendar.Event event,
    String? calendarId,
  }) async {
    if (_calendarApi == null) {
      throw Exception('Calendar API not initialized. Please sign in first.');
    }

    return await _apiCallWithTimeout<calendar.Event>(
      () async {
        final calendar.Event updatedEvent = await _calendarApi!.events.update(
          event,
          calendarId ?? 'primary',
          eventId,
        );
        return updatedEvent;
      },
      'Update Event',
    );
  }

  /// Delete a calendar event
  static Future<bool> deleteEvent({
    required String eventId,
    String? calendarId,
  }) async {
    if (_calendarApi == null) {
      throw Exception('Calendar API not initialized. Please sign in first.');
    }

    try {
      await _apiCallWithTimeout<void>(
        () async {
          await _calendarApi!.events.delete(
            calendarId ?? 'primary',
            eventId,
          );
        },
        'Delete Event',
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Refresh authentication with multiple retry strategies
  static Future<bool> _refreshAuthentication() async {
    try {

      
      if (_currentUser == null) {

        final email = await signInWithGoogle(interactive: false);
        return email != null;
      }

      // Strategy 1: Clear auth cache and reinitialize
      try {
        await _currentUser!.clearAuthCache();
        await _initializeCalendarApi();
        
        // Test the connection to verify the refresh worked
        final testResult = await testConnection();
        if (testResult) {
          await _saveTokenRefreshTimestamp();
          return true;
        }
      } catch (e) {
        // Failed to clear auth cache, continue with next strategy
      }

      // Strategy 2: Try silent sign-in to get fresh tokens
      try {

        final silentUser = await _googleSignIn.signInSilently();
        if (silentUser != null) {
          _currentUser = silentUser;
          await _initializeCalendarApi();
          
          final testResult = await testConnection();
          if (testResult) {
            await _saveTokenRefreshTimestamp();
            return true;
          }
        }
      } catch (e) {
        // Failed to sign in silently, continue with sign out
      }

      // Strategy 3: Complete sign-out and indicate authentication needed

      await signOut();
      return false;
      
    } catch (e) {

      await signOut();
      return false;
    }
  }

  /// Get list of calendars
  static Future<List<calendar.CalendarListEntry>> getCalendars() async {
    try {
      if (_calendarApi == null) {
        throw Exception('Calendar API not initialized. Please sign in first.');
      }

      final calendar.CalendarList calendarList = await _calendarApi!.calendarList.list();
      final calendars = calendarList.items ?? [];
      return calendars;
    } catch (e) {
      return [];
    }
  }

  /// Validate and refresh authentication if needed
  static Future<bool> _validateAuthentication() async {
    try {
      if (_currentUser == null || _calendarApi == null) {
        return false;
      }

      // Quick test to validate current authentication
      try {
        await _calendarApi!.calendarList.list(maxResults: 1);
        return true;
      } catch (e) {
        if (e.toString().contains('401') || e.toString().contains('403')) {
          return await _refreshAuthentication();
        }
        rethrow;
      }
    } catch (e) {
      return false;
    }
  }

  /// Test calendar connection
  static Future<bool> testConnection() async {
    try {
      if (_calendarApi == null) {
        return false;
      }

      // Try to list calendars as a simple test
      await getCalendars();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check if tokens need proactive refresh (before they expire)
  static Future<bool> _shouldRefreshTokens() async {
    try {
      if (_currentUser == null) return true;
      
      // Check if we've refreshed recently (within last 5 minutes)
      if (_lastTokenRefresh != null) {
        final timeSinceLastRefresh = DateTime.now().difference(_lastTokenRefresh!);
        if (timeSinceLastRefresh < const Duration(minutes: 5)) {
          return false; // Don't refresh too frequently
        }
      }
      
      // Get current authentication and check expiry
      final GoogleSignInAuthentication googleAuth = await _currentUser!.authentication;
      if (googleAuth.accessToken == null) return true;
      
      // For Google tokens, we can't directly check expiry time, so we use a time-based approach
      // Refresh if it's been more than 45 minutes since last refresh (Google tokens typically last 1 hour)
      if (_lastTokenRefresh != null) {
        final timeSinceLastRefresh = DateTime.now().difference(_lastTokenRefresh!);
        return timeSinceLastRefresh > const Duration(minutes: 45);
      }
      
      // If we don't have a last refresh time, assume we need to refresh
      return true;
    } catch (e) {
      // If we can't check, assume we need to refresh
      return true;
    }
  }

  /// Proactively refresh tokens before API operations
  static Future<bool> _ensureValidTokens() async {
    try {
      // On first call after app startup, do comprehensive validation
      if (_lastTokenRefresh == null) {
        return await _handleStartupTokenValidation();
      }
      
      // Check if we need to refresh tokens proactively
      if (await _shouldRefreshTokens()) {
        final refreshSuccess = await _refreshAuthentication();
        if (refreshSuccess) {
          await _saveTokenRefreshTimestamp();
        }
        return refreshSuccess;
      }
      
      // Tokens should be valid, but do a quick validation
      return await _validateAuthentication();
    } catch (e) {
      return false;
    }
  }

  /// Wrapper for API calls with timeout and retry logic
  static Future<T?> _apiCallWithTimeout<T>(
    Future<T> Function() apiCall,
    String operationName,
  ) async {
    try {
      // Ensure tokens are valid before making the call
      final tokensValid = await _ensureValidTokens();
      if (!tokensValid) {
        throw Exception('Authentication failed for $operationName');
      }

      // Make the API call with timeout
      final result = await apiCall().timeout(_apiTimeout);
      return result;
    } catch (e) {
      // Handle authentication errors with retry
      if (e.toString().contains('401') || e.toString().contains('403')) {
        final refreshSuccess = await _refreshAuthentication();
        if (refreshSuccess) {
          await _saveTokenRefreshTimestamp();
          try {
            // Retry once with refreshed authentication
            return await apiCall().timeout(_apiTimeout);
          } catch (retryError) {
            return null;
          }
        }
      }
      
      // Handle timeout errors
      if (e.toString().contains('TimeoutException')) {
        throw Exception('$operationName timed out after ${_apiTimeout.inSeconds} seconds. Please check your connection and try again.');
      }
      
      return null;
    }
  }

  /// Check if tokens likely expired while app was closed and proactively refresh
  static Future<bool> _handleStartupTokenValidation() async {
    try {
      // If we don't have a last refresh timestamp, assume we need to refresh
      if (_lastTokenRefresh == null) {
        return await _refreshAuthentication();
      }
      
      // Check if tokens likely expired while app was closed
      final timeSinceLastRefresh = DateTime.now().difference(_lastTokenRefresh!);
      
      // If it's been more than 50 minutes since last refresh, tokens likely expired
      if (timeSinceLastRefresh > const Duration(minutes: 50)) {
        return await _refreshAuthentication();
      }
      
      // If it's been more than 40 minutes, do a quick validation test
      if (timeSinceLastRefresh > const Duration(minutes: 40)) {
        return await _validateAuthentication();
      }
      
      // Tokens should still be valid
      return true;
    } catch (e) {
      // If anything fails, try to refresh
      return await _refreshAuthentication();
    }
  }

  // =============================================================================
  // DEVELOPER TESTING UTILITIES - Remove in production if desired
  // =============================================================================
  
  /// [DEV ONLY] Force simulate token expiry for testing
  static Future<void> devSimulateTokenExpiry() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Set timestamp to 2 hours ago to simulate expired tokens
      final expiredTimestamp = DateTime.now().subtract(const Duration(hours: 2)).millisecondsSinceEpoch;
      await prefs.setInt('lastTokenRefreshTimestamp', expiredTimestamp);
      _lastTokenRefresh = DateTime.fromMillisecondsSinceEpoch(expiredTimestamp);
    } catch (e) {
      // Failed to simulate token expiry
    }
  }
  
  /// [DEV ONLY] Force simulate tokens near expiry for testing
  static Future<void> devSimulateTokensNearExpiry() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Set timestamp to 45 minutes ago to simulate tokens near expiry
      final nearExpiryTimestamp = DateTime.now().subtract(const Duration(minutes: 45)).millisecondsSinceEpoch;
      await prefs.setInt('lastTokenRefreshTimestamp', nearExpiryTimestamp);
      _lastTokenRefresh = DateTime.fromMillisecondsSinceEpoch(nearExpiryTimestamp);
    } catch (e) {
      // Failed to simulate near expiry
    }
  }
  
  /// [DEV ONLY] Reset token timestamp to now for testing
  static Future<void> devResetTokenTimestamp() async {
    try {
      await _saveTokenRefreshTimestamp();
    } catch (e) {
      // Failed to reset timestamp
    }
  }
  
  /// [DEV ONLY] Get current token status for debugging
  static Map<String, dynamic> devGetTokenStatus() {
    final now = DateTime.now();
    final status = <String, dynamic>{
      'lastTokenRefresh': _lastTokenRefresh?.toIso8601String() ?? 'null',
      'currentTime': now.toIso8601String(),
      'timeSinceRefresh': _lastTokenRefresh != null 
          ? now.difference(_lastTokenRefresh!).inMinutes 
          : null,
      'shouldRefreshTokens': null, // Will be set below
      'isSignedIn': null, // Will be set below
    };
    
    // Token status information available in returned map
    
    return status;
  }
  
  /// [DEV ONLY] Test the startup validation logic
  static Future<Map<String, dynamic>> devTestStartupValidation() async {
    final startTime = DateTime.now();
    final result = await _handleStartupTokenValidation();
    final endTime = DateTime.now();
    
    final testResult = {
      'success': result,
      'duration': endTime.difference(startTime).inMilliseconds,
      'tokenStatus': devGetTokenStatus(),
    };
    
    return testResult;
  }
  
  /// [DEV ONLY] Test the proactive refresh logic
  static Future<Map<String, dynamic>> devTestProactiveRefresh() async {
    final startTime = DateTime.now();
    final shouldRefresh = await _shouldRefreshTokens();
    final result = await _ensureValidTokens();
    final endTime = DateTime.now();
    
    final testResult = {
      'shouldRefresh': shouldRefresh,
      'success': result,
      'duration': endTime.difference(startTime).inMilliseconds,
      'tokenStatus': devGetTokenStatus(),
    };
    
    return testResult;
  }
}
