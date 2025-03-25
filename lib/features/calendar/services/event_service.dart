import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spdrivercalendar/core/constants/app_constants.dart';
import 'package:spdrivercalendar/models/event.dart';

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
    final normalizedStartDate = DateTime(
      event.startDate.year, event.startDate.month, event.startDate.day
    );

    if (_events[normalizedStartDate] == null) {
      _events[normalizedStartDate] = [];
    }

    // Make sure we're not adding a duplicate
    if (!_events[normalizedStartDate]!.any((e) => e.id == event.id)) {
      _events[normalizedStartDate]!.add(event);
    }

    // If event spans multiple days, add to end date as well
    if (event.startDate != event.endDate) {
      final normalizedEndDate = DateTime(
        event.endDate.year, event.endDate.month, event.endDate.day
      );

      if (_events[normalizedEndDate] == null) {
        _events[normalizedEndDate] = [];
      }

      if (!_events[normalizedEndDate]!.any((e) => e.id == event.id)) {
        _events[normalizedEndDate]!.add(event);
      }
    }

    await _saveEvents();
    
    // Return a copy of the event for UI updates
    return;
  }
  
  // Update an existing event
  static Future<void> updateEvent(Event oldEvent, Event newEvent) async {
    // First delete the old event
    await deleteEvent(oldEvent);
    
    // Then add the new event
    await addEvent(newEvent);
  }
  
  // Delete an event
  static Future<void> deleteEvent(Event event) async {
    final normalizedStartDate = DateTime(
      event.startDate.year, event.startDate.month, event.startDate.day
    );

    if (_events[normalizedStartDate] != null) {
      _events[normalizedStartDate]!.removeWhere((e) => e.id == event.id);
    }

    if (event.startDate != event.endDate) {
      final normalizedEndDate = DateTime(
        event.endDate.year, event.endDate.month, event.endDate.day
      );

      if (_events[normalizedEndDate] != null) {
        _events[normalizedEndDate]!.removeWhere((e) => e.id == event.id);
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
      encodedEvents[dateStr] = eventsList
          .map((event) => event.toMap())
          .toList();
    });
    
    await prefs.setString(AppConstants.eventsStorageKey, jsonEncode(encodedEvents));
  }
}
