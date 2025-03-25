import 'package:flutter/material.dart';
import 'package:googleapis/calendar/v3.dart' as cal;
import 'package:googleapis_auth/auth_io.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:spdrivercalendar/google_calendar_service.dart';
import 'package:spdrivercalendar/models/event.dart'; // Import existing Event class
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// Removed duplicate Event class since we're now importing it from models/event.dart

class CalendarTestHelper {
  /// Adds a test event to the user's Google Calendar
  static Future<bool> addTestEvent(BuildContext context) async {
    try {
      print('Starting test event creation...');
      
      // First check if we're signed in
      final isSignedIn = await GoogleCalendarService.isSignedIn();
      if (!isSignedIn) {
        print('User not signed in, attempting to sign in...');
        final account = await GoogleCalendarService.signIn();
        if (account == null) {
          _showSnackBar(context, 'Failed to authenticate with Google');
          return false;
        }
      }
      
      // Use the Calendar API directly from GoogleCalendarService
      print('Getting Calendar API client...');
      final calendarApi = await GoogleCalendarService.getCalendarApi();
      
      if (calendarApi == null) {
        print('Failed to get Calendar API client');
        _showSnackBar(context, 'Error: Failed to connect to Google Calendar');
        return false;
      }

      // Current time and end time
      final startTime = DateTime.now().add(const Duration(hours: 1));
      final endTime = DateTime.now().add(const Duration(hours: 9));

      print('Creating event object...');
      // Create a new event
      final event = cal.Event();
      event.summary = 'Test Shift from Spare Driver Calendar';
      event.description = 'This is a test event created by the Spare Driver Calendar app';
      
      // Create start and end times correctly
      final startEventDateTime = cal.EventDateTime();
      startEventDateTime.dateTime = startTime;
      startEventDateTime.timeZone = 'Europe/Dublin';
      event.start = startEventDateTime;
      
      final endEventDateTime = cal.EventDateTime();
      endEventDateTime.dateTime = endTime;
      endEventDateTime.timeZone = 'Europe/Dublin';
      event.end = endEventDateTime;
      
      // Disable notifications
      final reminders = cal.EventReminders();
      reminders.useDefault = false;
      reminders.overrides = [];
      event.reminders = reminders;
      
      event.colorId = '4';  // Red color for test events
      event.location = 'Test Location';

      print('Inserting event into calendar...');
      // Insert the event
      final createdEvent = await calendarApi.events.insert(
        event,
        'primary',  // Use the user's primary calendar
      );

      print('Event created with ID: ${createdEvent.id}');
      _showSnackBar(
        context, 
        'Test event created successfully! Check your Google Calendar.',
      );
      
      return true;
    } catch (e) {
      print('Error creating test event: $e');
      _showSnackBar(context, 'Error creating test event: $e');
      return false;
    }
  }

  /// Fetch recent events from the user's Google Calendar
  static Future<List<cal.Event>> fetchRecentEvents(BuildContext context) async {
    try {
      // Use the Calendar API directly from GoogleCalendarService
      final calendarApi = await GoogleCalendarService.getCalendarApi();
      
      if (calendarApi == null) {
        _showSnackBar(context, 'Error: Failed to connect to Google Calendar');
        return [];
      }

      // Query for recent events - use DateTime objects directly
      final now = DateTime.now();
      final pastDate = now.subtract(const Duration(days: 1)).toUtc();
      final futureDate = now.add(const Duration(days: 7)).toUtc();
      
      final events = await calendarApi.events.list(
        'primary',  // Use the user's primary calendar
        timeMin: pastDate,
        timeMax: futureDate,
        maxResults: 10,
      );

      return events.items ?? [];
    } catch (e) {
      _showSnackBar(context, 'Error fetching events: $e');
      return [];
    }
  }

