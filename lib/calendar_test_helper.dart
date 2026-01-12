import 'package:flutter/material.dart';
import 'package:googleapis/calendar/v3.dart' as cal;
import 'package:spdrivercalendar/google_calendar_service.dart';
import 'package:spdrivercalendar/models/event.dart'; // Import existing Event class
import 'package:spdrivercalendar/models/holiday.dart'; // Import the Holiday model
import 'package:spdrivercalendar/features/calendar/services/event_service.dart'; // Import EventService
// For date formatting

// Removed duplicate Event class since we're now importing it from models/event.dart

// Constant for Holiday event color in Google Calendar (Teal)
const String _holidayColorId = '8';
// Constant prefix for storing the app's holiday ID in the description
const String _holidayIdPrefix = 'App Holiday ID: ';

/// Utilities for Google Calendar testing
class CalendarTestHelper {
  /// Test creating a sample event in Google Calendar
  static Future<bool> createTestEvent(BuildContext context) async {
    try {
      // Store context.mounted status
      if (!context.mounted) return false;

      
      // Check if signed in
      final isSignedIn = await GoogleCalendarService.isSignedIn();
      if (!isSignedIn) {
        if (context.mounted) {
          _showSnackBar(context, 'Error: Please sign in to Google Calendar first');
        }
        return false;
      }
      
      // Test connection
      final hasConnection = await GoogleCalendarService.testConnection();
      if (!hasConnection) {
        if (context.mounted) {
          _showSnackBar(context, 'Error: Failed to connect to Google Calendar');
        }
        return false;
      }

      // Current time and end time
      final startTime = DateTime.now().add(const Duration(hours: 1));
      final endTime = DateTime.now().add(const Duration(hours: 9));


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


      // Use the new createEvent method
      final createdEvent = await GoogleCalendarService.createEvent(event: event);

      if (createdEvent != null) {
        if (context.mounted) {
          _showSnackBar(
            context, 
            'Test event created successfully! Check your Google Calendar.',
          );
        }
        return true;
      } else {
        if (context.mounted) {
          _showSnackBar(context, 'Error: Failed to create test event');
        }
        return false;
      }
      
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, 'Error creating test event: $e');
      }
      return false;
    }
  }

  /// Fetch recent events from the user's Google Calendar
  static Future<List<cal.Event>> fetchRecentEvents(BuildContext context) async {
    try {
      // Check if signed in
      final isSignedIn = await GoogleCalendarService.isSignedIn();
      if (!isSignedIn) {
        if (context.mounted) {
          _showSnackBar(context, 'Error: Please sign in to Google Calendar first');
        }
        return [];
      }

      // Query for recent events - use DateTime objects directly
      final now = DateTime.now();
      final pastDate = now.subtract(const Duration(days: 1)).toUtc();
      final futureDate = now.add(const Duration(days: 7)).toUtc();
      
      // Use the new listEvents method
      final events = await GoogleCalendarService.listEvents(
        startTime: pastDate,
        endTime: futureDate,
      );

      return events;
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, 'Error fetching events: $e');
      }
      return [];
    }
  }

  /// Adds a work shift to the Google Calendar
  static Future<bool> addWorkShiftToCalendar({
    required BuildContext context,
    required String title,
    required DateTime startTime,
    required DateTime endTime,
    String? description,  // Added description parameter
    bool showUIFeedback = true,  // Control UI feedback
  }) async {
    try {
      // Get Google Sign-In status
      final isSignedIn = await GoogleCalendarService.isSignedIn();

      if (!isSignedIn) {
        if (context.mounted && showUIFeedback) {
          _showSnackBar(context, 'Please sign in to Google Calendar first');
        }
        return false;
      }
      
      // Test connection
      final hasConnection = await GoogleCalendarService.testConnection();
      if (!hasConnection) {
        if (context.mounted && showUIFeedback) {
          _showSnackBar(context, 'Failed to authenticate with Google');
        }
        return false;
      }
      
      // Create a new event
      final event = cal.Event();
      event.summary = title;
      event.description = description;  // Set the description if provided
      
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
      
      // Use the new createEvent method
      final createdEvent = await GoogleCalendarService.createEvent(event: event);

      if (createdEvent != null) {
        // Only show SnackBar if context is still valid and UI feedback is enabled
        if (context.mounted && showUIFeedback) {
          _showSnackBar(
            context, 
            'Work shift added to your Google Calendar',
          );
        }
        
        return true;
      } else {
        return false;
      }
    } catch (e) {
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
      // Check if we're signed in
      final isSignedIn = await GoogleCalendarService.isSignedIn();
      if (!isSignedIn) {

        return false;
      }
      
      // First, find the event by searching for it
      final events = await GoogleCalendarService.listEvents(
        startTime: DateTime.now().subtract(const Duration(days: 30)),
        endTime: DateTime.now().add(const Duration(days: 30)),
      );
      
      // Find the event with matching title
      cal.Event? targetEvent;
      for (final event in events) {
        if (event.summary == title) {
          // If start time is provided, match by title and date (more reliable than exact time)
          if (eventStartTime != null) {
            final eventStart = event.start?.dateTime ?? event.start?.date;
            if (eventStart != null && _isSameDate(eventStart, eventStartTime)) {
              targetEvent = event;
              break;
            }
          } else {
            targetEvent = event;
            break;
          }
        }
      }
      
      if (targetEvent == null || targetEvent.id == null) {

        if (context.mounted) {
          _showSnackBar(context, 'Event not found in Google Calendar');
        }
        return false;
      }
      
      // Delete the event using the new method
      final success = await GoogleCalendarService.deleteEvent(eventId: targetEvent.id!);
      
      if (success) {

        if (context.mounted) {
          _showSnackBar(context, 'Event deleted from Google Calendar');
        }
        return true;
      } else {

        return false;
      }
      
    } catch (e) {

      return false;
    }
  }

  /// Update an existing event in Google Calendar
  static Future<bool> updateEventInCalendar({
    required BuildContext context,
    required String oldTitle,
    required String newTitle,
    required DateTime newStartTime,
    required DateTime newEndTime,
    String? newDescription,
    DateTime? oldEventStartTime,
  }) async {
    try {
      // Check if we're signed in
      final isSignedIn = await GoogleCalendarService.isSignedIn();
      if (!isSignedIn) {

        return false;
      }
      
      // First, find the event by searching for it
      final events = await GoogleCalendarService.listEvents(
        startTime: DateTime.now().subtract(const Duration(days: 30)),
        endTime: DateTime.now().add(const Duration(days: 30)),
      );
      
      // Find the event with matching title
      cal.Event? targetEvent;
      for (final event in events) {
        if (event.summary == oldTitle) {
          // If start time is provided, match by title and date (more reliable than exact time)
          if (oldEventStartTime != null) {
            final eventStart = event.start?.dateTime ?? event.start?.date;
            if (eventStart != null && _isSameDate(eventStart, oldEventStartTime)) {
              targetEvent = event;
              break;
            }
          } else {
            targetEvent = event;
            break;
          }
        }
      }
      
      if (targetEvent == null || targetEvent.id == null) {

        if (context.mounted) {
          _showSnackBar(context, 'Event not found in Google Calendar');
        }
        return false;
      }
      
      // Update the event properties
      targetEvent.summary = newTitle;
      targetEvent.description = newDescription;
      
      // Update start time
      final startEventDateTime = cal.EventDateTime();
      startEventDateTime.dateTime = newStartTime;
      startEventDateTime.timeZone = 'Europe/Dublin';
      targetEvent.start = startEventDateTime;
      
      // Update end time
      final endEventDateTime = cal.EventDateTime();
      endEventDateTime.dateTime = newEndTime;
      endEventDateTime.timeZone = 'Europe/Dublin';
      targetEvent.end = endEventDateTime;
      
      // Set color based on shift type
      targetEvent.colorId = _getColorIdForShift(newTitle);
      
      // Update the event using the new method
      final updatedEvent = await GoogleCalendarService.updateEvent(
        eventId: targetEvent.id!,
        event: targetEvent,
      );
      
      if (updatedEvent != null) {

        if (context.mounted) {
          _showSnackBar(context, 'Event updated in Google Calendar');
        }
        return true;
      } else {

        return false;
      }
      
    } catch (e) {

      return false;
    }
  }

  /// Sync all local shift events to Google Calendar
  static Future<bool> syncAllEventsToCalendar({
    required BuildContext context,
    required List<Map<String, dynamic>> shiftEvents,
  }) async {
    try {
      int successCount = 0;
      int totalCount = shiftEvents.length;
      
      for (final shiftEvent in shiftEvents) {
        // Check if context is still valid before processing each event
        if (!context.mounted) break;
        
        final title = shiftEvent['title'] as String? ?? 'Work Shift';
        final startTime = shiftEvent['startTime'] as DateTime? ?? DateTime.now();
        final endTime = shiftEvent['endTime'] as DateTime? ?? DateTime.now().add(const Duration(hours: 8));
        final description = shiftEvent['description'] as String?;
        
        final success = await addWorkShiftToCalendar(
          context: context,
          title: title,
          startTime: startTime,
          endTime: endTime,
          description: description,
        );
        
        if (success) {
          successCount++;
        }
        
        // Small delay to avoid hitting rate limits
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      if (context.mounted) {
        _showSnackBar(
          context,
          'Synced $successCount of $totalCount events to Google Calendar',
        );
      }
      
      return successCount == totalCount;
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, 'Error syncing events: $e');
      }
      return false;
    }
  }

  /// Get available calendars
  static Future<List<cal.CalendarListEntry>> getAvailableCalendars(BuildContext context) async {
    try {
      // Check if signed in
      final isSignedIn = await GoogleCalendarService.isSignedIn();
      if (!isSignedIn) {
        if (context.mounted) {
          _showSnackBar(context, 'Error: Please sign in to Google Calendar first');
        }
        return [];
      }

      // Use the new getCalendars method
      return await GoogleCalendarService.getCalendars();
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, 'Error getting calendars: $e');
      }
      return [];
    }
  }

  /// Test connection to Google Calendar
  static Future<bool> testCalendarConnection(BuildContext context) async {
    try {

      
      // Check if signed in
      final isSignedIn = await GoogleCalendarService.isSignedIn();
      if (!isSignedIn) {
        if (context.mounted) {
          _showSnackBar(context, 'Error: Please sign in to Google Calendar first');
        }
        return false;
      }

      // Use the new testConnection method
      final hasConnection = await GoogleCalendarService.testConnection();
      
      if (context.mounted) {
        if (hasConnection) {
          _showSnackBar(context, 'Google Calendar connection successful!');
        } else {
          _showSnackBar(context, 'Google Calendar connection failed');
        }
      }
      
      return hasConnection;
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, 'Error testing connection: $e');
      }
      return false;
    }
  }

  /// Helper function to show SnackBar messages
  static void _showSnackBar(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
  
  /// Get color ID for different shift types
  static String _getColorIdForShift(String title) {
    if (title.contains('PZ1') || title.contains('Zone 1')) {
      return '7'; // Blue
    } else if (title.contains('PZ2') || title.contains('Zone 2')) {
      return '10'; // Green
    } else if (title.contains('PZ3') || title.contains('Zone 3')) {
      return '6'; // Orange
    } else if (title.contains('PZ4') || title.contains('Zone 4')) {
      return '4'; // Red
    } else if (title.contains('Spare')) {
      return '8'; // Gray
    } else {
      return '1'; // Default lavender
    }
  }
  
  /// Helper to check if two DateTime objects represent the same time (within 1 minute)
  static bool _isSameDateTime(DateTime dt1, DateTime dt2) {
    final difference = dt1.difference(dt2).abs();
    return difference.inMinutes <= 1;
  }

  /// Helper to check if two DateTime objects represent the same date (ignoring time)
  static bool _isSameDate(DateTime dt1, DateTime dt2) {
    return dt1.year == dt2.year &&
           dt1.month == dt2.month &&
           dt1.day == dt2.day;
  }

  /// Add a holiday to Google Calendar
  static Future<bool> addHolidayToCalendar(Holiday holiday, {BuildContext? context}) async {
    try {
      // Get holiday name based on type
      final holidayName = _getHolidayDisplayName(holiday);

      
      // Check if signed in
      final isSignedIn = await GoogleCalendarService.isSignedIn();
      if (!isSignedIn) {
        if (context != null && context.mounted) {
          _showSnackBar(context, 'Please sign in to Google Calendar first');
        }
        return false;
      }
      
      // Test connection
      final hasConnection = await GoogleCalendarService.testConnection();
      if (!hasConnection) {
        if (context != null && context.mounted) {
          _showSnackBar(context, 'Failed to authenticate with Google');
        }
        return false;
      }
      
      // Create holiday event
      final event = cal.Event();
      event.summary = holidayName;
      event.description = '$_holidayIdPrefix${holiday.id}\n\n${holiday.type.toUpperCase()} Holiday';
      
      // Set as all-day event
      final eventDate = cal.EventDateTime();
      eventDate.date = holiday.startDate;
      event.start = eventDate;
      event.end = eventDate;
      
      // Set holiday color (teal)
      event.colorId = _holidayColorId;
      
      // Disable notifications for holidays
      final reminders = cal.EventReminders();
      reminders.useDefault = false;
      reminders.overrides = [];
      event.reminders = reminders;
      
      // Create the event
      final createdEvent = await GoogleCalendarService.createEvent(event: event);
      
      if (createdEvent != null) {

        if (context != null && context.mounted) {
          _showSnackBar(context, 'Holiday added to Google Calendar');
        }
        return true;
      } else {

        return false;
      }
      
    } catch (e) {

      if (context != null && context.mounted) {
        _showSnackBar(context, 'Error adding holiday: $e');
      }
      return false;
    }
  }

  /// Delete a holiday from Google Calendar
  static Future<bool> deleteHolidayFromCalendar(Holiday holiday, {BuildContext? context}) async {
    try {
      final holidayName = _getHolidayDisplayName(holiday);

      
      // Check if signed in
      final isSignedIn = await GoogleCalendarService.isSignedIn();
      if (!isSignedIn) {

        return false;
      }
      
      // Search for the holiday event by name and date
      final events = await GoogleCalendarService.listEvents(
        startTime: holiday.startDate.subtract(const Duration(days: 1)),
        endTime: holiday.startDate.add(const Duration(days: 1)),
      );
      
      // Find the holiday event
      cal.Event? targetEvent;
      for (final event in events) {
        if (event.summary == holidayName && 
            event.description != null && 
            event.description!.contains('$_holidayIdPrefix${holiday.id}')) {
          targetEvent = event;
          break;
        }
      }
      
      if (targetEvent == null || targetEvent.id == null) {

        if (context != null && context.mounted) {
          _showSnackBar(context, 'Holiday not found in Google Calendar');
        }
        return false;
      }
      
      // Delete the event
      final success = await GoogleCalendarService.deleteEvent(eventId: targetEvent.id!);
      
      if (success) {

        if (context != null && context.mounted) {
          _showSnackBar(context, 'Holiday deleted from Google Calendar');
        }
        return true;
      } else {

        return false;
      }
      
    } catch (e) {

      if (context != null && context.mounted) {
        _showSnackBar(context, 'Error deleting holiday: $e');
      }
      return false;
    }
  }

  /// Check calendar sync status
  static Future<Map<String, dynamic>> checkCalendarSyncStatus({BuildContext? context}) async {
    try {

      
      // Check if signed in
      final isSignedIn = await GoogleCalendarService.isSignedIn();
      if (!isSignedIn) {

        return {
          'error': 'Not signed in to Google Calendar',
          'totalLocalEvents': 0,
          'matchedEvents': 0,
          'missingEvents': 0,
          'missingSyncEvents': <Map<String, dynamic>>[],
        };
      }
      
      // Test connection
      final hasConnection = await GoogleCalendarService.testConnection();
      if (!hasConnection) {

        return {
          'error': 'Failed to connect to Google Calendar',
          'totalLocalEvents': 0,
          'matchedEvents': 0,
          'missingEvents': 0,
          'missingSyncEvents': <Map<String, dynamic>>[],
        };
      }
      
      // Get local events from the last 30 days and next 30 days
      final now = DateTime.now();
      final startDate = now.subtract(const Duration(days: 30));
      final endDate = now.add(const Duration(days: 30));
      

      
      // Get Google Calendar events

      final googleEvents = await GoogleCalendarService.listEvents(
        startTime: startDate,
        endTime: endDate,
      );

      
      // Get local events using EventService

      final localEvents = _getEventsInRange(startDate, endDate);

      // Compare and find missing events
      final missingSyncEvents = <Map<String, dynamic>>[];
      int matchedCount = 0;
      
      for (final localEvent in localEvents) {
        final matchingGoogleEvent = googleEvents.where((gEvent) {
          return gEvent.summary == localEvent.title &&
                 gEvent.start?.dateTime != null &&
                 _isSameDateTime(gEvent.start!.dateTime!, localEvent.fullStartDateTime);
        }).isNotEmpty;
        
        if (matchingGoogleEvent) {
          matchedCount++;
        } else {
          missingSyncEvents.add({
            'title': localEvent.title,
            'startTime': localEvent.fullStartDateTime,
            'endTime': localEvent.fullEndDateTime,
            'description': '', // Can add description if needed
          });
        }
      }
      

      
      return {
        'totalLocalEvents': localEvents.length,
        'matchedEvents': matchedCount,
        'missingEvents': missingSyncEvents.length,
        'missingSyncEvents': missingSyncEvents,
      };
      
    } catch (e) {

      return {
        'error': 'Error checking sync status: $e',
        'totalLocalEvents': 0,
        'matchedEvents': 0,
        'missingEvents': 0,
        'missingSyncEvents': <Map<String, dynamic>>[],
      };
    }
  }

  /// Sync missing events to Google Calendar
  static Future<Map<String, dynamic>> syncMissingEventsToGoogleCalendar(BuildContext context) async {
    try {
      // First get the sync status to find missing events
      final syncStatus = await checkCalendarSyncStatus(context: context);
      final missingSyncEvents = syncStatus['missingSyncEvents'] as List<Map<String, dynamic>>? ?? [];
      
      int successCount = 0;
      
      for (final eventData in missingSyncEvents) {
        final eventTitle = eventData['title'] as String? ?? 'Work Shift';
        
        final success = await addWorkShiftToCalendar(
          context: context,
          title: eventTitle,
          startTime: eventData['startTime'] as DateTime? ?? DateTime.now(),
          endTime: eventData['endTime'] as DateTime? ?? DateTime.now().add(const Duration(hours: 8)),
          description: eventData['description'] as String?,
          showUIFeedback: false,  // Don't show individual feedback during bulk sync
        );
        
        if (success) {
          successCount++;
        }
        
        // Small delay to avoid hitting rate limits
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      // Only show UI feedback if context is still valid
      if (context.mounted) {
        _showSnackBar(
          context,
          'Synced $successCount of ${missingSyncEvents.length} events to Google Calendar',
        );
      }
      
      return {
        'syncedCount': successCount,
        'updatedCount': 0, // For now, we're only syncing new events
        'totalProcessed': missingSyncEvents.length,
      };
      
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, 'Error syncing events: $e');
      }
      return {
        'syncedCount': 0,
        'updatedCount': 0,
        'totalProcessed': 0,
        'error': e.toString(),
      };
    }
  }

  /// Add a test event (alias for createTestEvent for backwards compatibility)
  static Future<bool> addTestEvent(BuildContext context) async {
    return await createTestEvent(context);
  }

  /// Get holiday display name based on type
  static String _getHolidayDisplayName(Holiday holiday) {
    switch (holiday.type.toLowerCase()) {
      case 'winter':
        return 'Winter Holiday';
      case 'summer':
        return 'Summer Holiday';
      case 'unpaid_leave':
        return 'Unpaid Leave';
      case 'day_in_lieu':
        return 'Day In Lieu';
      case 'other':
        return 'Holiday';
      default:
        return 'Holiday';
    }
  }

  /// Get events in a date range from local storage
  static List<Event> _getEventsInRange(DateTime startDate, DateTime endDate) {
    final Map<String, Event> uniqueEvents = {}; // Use Map to deduplicate by event ID
    
    // Iterate through each day in the range
    for (DateTime date = startDate; 
         date.isBefore(endDate.add(const Duration(days: 1))); 
         date = date.add(const Duration(days: 1))) {
      
      // Get events for this day using EventService
      final dayEvents = EventService.getEventsForDay(date);
      
      // Add work shifts only (filter out holidays and other non-work events)
      for (final event in dayEvents) {
        if (event.isWorkShift) {
          // Use event ID as key to prevent duplicates
          // This ensures shifts spanning midnight are only included once
          uniqueEvents[event.id] = event;
        }
      }
    }
    
    // Return list of unique events
    return uniqueEvents.values.toList();
  }
}
