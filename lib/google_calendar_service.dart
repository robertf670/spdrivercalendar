import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class GoogleCalendarService {
  // Static GoogleSignIn instance to be used across the app
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/calendar',
      'https://www.googleapis.com/auth/calendar.events',
    ],
    // Don't force code for refresh token every time as it causes extra auth prompts
    forceCodeForRefreshToken: false,
  );

  /// Initialize the Google Calendar service
  static Future<void> initialize() async {
    // Pre-initialize Google Sign-In if needed
    try {
      final isSignedIn = await _googleSignIn.isSignedIn();
      print('Google Sign-In initialized. Already signed in: $isSignedIn');
      
      // If signed in, verify access
      if (isSignedIn) {
        try {
          // Try silent sign in to refresh tokens
          await _googleSignIn.signInSilently();
          print('Silent sign-in executed successfully');
        } catch (e) {
          print('Silent sign-in failed: $e');
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
      // Check if already signed in
      if (await _googleSignIn.isSignedIn()) {
        final currentUser = _googleSignIn.currentUser;
        if (currentUser != null) {
          print('User is already signed in: ${currentUser.email}');
          await saveLoginStatus(true);
          return currentUser;
        }
      }
      
      // First, try silent sign in
      final silentUser = await _googleSignIn.signInSilently();
      if (silentUser != null) {
        print('Silent sign-in successful: ${silentUser.email}');
        await saveLoginStatus(true);
        return silentUser;
      }
      
      print('Silent sign-in failed, trying interactive sign-in...');
      
      // If silent sign in fails, try interactive sign in
      final account = await _googleSignIn.signIn();
      if (account != null) {
        print('Interactive sign-in successful: ${account.email}');
        
        // Force authentication to validate permissions
        final auth = await account.authentication;
        if (auth.accessToken == null) {
          print('Error: No access token received');
          await saveLoginStatus(false);
          return null;
        }
        
        print('Access token received successfully');
        await saveLoginStatus(true);
        return account;
      } else {
        print('Interactive sign-in canceled by user');
        await saveLoginStatus(false);
        return null;
      }
    } catch (error) {
      print('Error during sign in: $error');
      await saveLoginStatus(false);
      return null; // Return null instead of rethrowing to make calling code simpler
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
        }
      }

      // Get the auth client
      final httpClient = await getAuthenticatedClient();
      
      if (httpClient == null) {
        print('Failed to get authenticated client');
        
        // Try to re-authenticate
        print('Attempting to re-authenticate...');
        final account = await signIn();
        if (account == null) {
          print('Re-authentication failed');
          return null;
        }
        
        // Try again to get authenticated client
        final retryClient = await getAuthenticatedClient();
        if (retryClient == null) {
          print('Failed to get authenticated client after re-authentication');
          return null;
        }
        
        // Return the Calendar API client
        return calendar.CalendarApi(retryClient);
      }

      // Return the Calendar API client
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
  static Future<bool> checkCalendarAccess() async {
    try {
      final httpClient = await _googleSignIn.authenticatedClient();
      if (httpClient == null) {
        print('No authenticated client available');
        return false;
      }

      // Try a simple API call to verify access
      final calendarApi = calendar.CalendarApi(httpClient);
      await calendarApi.calendarList.list(maxResults: 1);
      print('Calendar access verified successfully');
      return true;
    } catch (error) {
      print('Calendar access check failed: $error');
      return false;
    }
  }

  /// Get an authenticated HTTP client
  static Future<http.Client?> getAuthenticatedClient() async {
    try {
      if (!await isSignedIn()) {
        return null;
      }

      // Convert the GoogleSignIn to a GoogleHttpClient
      final client = await _googleSignIn.authenticatedClient();
      return client;
    } catch (e) {
      print('Error getting authenticated client: $e');
      return null;
    }
  }
}