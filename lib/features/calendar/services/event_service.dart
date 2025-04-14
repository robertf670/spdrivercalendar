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
  // In-memory events cache with month-based loading
  static Map<DateTime, List<Event>> _events = {};
  static Map<String, List<Event>> _monthlyCache = {};
  static DateTime? _lastLoadedMonth;
  
  // ADD STATIC GETTER for all loaded events
  static Map<DateTime, List<Event>> get allLoadedEvents => Map.unmodifiable(_events);
  
  // Load events for a specific month
  static Future<List<Event>> _loadEventsForMonth(DateTime month) async {
    final monthKey = '${month.year}-${month.month}';
    
    // Check if we already have this month in cache
    if (_monthlyCache.containsKey(monthKey)) {
      return _monthlyCache[monthKey]!;
    }
    
    final prefs = await SharedPreferences.getInstance();
    final eventsJson = prefs.getString(AppConstants.eventsStorageKey);
    
    if (eventsJson == null || eventsJson.isEmpty) {
      _monthlyCache[monthKey] = [];
      return [];
    }
    
    try {
      final Map<String, dynamic> decodedData = jsonDecode(eventsJson);
      List<Event> monthEvents = [];
      
      decodedData.forEach((dateStr, eventsList) {
        final date = DateTime.parse(dateStr);
        if (date.year == month.year && date.month == month.month) {
          final List<dynamic> eventsData = eventsList;
          monthEvents.addAll(eventsData.map((eventData) => Event.fromMap(eventData)));
        }
      });
      
      _monthlyCache[monthKey] = monthEvents;
      return monthEvents;
    } catch (e) {
      print('Error loading events for month: $e');
      _monthlyCache[monthKey] = [];
      return [];
    }
  }
  
  // Get events for a specific date (maintains same interface)
  static List<Event> getEventsForDay(DateTime day) {
    // Normalize date to remove time component for lookup
    final normalizedDate = DateTime(day.year, day.month, day.day);
    
    // If we don't have this date's events, load the month
    if (!_events.containsKey(normalizedDate)) {
      _loadEventsForMonth(normalizedDate).then((monthEvents) {
        // Update the events map with the loaded month's events
        for (var event in monthEvents) {
          final eventDate = DateTime(event.startDate.year, event.startDate.month, event.startDate.day);
          if (!_events.containsKey(eventDate)) {
            _events[eventDate] = [];
          }
          if (!_events[eventDate]!.any((e) => e.id == event.id)) {
            _events[eventDate]!.add(event);
          }
        }
      });
    }
    
    return _events[normalizedDate] ?? [];
  }
  
  // Preload events for a month (to be called when calendar page changes)
  static Future<void> preloadMonth(DateTime month) async {
    if (_lastLoadedMonth != null && 
        _lastLoadedMonth!.year == month.year && 
        _lastLoadedMonth!.month == month.month) {
      return; // Already loaded
    }
    
    await _loadEventsForMonth(month);
    _lastLoadedMonth = month;
  }
  
  // Clear old cache entries to manage memory
  static void clearOldCache() {
    final now = DateTime.now();
    final threeMonthsAgo = DateTime(now.year, now.month - 3, 1);
    
    _monthlyCache.removeWhere((key, _) {
      final parts = key.split('-');
      final monthDate = DateTime(int.parse(parts[0]), int.parse(parts[1]), 1);
      return monthDate.isBefore(threeMonthsAgo);
    });
  }
  
  // Add a new event (maintains same interface)
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
        _events[normalizedEndDate]!.add(eventWithId);
      }
    }

    // Update monthly cache
    final monthKey = '${normalizedStartDate.year}-${normalizedStartDate.month}';
    if (!_monthlyCache.containsKey(monthKey)) {
      _monthlyCache[monthKey] = [];
    }
    if (!_monthlyCache[monthKey]!.any((e) => e.id == eventWithId.id)) {
      _monthlyCache[monthKey]!.add(eventWithId);
    }

    // Schedule notification if needed
    if (eventWithId.isWorkShift) {
      await _scheduleWorkShiftNotification(eventWithId);
    }

    await _saveEvents();
  }
  
  // Update an existing event (maintains same interface)
  static Future<void> updateEvent(Event oldEvent, Event newEvent) async {
    // Ensure new event has an ID, preferably the same as the old one
    final eventId = oldEvent.id ?? newEvent.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    final newEventWithId = newEvent.copyWith(id: eventId);

    // --- Find and Update Logic ---
    bool eventFoundAndUpdated = false;

    // Normalize dates for searching in the cache
    final normalizedOldStartDate = DateTime(oldEvent.startDate.year, oldEvent.startDate.month, oldEvent.startDate.day);
    final normalizedOldEndDate = DateTime(oldEvent.endDate.year, oldEvent.endDate.month, oldEvent.endDate.day);
    final normalizedNewStartDate = DateTime(newEventWithId.startDate.year, newEventWithId.startDate.month, newEventWithId.startDate.day);
    final normalizedNewEndDate = DateTime(newEventWithId.endDate.year, newEventWithId.endDate.month, newEventWithId.endDate.day);

    // 1. Remove the old event reference(s) from its original date(s)
    // Check start date
    if (_events[normalizedOldStartDate] != null) {
      final index = _events[normalizedOldStartDate]!.indexWhere((e) => e.id == eventId);
      if (index != -1) {
        _events[normalizedOldStartDate]!.removeAt(index);
        if (_events[normalizedOldStartDate]!.isEmpty) {
           _events.remove(normalizedOldStartDate);
        }
      }
    }
    // Check end date (if different from start date)
    if (oldEvent.startDate != oldEvent.endDate && _events[normalizedOldEndDate] != null) {
       final index = _events[normalizedOldEndDate]!.indexWhere((e) => e.id == eventId);
       if (index != -1) {
         _events[normalizedOldEndDate]!.removeAt(index);
         if (_events[normalizedOldEndDate]!.isEmpty) {
           _events.remove(normalizedOldEndDate);
         }
       }
    }
    
    // 2. Add the updated event reference(s) to its new date(s)
    // Add to new start date
    if (_events[normalizedNewStartDate] == null) {
       _events[normalizedNewStartDate] = [];
    }
    // Avoid adding duplicates if date hasn't changed and somehow it wasn't removed
    if (!_events[normalizedNewStartDate]!.any((e) => e.id == eventId)) {
       _events[normalizedNewStartDate]!.add(newEventWithId);
       eventFoundAndUpdated = true; // Mark as found/updated
    }

    // Add to new end date (if different from start date)
    if (newEventWithId.startDate != newEventWithId.endDate) {
       if (_events[normalizedNewEndDate] == null) {
         _events[normalizedNewEndDate] = [];
       }
       // Avoid adding duplicates
       if (!_events[normalizedNewEndDate]!.any((e) => e.id == eventId)) {
          _events[normalizedNewEndDate]!.add(newEventWithId);
          eventFoundAndUpdated = true; // Mark as found/updated
       }
    }

    // --- Handle Notifications ---
    // Only reschedule if the event was actually found and potentially modified
    if (eventFoundAndUpdated) {
      // Cancel old notification if applicable
      if (oldEvent.isWorkShift) {
        await _cancelWorkShiftNotification(oldEvent);
      }
      // Schedule new notification if applicable
      if (newEventWithId.isWorkShift) {
        await _scheduleWorkShiftNotification(newEventWithId);
      }
    } else {
        print("Warning: Event with ID $eventId not found in cache during update. Attempting to add as new.");
        // Fallback: If we couldn't find the event to update (edge case), treat it as adding a new one.
        // This might happen if the cache wasn't loaded correctly or the oldEvent data was stale.
        await addEvent(newEventWithId); // Use addEvent logic which includes saving
        return; // Exit early as addEvent handles saving
    }
    
    // 3. Save the updated cache
    await _saveEvents();
  }
  
  // Delete an event (maintains same interface)
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

    // --- Update Monthly Cache ---
    final monthKey = '${normalizedStartDate.year}-${normalizedStartDate.month}';
    if (_monthlyCache.containsKey(monthKey)) {
      _monthlyCache[monthKey]!.removeWhere((e) => e.id == event.id);
      // Optional: Remove month key if list becomes empty
      // if (_monthlyCache[monthKey]!.isEmpty) {
      //   _monthlyCache.remove(monthKey);
      // }
    }
    // Also check end date month if different
    if (event.startDate != event.endDate) {
      final endMonthKey = '${event.endDate.year}-${event.endDate.month}';
      if (monthKey != endMonthKey && _monthlyCache.containsKey(endMonthKey)) {
         _monthlyCache[endMonthKey]!.removeWhere((e) => e.id == event.id);
         // Optional: Remove key if list becomes empty
      }
    }
    // --- End Update Monthly Cache ---

    await _saveEvents();
  }
  
  // Save events to storage (maintains same interface)
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

  // Get all events with notes (for the notes screen)
  static Future<List<Event>> getAllEventsWithNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final eventsJson = prefs.getString(AppConstants.eventsStorageKey);
    
    if (eventsJson == null || eventsJson.isEmpty) {
      return [];
    }
    
    try {
      final Map<String, dynamic> decodedData = jsonDecode(eventsJson);
      List<Event> allEvents = [];
      
      decodedData.forEach((dateStr, eventsList) {
        final List<dynamic> eventsData = eventsList;
        allEvents.addAll(eventsData.map((eventData) => Event.fromMap(eventData)));
      });
      
      // Filter for events with notes and sort by date
      return allEvents
        .where((event) => event.notes != null && event.notes!.trim().isNotEmpty)
        .toList()
        ..sort((a, b) => b.startDate.compareTo(a.startDate));
    } catch (e) {
      print('Error loading all events with notes: $e');
      return [];
    }
  }
}

