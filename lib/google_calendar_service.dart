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
      } else {
        await prefs.remove('lastSignedInEmail');
      }
      

    } catch (e) {
      // Failed to initialize Google sign-in, ignore error
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
    try {
      if (_calendarApi == null) {
        throw Exception('Calendar API not initialized. Please sign in first.');
      }

      // Proactively validate authentication
      final isValid = await _validateAuthentication();
      if (!isValid) {

        return null;
      }

      final calendar.Event createdEvent = await _calendarApi!.events.insert(
        event,
        calendarId ?? 'primary',
      );


      return createdEvent;
    } catch (e) {
      // Failed to create event, handle authentication errors
      
      // If authentication error, try to refresh
      if (e.toString().contains('401') || e.toString().contains('403')) {

        final refreshSuccess = await _refreshAuthentication();
        
        if (refreshSuccess && _calendarApi != null) {
          // Retry once with refreshed authentication
          try {
            final calendar.Event createdEvent = await _calendarApi!.events.insert(
              event,
              calendarId ?? 'primary',
            );
            return createdEvent;
          } catch (retryError) {
            // Retry failed, return null
            return null;
          }
        } else {

          return null;
        }
      }
      
      return null;
    }
  }

  /// Update a calendar event
  static Future<calendar.Event?> updateEvent({
    required String eventId,
    required calendar.Event event,
    String? calendarId,
  }) async {
    try {
      if (_calendarApi == null) {
        throw Exception('Calendar API not initialized. Please sign in first.');
      }

      final calendar.Event updatedEvent = await _calendarApi!.events.update(
        event,
        calendarId ?? 'primary',
        eventId,
      );


      return updatedEvent;
    } catch (e) {
      // Failed to update event, handle authentication errors
      
      // If authentication error, try to refresh
      if (e.toString().contains('401') || e.toString().contains('403')) {

        final refreshSuccess = await _refreshAuthentication();
        
        if (refreshSuccess && _calendarApi != null) {
          // Retry once with refreshed authentication
          try {
            final calendar.Event updatedEvent = await _calendarApi!.events.update(
              event,
              calendarId ?? 'primary',
              eventId,
            );
            return updatedEvent;
          } catch (retryError) {
            // Retry failed for update event
            return null;
          }
        } else {
          // Failed to refresh authentication for update event
          return null;
        }
      }
      
      return null;
    }
  }

  /// Delete a calendar event
  static Future<bool> deleteEvent({
    required String eventId,
    String? calendarId,
  }) async {
    try {
      if (_calendarApi == null) {
        throw Exception('Calendar API not initialized. Please sign in first.');
      }

      await _calendarApi!.events.delete(
        calendarId ?? 'primary',
        eventId,
      );


      return true;
    } catch (e) {
      // Failed to delete event, handle authentication errors
      
      // If authentication error, try to refresh
      if (e.toString().contains('401') || e.toString().contains('403')) {

        final refreshSuccess = await _refreshAuthentication();
        
        if (refreshSuccess && _calendarApi != null) {
          // Retry once with refreshed authentication
          try {
            await _calendarApi!.events.delete(
              calendarId ?? 'primary',
              eventId,
            );
            return true;
          } catch (retryError) {
            // Retry failed for delete event
            return false;
          }
        } else {
          // Failed to refresh authentication for delete event
          return false;
        }
      }
      
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
      return calendarList.items ?? [];
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
}
