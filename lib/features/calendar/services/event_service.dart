import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spdrivercalendar/core/constants/app_constants.dart';
import 'package:spdrivercalendar/models/event.dart';
import 'package:spdrivercalendar/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:spdrivercalendar/features/settings/screens/settings_screen.dart';

class EventService {
  // In-memory events cache
  static Map<DateTime, List<Event>> _events = {};
  
  // Load events from storage
  static Future<Map<DateTime, List<Event>>> loadEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final eventsJson = prefs.getString(AppConstants.eventsStorageKey);
    
    if (eventsJson == null || eventsJson.isEmpty) {
      _events = {};
      return _events;
    }
    
    try {
      final Map<String, dynamic> decodedData = jsonDecode(eventsJson);
      
      Map<DateTime, List<Event>> loadedEvents = {};
      
      decodedData.forEach((dateStr, eventsList) {
        final date = DateTime.parse(dateStr);
        final List<dynamic> eventsData = eventsList;
        
        loadedEvents[date] = eventsData
            .map((eventData) => Event.fromMap(eventData))
            .toList();
      });
      
      _events = loadedEvents;
      return _events;
    } catch (e) {
      print('Error loading events: $e');
      _events = {};
      return _events;
    }
  }
  
  // Get events (from cache or storage)
  static Future<Map<DateTime, List<Event>>> getEvents() async {
    if (_events.isEmpty) {
      return await loadEvents();
    }
    return _events;
  }
  
  // Get events for a specific date
  static List<Event> getEventsForDay(DateTime day) {
    // Normalize date to remove time component for lookup
    final normalizedDate = DateTime(day.year, day.month, day.day);
    
    return _events[normalizedDate] ?? [];
  }
  
  // Add a new event
  static Future<void> addEvent(Event event) async {
    // Ensure event has an ID
    final eventWithId = event.id == null ? event.copyWith(id: DateTime.now().millisecondsSinceEpoch.toString()) : event;

    final normalizedStartDate = DateTime(
      eventWithId.startDate.year, eventWithId.startDate.month, eventWithId.startDate.day
    );

    if (_events[normalizedStartDate] == null) {
      _events[normalizedStartDate] = [];
    }

    // Make sure we're not adding a duplicate (check by ID)
    if (!_events[normalizedStartDate]!.any((e) => e.id == eventWithId.id)) {
      _events[normalizedStartDate]!.add(eventWithId);
    }

    // If event spans multiple days, add reference to end date as well
    if (eventWithId.startDate != eventWithId.endDate) {
      final normalizedEndDate = DateTime(
        eventWithId.endDate.year, eventWithId.endDate.month, eventWithId.endDate.day
      );

      if (_events[normalizedEndDate] == null) {
        _events[normalizedEndDate] = [];
      }

      if (!_events[normalizedEndDate]!.any((e) => e.id == eventWithId.id)) {
        // Store the same event instance
        _events[normalizedEndDate]!.add(eventWithId);
      }
    }

    // --- Schedule Notification --- 
    if (eventWithId.isWorkShift) {
      await _scheduleWorkShiftNotification(eventWithId);
    }
    // --- End Schedule Notification ---

    await _saveEvents();
    
    // Return
    return;
  }
  
  // Update an existing event
  static Future<void> updateEvent(Event oldEvent, Event newEvent) async {
    // Ensure new event has an ID, preferably the same as the old one
    final newEventWithId = newEvent.copyWith(id: oldEvent.id ?? newEvent.id ?? DateTime.now().millisecondsSinceEpoch.toString());

    // First delete the old event (this will also cancel its notification)
    await deleteEvent(oldEvent);
    
    // Then add the new event (this will schedule its notification)
    await addEvent(newEventWithId);
  }
  
  // Delete an event
  static Future<void> deleteEvent(Event event) async {
    // --- Cancel Notification --- 
    if (event.isWorkShift) {
      await _cancelWorkShiftNotification(event);
    }
    // --- End Cancel Notification ---

    final normalizedStartDate = DateTime(
      event.startDate.year, event.startDate.month, event.startDate.day
    );

    if (_events[normalizedStartDate] != null) {
      _events[normalizedStartDate]!.removeWhere((e) => e.id == event.id);
      if (_events[normalizedStartDate]!.isEmpty) {
        _events.remove(normalizedStartDate);
      }
    }

    // Remove reference from end date if it spans multiple days
    if (event.startDate != event.endDate) {
      final normalizedEndDate = DateTime(
        event.endDate.year, event.endDate.month, event.endDate.day
      );

      if (_events[normalizedEndDate] != null) {
        _events[normalizedEndDate]!.removeWhere((e) => e.id == event.id);
         if (_events[normalizedEndDate]!.isEmpty) {
           _events.remove(normalizedEndDate);
         }
      }
    }

    await _saveEvents();
  }
  
  // Save events to storage
  static Future<void> _saveEvents() async {
    final prefs = await SharedPreferences.getInstance();
    
    Map<String, List<Map<String, dynamic>>> encodedEvents = {};
    
    _events.forEach((date, eventsList) {
      final dateStr = date.toIso8601String();
      // Ensure we only save unique events based on ID
      final uniqueEvents = <String, Event>{};
      for (var event in eventsList) {
         uniqueEvents[event.id] = event;
            }
      encodedEvents[dateStr] = uniqueEvents.values
          .map((event) => event.toMap())
          .toList();
    });
    
    await prefs.setString(AppConstants.eventsStorageKey, jsonEncode(encodedEvents));
  }

  // --- Notification Helper Methods ---

  static Future<void> _scheduleWorkShiftNotification(Event event) async {
    print("[Notif Debug] _scheduleWorkShiftNotification called for event ID: ${event.id}");
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool notificationsEnabled = prefs.getBool(kNotificationsEnabledKey) ?? false;
      print("[Notif Debug] Notifications Enabled (from prefs): $notificationsEnabled");
      
      if (!notificationsEnabled) {
        print("[Notif Debug] Exiting scheduling: Notifications disabled or event ID is null.");
        return; // Don't schedule if disabled or event has no ID
      }

      final int offsetHours = prefs.getInt(kNotificationOffsetHoursKey) ?? 1;
      
      // Combine date and time for the report time
      final DateTime reportDateTime = DateTime(
        event.startDate.year,
        event.startDate.month,
        event.startDate.day,
        event.startTime.hour,
        event.startTime.minute,
      );

      final DateTime scheduledDateTime = reportDateTime.subtract(Duration(hours: offsetHours));
      print("[Notif Debug] Calculated Schedule Time: ${scheduledDateTime.toIso8601String()}");

      // Ensure notification time is in the future
      if (scheduledDateTime.isBefore(DateTime.now())) {
          print("[Notif Debug] Notification time ${scheduledDateTime.toIso8601String()} is in the past. Not scheduling for event ID: ${event.id}.");
          return;
      }

      final int notificationId = event.id.hashCode; // Use hash code of string ID
      const String title = "Upcoming Shift";
      // Format time for the body
      final String reportTimeFormatted = DateFormat('HH:mm').format(reportDateTime);
      final String body = "Report at $reportTimeFormatted for ${event.title}";

      // --- Explicitly check SCHEDULE_EXACT_ALARM permission before scheduling ---
      bool exactAlarmPermGranted = true; // Default to true for non-Android or older versions
      if (defaultTargetPlatform == TargetPlatform.android) {
        print("[Notif Debug - EventService] Checking scheduleExactAlarm status before scheduling for event ID: ${event.id}");
        final status = await Permission.scheduleExactAlarm.status;
        exactAlarmPermGranted = status.isGranted;
        print("[Notif Debug - EventService] scheduleExactAlarm status: ${status.name} for event ID: ${event.id}");
        if (!exactAlarmPermGranted) {
           print("[Notif Debug - EventService] *** EXACT ALARM PERMISSION DENIED *** in EventService check for event ID: ${event.id}. Notification might be delayed or blocked by OS.");
           // Consider adding user feedback here, like a SnackBar
        }
      }
      // --- End permission check ---

      // --- Add specific try-catch for scheduling ---
      try {
        // Only proceed if permission was granted (or not applicable)
        // Note: We still proceed even if denied, as the inner check handles it,
        // but the log above provides context.
        await NotificationService().scheduleNotification(
          id: notificationId,
          title: title,
          body: body,
          scheduledDateTime: scheduledDateTime,
          payload: event.id, // Pass event ID as payload if needed later
        );
        print("[Notif Debug] Successfully CALLED NotificationService.scheduleNotification for event ID: ${event.id} (Notif ID: $notificationId) at $scheduledDateTime");
        
        // --- Check pending notifications immediately after scheduling ---
        try {
          final pending = await NotificationService().getPendingNotifications();
          print("[Notif Debug] Found ${pending.length} pending notifications immediately after scheduling.");
          bool found = false;
          for (var p in pending) {
            print("[Notif Debug] Pending ID: ${p.id}, Title: ${p.title}, Scheduled: [Needs TZDateTime conversion]");
            if (p.id == notificationId) {
              found = true;
              print("[Notif Debug] *** SUCCESS: Newly scheduled notification (ID: $notificationId) IS PENDING in the system! ***");
              break;
            }
          }
          if (!found) {
             print("[Notif Debug] *** WARNING: Newly scheduled notification (ID: $notificationId) was NOT found in pending list immediately after scheduling! ***");
          }
        } catch (e) {
          print("[Notif Debug] Error checking pending notifications: $e");
        }
        // --- End check pending notifications ---

      } catch (e) {
        print("[Notif Debug] *** FAILED TO SCHEDULE *** for event ID: ${event.id} (Notif ID: $notificationId). Error: $e"); // Add error log
      }
      // --- End specific try-catch ---
      
    } catch (e) {
        print("[Notif Debug] Error in _scheduleWorkShiftNotification (outer catch) for event ID: ${event.id}: $e"); // Modify outer catch log
    }
  }

  static Future<void> _cancelWorkShiftNotification(Event event) async {
     try {
        final int notificationId = event.id.hashCode;
        await NotificationService().cancelNotification(notificationId);
        print("Attempted to cancel notification for event ID: ${event.id} (Notif ID: $notificationId)");
     } catch (e) {
        print("Error cancelling notification for event ID: ${event.id}: $e");
     }
  }
}
