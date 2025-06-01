import 'dart:convert';
import 'package:flutter/foundation.dart';
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

  // Configuration - these will be set from environment or config
  static String? _webClientId;
  static String? _androidClientId;

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
      print('[GoogleCalendar] Initializing Google Calendar Service...');
      
      // Configure GoogleSignIn
      _googleSignIn = GoogleSignIn(
        scopes: _scopes,
        // For Android, use the client ID from google-services.json
        // For web builds, you can specify serverClientId if needed
      );

      // Check if user was previously signed in
      final bool isSignedIn = await _googleSignIn.isSignedIn();
      if (isSignedIn) {
        print('[GoogleCalendar] User was previously signed in, attempting silent sign-in...');
        _currentUser = await _googleSignIn.signInSilently();
        if (_currentUser != null) {
          print('[GoogleCalendar] Silent sign-in successful for ${_currentUser!.email}');
          await _initializeCalendarApi();
        } else {
          print('[GoogleCalendar] Silent sign-in failed');
        }
      } else {
        print('[GoogleCalendar] User was not previously signed in');
      }

      _isInitialized = true;
      print('[GoogleCalendar] Google Calendar Service initialized successfully');
    } catch (e, stackTrace) {
      print('[GoogleCalendar] Error initializing Google Calendar Service: $e');
      print('[GoogleCalendar] Stack trace: $stackTrace');
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
      print('[GoogleCalendar] Calendar API initialized successfully');
    } catch (e) {
      print('[GoogleCalendar] Error initializing Calendar API: $e');
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

    return auth.AccessCredentials(
      auth.AccessToken(
        'Bearer',
        googleAuth.accessToken!,
        // Google doesn't provide expiry time through google_sign_in
        // but tokens typically last 1 hour - MUST be in UTC
        DateTime.now().toUtc().add(const Duration(hours: 1)),
      ),
      googleAuth.idToken, // refresh token
      _scopes,
    );
  }

  /// Sign in with Google
  static Future<String?> signInWithGoogle({bool interactive = true}) async {
    try {
      print('[GoogleCalendar] Starting sign-in process (interactive: $interactive)...');
      
      if (!interactive) {
        // Try silent sign-in first
        _currentUser = await _googleSignIn.signInSilently();
      } else {
        // Interactive sign-in
        _currentUser = await _googleSignIn.signIn();
      }

      if (_currentUser != null) {
        print('[GoogleCalendar] Sign-in successful for ${_currentUser!.email}');
        await _initializeCalendarApi();
        await _saveLoginStatus(true);
        return _currentUser!.email;
      } else {
        print('[GoogleCalendar] Sign-in failed or was cancelled');
        await _saveLoginStatus(false);
        return null;
      }
    } catch (e, stackTrace) {
      print('[GoogleCalendar] Error during sign-in: $e');
      print('[GoogleCalendar] Stack trace: $stackTrace');
      await _saveLoginStatus(false);
      return null;
    }
  }

  /// Sign out from Google
  static Future<void> signOut() async {
    try {
      print('[GoogleCalendar] Signing out...');
      await _googleSignIn.signOut();
      _currentUser = null;
      _calendarApi = null;
      await _saveLoginStatus(false);
      print('[GoogleCalendar] Sign-out successful');
    } catch (e) {
      print('[GoogleCalendar] Error during sign-out: $e');
    }
  }

  /// Check if user is currently signed in
  static Future<bool> isSignedIn() async {
    try {
      return await _googleSignIn.isSignedIn();
    } catch (e) {
      print('[GoogleCalendar] Error checking sign-in status: $e');
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
      print('[GoogleCalendar] Error getting current user email: $e');
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
      
      print('[GoogleCalendar] Saved login status: $status');
    } catch (e) {
      print('[GoogleCalendar] Error saving login status: $e');
    }
  }

  /// Get login status from SharedPreferences
  static Future<bool> getLoginStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('hasCompletedGoogleLogin') ?? false;
    } catch (e) {
      print('[GoogleCalendar] Error getting login status: $e');
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
      
      print('[GoogleCalendar] Cleared all login data');
    } catch (e) {
      print('[GoogleCalendar] Error clearing login data: $e');
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

      final calendar.Events events = await _calendarApi!.events.list(
        calendarId ?? 'primary',
        timeMin: startTime,
        timeMax: endTime,
        singleEvents: true,
        orderBy: 'startTime',
      );

      return events.items ?? [];
    } catch (e) {
      print('[GoogleCalendar] Error listing events: $e');
      
      // If authentication error, try to refresh
      if (e.toString().contains('401') || e.toString().contains('403')) {
        print('[GoogleCalendar] Authentication error, attempting to refresh...');
        await _refreshAuthentication();
        // Retry once
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
          print('[GoogleCalendar] Retry failed: $retryError');
          throw retryError;
        }
      }
      
      throw e;
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

      final calendar.Event createdEvent = await _calendarApi!.events.insert(
        event,
        calendarId ?? 'primary',
      );

      print('[GoogleCalendar] Event created successfully: ${createdEvent.id}');
      return createdEvent;
    } catch (e) {
      print('[GoogleCalendar] Error creating event: $e');
      
      // If authentication error, try to refresh
      if (e.toString().contains('401') || e.toString().contains('403')) {
        print('[GoogleCalendar] Authentication error, attempting to refresh...');
        await _refreshAuthentication();
        // Retry once
        try {
          final calendar.Event createdEvent = await _calendarApi!.events.insert(
            event,
            calendarId ?? 'primary',
          );
          return createdEvent;
        } catch (retryError) {
          print('[GoogleCalendar] Retry failed: $retryError');
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

      print('[GoogleCalendar] Event updated successfully: ${updatedEvent.id}');
      return updatedEvent;
    } catch (e) {
      print('[GoogleCalendar] Error updating event: $e');
      
      // If authentication error, try to refresh
      if (e.toString().contains('401') || e.toString().contains('403')) {
        print('[GoogleCalendar] Authentication error, attempting to refresh...');
        await _refreshAuthentication();
        // Retry once
        try {
          final calendar.Event updatedEvent = await _calendarApi!.events.update(
            event,
            calendarId ?? 'primary',
            eventId,
          );
          return updatedEvent;
        } catch (retryError) {
          print('[GoogleCalendar] Retry failed: $retryError');
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

      print('[GoogleCalendar] Event deleted successfully: $eventId');
      return true;
    } catch (e) {
      print('[GoogleCalendar] Error deleting event: $e');
      
      // If authentication error, try to refresh
      if (e.toString().contains('401') || e.toString().contains('403')) {
        print('[GoogleCalendar] Authentication error, attempting to refresh...');
        await _refreshAuthentication();
        // Retry once
        try {
          await _calendarApi!.events.delete(
            calendarId ?? 'primary',
            eventId,
          );
          return true;
        } catch (retryError) {
          print('[GoogleCalendar] Retry failed: $retryError');
          return false;
        }
      }
      
      return false;
    }
  }

  /// Refresh authentication
  static Future<void> _refreshAuthentication() async {
    try {
      print('[GoogleCalendar] Refreshing authentication...');
      
      if (_currentUser != null) {
        // Clear the current authentication and re-authenticate
        await _currentUser!.clearAuthCache();
        await _initializeCalendarApi();
        print('[GoogleCalendar] Authentication refreshed successfully');
      } else {
        print('[GoogleCalendar] No current user to refresh authentication for');
      }
    } catch (e) {
      print('[GoogleCalendar] Error refreshing authentication: $e');
      // If refresh fails, user needs to sign in again
      await signOut();
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
      print('[GoogleCalendar] Error getting calendars: $e');
      return [];
    }
  }

  /// Test calendar connection
  static Future<bool> testConnection() async {
    try {
      print('[GoogleCalendar] Testing calendar connection...');
      
      if (_calendarApi == null) {
        print('[GoogleCalendar] Calendar API not initialized');
        return false;
      }

      // Try to list calendars as a simple test
      final calendars = await getCalendars();
      print('[GoogleCalendar] Connection test successful. Found ${calendars.length} calendars');
      return true;
    } catch (e) {
      print('[GoogleCalendar] Connection test failed: $e');
      return false;
    }
  }
}