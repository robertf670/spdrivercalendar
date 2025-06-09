import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spdrivercalendar/core/constants/app_constants.dart';
import 'package:spdrivercalendar/models/event.dart';
import 'package:spdrivercalendar/services/notification_service.dart';
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
        try {
          final date = DateTime.parse(dateStr);
          if (date.year == month.year && date.month == month.month) {
            final List<dynamic> eventsData = eventsList;
            for (var eventData in eventsData) {
                try {
                    monthEvents.add(Event.fromMap(eventData));
                } catch (e_map) {
                    // Corrected logging for mapping error
                }
            }
          }
        } catch (e_parse) {
          // Corrected logging for parsing error
        }
      });

      _monthlyCache[monthKey] = monthEvents;
      return monthEvents;
    } catch (e) {
      _monthlyCache[monthKey] = [];
      return [];
    }
  }
  
  // Get events for a specific date (maintains same interface)
  static List<Event> getEventsForDay(DateTime day) {
    // Normalize date to remove time component for lookup
    final normalizedDate = DateTime(day.year, day.month, day.day);

    // If we have events for this date, return them immediately
    if (_events.containsKey(normalizedDate)) {
      return _events[normalizedDate]!;
    }

    // Check if month is being loaded or needs to be loaded
    final monthKey = '${day.year}-${day.month}';
    
    // If month is not cached, preload it immediately (this will populate _events)
    if (!_monthlyCache.containsKey(monthKey)) {
      // Use preloadMonth which awaits the loading
      preloadMonth(day).then((_) {
        // Month is now loaded, but we can't return the result here due to async nature
        // The UI will need to call this method again or use a different approach
      }).catchError((error) {

      });
      
      // For immediate return, check if we can populate from already loaded cache
      _populateEventsFromCache(day);
    } else {
      // Month is cached, ensure events are populated in _events map
      _populateEventsFromCache(day);
    }

    // Return whatever we have (might be empty on first call, but populated on subsequent calls)
    return _events[normalizedDate] ?? [];
  }

  // Helper method to populate _events from _monthlyCache
  static void _populateEventsFromCache(DateTime month) {
    final monthKey = '${month.year}-${month.month}';
    
    if (!_monthlyCache.containsKey(monthKey)) {
      return; // No cache available
    }

    final monthEvents = _monthlyCache[monthKey]!;
    
    for (var event in monthEvents) {
      // Add to start date
      final normalizedEventStartDate = DateTime(event.startDate.year, event.startDate.month, event.startDate.day);
      if (!_events.containsKey(normalizedEventStartDate)) {
        _events[normalizedEventStartDate] = [];
      }
      if (!_events[normalizedEventStartDate]!.any((e) => e.id == event.id)) {
        _events[normalizedEventStartDate]!.add(event);
      }

      // If event spans multiple days, add reference to end date as well
      final normalizedEventEndDate = DateTime(event.endDate.year, event.endDate.month, event.endDate.day);
      if (normalizedEventStartDate != normalizedEventEndDate) {
        if (!_events.containsKey(normalizedEventEndDate)) {
          _events[normalizedEventEndDate] = [];
        }
        if (!_events[normalizedEventEndDate]!.any((e) => e.id == event.id)) {
          _events[normalizedEventEndDate]!.add(event);
        }
      }
    }
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
    
    // After loading, populate _events from the monthly cache
    _populateEventsFromCache(month);
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
    final eventWithId = event.id.isEmpty ? event.copyWith(id: DateTime.now().millisecondsSinceEpoch.toString()) : event;

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
    final eventId = oldEvent.id.isNotEmpty ? oldEvent.id : newEvent.id.isNotEmpty ? newEvent.id : DateTime.now().millisecondsSinceEpoch.toString();
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

    try {
      final prefs = await SharedPreferences.getInstance();
      final bool notificationsEnabled = prefs.getBool(kNotificationsEnabledKey) ?? false;

      
      if (!notificationsEnabled) {

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


      // Ensure notification time is in the future
      if (scheduledDateTime.isBefore(DateTime.now())) {

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

        final status = await Permission.scheduleExactAlarm.status;
        exactAlarmPermGranted = status.isGranted;

        if (!exactAlarmPermGranted) {

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

        
        // --- Check pending notifications immediately after scheduling ---
        try {
          final pending = await NotificationService().getPendingNotifications();

          bool found = false;
          for (var p in pending) {

            if (p.id == notificationId) {
              found = true;

              break;
            }
          }
          if (!found) {

          }
        } catch (e) {
          // Failed to get pending notifications, ignore
        }
        // --- End check pending notifications ---

      } catch (e) {
        // Failed to schedule notification, continue silently
      }
      // --- End specific try-catch ---
      
    } catch (e) {
        // Error scheduling work shift notification
    }
  }

  static Future<void> _cancelWorkShiftNotification(Event event) async {
     try {
        final int notificationId = event.id.hashCode;
        await NotificationService().cancelNotification(notificationId);

     } catch (e) {
       // Failed to cancel notification, ignore
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
      // Failed to parse events with notes, return empty list
      return [];
    }
  }

  static Future<void> initializeService() async {
    _events = {}; // Clear existing in-memory events for a fresh load
    _monthlyCache = {}; // Clear monthly cache as well
    _lastLoadedMonth = null;

    final prefs = await SharedPreferences.getInstance();
    final eventsJson = prefs.getString(AppConstants.eventsStorageKey);

    if (eventsJson == null || eventsJson.isEmpty) {

      return; // No events to load
    }

    try {
      final Map<String, dynamic> decodedJson = jsonDecode(eventsJson);
      // decodedJson is Map<String_dateAsISO_for_event_START_DATE, List_of_eventMaps>

      decodedJson.forEach((dateKeyString, eventsListDynamic) {
        if (eventsListDynamic is List) {
          for (var eventDataMap in eventsListDynamic) {
            if (eventDataMap is Map<String, dynamic>) {
              try {
                Event event = Event.fromMap(eventDataMap);

                // Add to _events based on actual event.startDate
                final normalizedEventStartDate = DateTime(event.startDate.year, event.startDate.month, event.startDate.day);
                _events[normalizedEventStartDate] ??= [];
                if (!_events[normalizedEventStartDate]!.any((e) => e.id == event.id)) {
                  _events[normalizedEventStartDate]!.add(event);
                }

                // If event spans multiple days, add reference to _events for endDate as well
                final normalizedEventEndDate = DateTime(event.endDate.year, event.endDate.month, event.endDate.day);
                if (normalizedEventStartDate != normalizedEventEndDate) {
                  _events[normalizedEventEndDate] ??= [];
                  if (!_events[normalizedEventEndDate]!.any((e) => e.id == event.id)) {
                    _events[normalizedEventEndDate]!.add(event);
                  }
                }
              } catch (e) {
                // Failed to parse individual event, skip it
              }
            }
          }
        }
      });
      // Optional: Count and log number of events loaded for verification
      int totalEventsInMap = 0;
      _events.values.forEach((list) => totalEventsInMap += list.length);
      // To avoid counting same event twice if it spans days & is in two lists, count unique IDs
      Set<String> uniqueEventIds = {};
      _events.values.forEach((list) => list.forEach((event) => uniqueEventIds.add(event.id)));


    } catch (e) {

      _events = {}; // Ensure events map is empty on error to avoid partial inconsistent state
    }
  }
}