  /// Adds a work shift to the Google Calendar
  static Future<bool> addWorkShiftToCalendar({
    required BuildContext context,
    required String title,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      // Store context.mounted in a local variable to safely check throughout the method
      final bool isContextMounted = context.mounted;
      
      print('Adding work shift to calendar...');
      
      // Get Google Sign-In status
      final isSignedIn = await GoogleCalendarService.isSignedIn();
      print('Google Sign-In status: $isSignedIn');
      
      if (!isSignedIn) {
        if (isContextMounted) {
          _showSnackBar(context, 'Please sign in to Google Calendar first');
        }
        return false;
      }
      
      // Get the HTTP client
      final httpClient = await GoogleCalendarService.getAuthenticatedClient();
      if (httpClient == null) {
        if (isContextMounted) {
          _showSnackBar(context, 'Failed to authenticate with Google');
        }
        return false;
      }
      
      // Create Calendar API client
      final calendarApi = cal.CalendarApi(httpClient);
      
      // Create a new event
      final event = cal.Event();
      event.summary = title;
      
      // Set start time
      final startEventDateTime = cal.EventDateTime();
      startEventDateTime.dateTime = startTime;
      startEventDateTime.timeZone = 'Europe/Dublin';
      event.start = startEventDateTime;
      
      // Set end time
      final endEventDateTime = cal.EventDateTime();
      endEventDateTime.dateTime = endTime;
      endEventDateTime.timeZone = 'Europe/Dublin';
      event.end = endEventDateTime;
      
      // Disable notifications
      final reminders = cal.EventReminders();
      reminders.useDefault = false;
      reminders.overrides = [];
      event.reminders = reminders;
      
      // Set color based on shift type
      event.colorId = _getColorIdForShift(title);
      
      // Insert the event
      final createdEvent = await calendarApi.events.insert(
        event,
        'primary',  // Use the user's primary calendar
      );

      print('Work shift added with ID: ${createdEvent.id}');
      
      // Only show SnackBar if context is still valid
      if (isContextMounted) {
        _showSnackBar(
          context, 
          'Work shift added to your Google Calendar',
        );
      }
      
      return true;
    } catch (e) {
      print('Error adding work shift to calendar: $e');
      return false;
    }
  }
  
  /// Delete an event from Google Calendar by title
  static Future<bool> deleteEventFromCalendar({
    required BuildContext context,
    required String title,
    DateTime? eventStartTime,
  }) async {
    try {
      // Store context.mounted in a local variable to safely check throughout the method
      final bool isContextMounted = context.mounted;
      
      print('Deleting event from Google Calendar: $title');
      
      // Check if we're signed in
      final isSignedIn = await GoogleCalendarService.isSignedIn();
      if (!isSignedIn) {
        print('User not signed in, cannot delete event');
        return false;
      }
      
      // Get Calendar API client
      final calendarApi = await GoogleCalendarService.getCalendarApi();
      
      if (calendarApi == null) {
        print('Failed to get Calendar API client');
        return false;
      }

      // Find events that match the title - limit the search window to 1 day if start time is provided
      DateTime timeMin = eventStartTime != null 
          ? DateTime(eventStartTime.year, eventStartTime.month, eventStartTime.day)
          : DateTime.now().subtract(const Duration(days: 30));
      
      DateTime timeMax = eventStartTime != null 
          ? DateTime(eventStartTime.year, eventStartTime.month, eventStartTime.day, 23, 59, 59)
          : DateTime.now().add(const Duration(days: 30));
      
      final events = await calendarApi.events.list(
        'primary',
        timeMin: timeMin.toUtc(),
        timeMax: timeMax.toUtc(),
        q: title, // Search by title
      );
      
      // If no events found, return
      if (events.items == null || events.items!.isEmpty) {
        print('No matching events found to delete');
        return false;
      }
      
      // If we found matching events, delete the ones that match both title and date/time (if provided)
      bool deletedAny = false;
      for (var event in events.items!) {
        bool shouldDelete = event.summary == title;
        
        // If start time is provided, verify the event starts on the same day and time
        if (shouldDelete && eventStartTime != null && event.start?.dateTime != null) {
          final eventDateTime = event.start!.dateTime!;
          
          // Check if the event occurs on the same day
          bool sameDay = eventDateTime.year == eventStartTime.year && 
                         eventDateTime.month == eventStartTime.month && 
                         eventDateTime.day == eventStartTime.day;
          
          // Only delete if it's on the same day (and approximately same time if provided)
          if (sameDay) {
            // For precision, we could also check if the hour/minute is close, 
            // but for most cases the day match plus exact title should be sufficient
            print('Deleting event with ID: ${event.id} (matches title and date)');
            await calendarApi.events.delete('primary', event.id!);
            deletedAny = true;
          }
        } else if (shouldDelete) {
          // If no start time provided, just delete based on title
          print('Deleting event with ID: ${event.id} (matches title only)');
          await calendarApi.events.delete('primary', event.id!);
          deletedAny = true;
        }
      }
      
      if (deletedAny) {
        print('Successfully deleted event(s) from Google Calendar');
        return true;
      } else {
        print('No exact matches found to delete');
        return false;
      }
    } catch (e) {
      print('Error deleting event from calendar: $e');
      return false;
    }
  }

  // Helper method to show a snackbar
  static void _showSnackBar(BuildContext context, String message) {
    // Additional safety check
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2), // Reduced from 5 seconds to 2 seconds
      ),
    );
  }

  // Helper method to determine Google Calendar color ID based on shift title
  static String _getColorIdForShift(String shiftTitle) {
    // Google Calendar color IDs:
    // 1: Blue, 2: Green, 3: Purple, 4: Red, 5: Yellow, 
    // 6: Orange, 7: Turquoise, 8: Gray, 9: Bold blue, 10: Bold green, 11: Bold red
    
    // Extract shift type from title (assuming format "Shift: TYPE")
    final shiftType = shiftTitle.replaceAll('Shift:', '').trim();
    
    if (shiftType.startsWith('SP')) {
      return '5'; // Yellow for Spare shifts
    } else if (RegExp(r'^\d{2,3}/').hasMatch(shiftType)) {
      return '7'; // Turquoise for Uni/Euro shifts
    } else if (shiftType.endsWith('X')) {
      return '6'; // Orange for Bogey shifts
    } else {
      // Try to determine shift type by parsing the shift code (e.g., PZ1/123)
      if (shiftType.contains('PZ1')) {
        return '2'; // Green for Zone 1 shifts (often Early)
      } else if (shiftType.contains('PZ3')) {
        return '3'; // Purple for Zone 3 shifts (often Relief)
      } else if (shiftType.contains('PZ4')) {
        return '6'; // Orange for Zone 4 shifts (often Late)
      }
    }
    
    // Default color if we can't determine
    return '9'; // Bold blue as default
  }

  /// Checks if all local events are synced to Google Calendar
  static Future<Map<String, int>> checkCalendarSyncStatus() async {
    try {
      // First check if we're signed in
      final isSignedIn = await GoogleCalendarService.isSignedIn();
      if (!isSignedIn) {
        throw Exception('Not signed in to Google Calendar');
      }
      
      // Get local events
      final localEvents = await _getLocalEvents();
      print('Found ${localEvents.length} total local events');
      
      // Get Google Calendar events for the last 6 months
      final googleEvents = await _getGoogleCalendarEvents();
      print('Found ${googleEvents.length} Google Calendar events');
      
      // Compare events
      int matchedCount = 0;
      final unmatched = <Event>[];
      
      for (final localEvent in localEvents) {
        // Only check work shift events (PZ or UNI/EURO shifts)
        final isWorkShift = localEvent.title.contains('PZ') || 
                           RegExp(r'^\d{2,3}/').hasMatch(localEvent.title) ||
                           localEvent.title.startsWith('SP');
        
        if (!isWorkShift) {
          print('Skipping non-work shift: ${localEvent.title}');
          continue;
        }
        
        print('Checking work shift: ${localEvent.title}');
        
        bool found = false;
        for (final googleEvent in googleEvents) {
          if (googleEvent.summary == localEvent.title) {
            // Compare the date and start time
            final localStartTime = DateTime(
              localEvent.startDate.year,
              localEvent.startDate.month,
              localEvent.startDate.day,
              localEvent.startTime.hour,
              localEvent.startTime.minute,
            );
            
            final googleStartTime = googleEvent.start?.dateTime;
            if (googleStartTime != null) {
              // Allow 1 minute difference to account for rounding errors
              final difference = googleStartTime.difference(localStartTime).inMinutes.abs();
              if (difference <= 1) {
                print('Found match for ${localEvent.title}');
                found = true;
                break;
              }
            }
          }
        }
        
        if (found) {
          matchedCount++;
        } else {
          print('No match found for work shift: ${localEvent.title}');
          unmatched.add(localEvent);
        }
      }
      
      // Store unmatched events for later use
      _unmatchedEvents = unmatched;
      
      print('Sync status: ${localEvents.length} total events, $matchedCount matched, ${unmatched.length} unmatched');
      
      return {
        'totalLocalEvents': localEvents.length,
        'matchedEvents': matchedCount,
        'missingEvents': unmatched.length,
      };
    } catch (e) {
      print('Error checking calendar sync status: $e');
      rethrow;
    }
  }
  
  // Store unmatched events for sync operation
  static List<Event> _unmatchedEvents = [];
  
  /// Sync missing events to Google Calendar
  static Future<Map<String, int>> syncMissingEventsToGoogleCalendar(BuildContext context) async {
    try {
      int syncedCount = 0;
      
      // If we haven't run a check yet, do it now
      if (_unmatchedEvents.isEmpty) {
        print('No unmatched events found, running sync status check...');
        await checkCalendarSyncStatus();
      }
      
      final totalToSync = _unmatchedEvents.length;
      print('Found $totalToSync events to sync');
      
      // Get Calendar API client
      final calendarApi = await GoogleCalendarService.getCalendarApi();
      
      if (calendarApi == null) {
        throw Exception('Failed to connect to Google Calendar');
      }

      // Get existing events from Google Calendar to check for duplicates
      final now = DateTime.now();
      final pastDate = now.subtract(const Duration(days: 180)).toUtc();
      final futureDate = now.add(const Duration(days: 30)).toUtc();
      
      final existingEvents = await calendarApi.events.list(
        'primary',
        timeMin: pastDate,
        timeMax: futureDate,
        maxResults: 2500,
      );
      
      print('Found ${existingEvents.items?.length ?? 0} existing Google Calendar events');
      
      // Upload each missing event
      for (final event in _unmatchedEvents) {
        try {
          print('Processing event: ${event.title}');
          
          // Create a full DateTime with both date and time components
          final startDateTime = DateTime(
            event.startDate.year,
            event.startDate.month,
            event.startDate.day,
            event.startTime.hour,
            event.startTime.minute,
          );
          
          final endDateTime = DateTime(
            event.endDate.year,
            event.endDate.month,
            event.endDate.day,
            event.endTime.hour,
            event.endTime.minute,
          );

          // Check if event already exists
          bool eventExists = false;
          for (final existingEvent in existingEvents.items ?? []) {
            if (existingEvent.summary == event.title) {
              // If event has same title, check if it's on the same day and approximately same time
              final existingStartTime = existingEvent.start?.dateTime;
              if (existingStartTime != null) {
                final timeDifference = existingStartTime.difference(startDateTime).inMinutes.abs();
                if (timeDifference <= 1) {  // Allow 1 minute difference for rounding
                  print('Event already exists: ${event.title}');
                  eventExists = true;
                  break;
                }
              }
            }
          }

          // Only add if event doesn't exist
          if (!eventExists) {
            print('Adding event to Google Calendar: ${event.title}');
            final success = await addWorkShiftToCalendar(
              context: context,
              title: event.title,
              startTime: startDateTime,
              endTime: endDateTime,
            );
            
            if (success) {
              print('Successfully added event: ${event.title}');
              syncedCount++;
            } else {
              print('Failed to add event: ${event.title}');
            }
          }
        } catch (e) {
          print('Failed to sync event ${event.title}: $e');
          // Continue with next event
        }
      }
      
      // Clear the unmatched events list
      _unmatchedEvents = [];
      
      print('Sync complete. Synced $syncedCount out of $totalToSync events');
      
      return {
        'totalToSync': totalToSync,
        'syncedCount': syncedCount,
      };
    } catch (e) {
      print('Error syncing events to Google Calendar: $e');
      rethrow;
    }
  }
  
  /// Helper method to get all local events from the app's storage
  static Future<List<Event>> _getLocalEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final eventsJson = prefs.getString('events');
    
    if (eventsJson == null || eventsJson.isEmpty) {
      return [];
    }
    
    final Map<String, dynamic> decodedData = jsonDecode(eventsJson);
    final List<Event> allEvents = [];
    
    decodedData.forEach((dateStr, eventsList) {
      final List<dynamic> eventsData = eventsList;
      
      for (final eventData in eventsData) {
        final event = Event.fromMap(eventData);
        // To avoid duplicates, only add events that aren't already in the list
        if (!allEvents.any((e) => e.id == event.id)) {
          allEvents.add(event);
        }
      }
    });
    
    return allEvents;
  }

  /// Helper method to get all Google Calendar events for comparison
  static Future<List<cal.Event>> _getGoogleCalendarEvents() async {
    final calendarApi = await GoogleCalendarService.getCalendarApi();
    
    if (calendarApi == null) {
      throw Exception('Failed to connect to Google Calendar');
    }

    // Query for events - go back 6 months
    final now = DateTime.now();
    final pastDate = now.subtract(const Duration(days: 180)).toUtc();
    final futureDate = now.add(const Duration(days: 30)).toUtc();
    
    final events = await calendarApi.events.list(
      'primary',
      timeMin: pastDate,
      timeMax: futureDate,
      maxResults: 2500, // Increased to handle more events
    );

    return events.items ?? [];
  }
}
