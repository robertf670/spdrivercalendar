import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spdrivercalendar/core/constants/app_constants.dart';
import 'package:spdrivercalendar/models/event.dart';
import 'package:spdrivercalendar/services/notification_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:spdrivercalendar/features/settings/screens/settings_screen.dart';

class EventService {
  // In-memory events cache with month-based loading - FIXED: Use string-based date keys
  static Map<String, List<Event>> _events = {};
  static Map<String, List<Event>> _monthlyCache = {};
  static DateTime? _lastLoadedMonth;
  
  // Cache for user preferences
  static bool _showOvernightDutiesOnBothDays = true; // Default to true
  static bool _preferencesLoaded = false;
  
  // ADD STATIC GETTER for all loaded events - FIXED: Convert to string keys
  static Map<String, List<Event>> get allLoadedEvents => Map.unmodifiable(_events);
  
  // Add save operation synchronization
  static bool _isSaving = false;
  static final List<Function> _pendingSaveQueue = [];
  
  // Add data validation and backup mechanisms
  static const int _maxBackupRetries = 3;
  static const String _backupSuffix = '_backup';
  
  // ADDED: Helper method to normalize date to string key
  static String _dateToKey(DateTime date) {
    return DateTime(date.year, date.month, date.day).toIso8601String();
  }
  
  // Enhanced error logging
  static void _logError(String operation, dynamic error, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('EventService Error [$operation]: $error');
      if (stackTrace != null) {
        print('Stack trace: $stackTrace');
      }
    }
  }
  
  // Load user preferences
  static Future<void> _loadPreferences() async {
    if (_preferencesLoaded) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      _showOvernightDutiesOnBothDays = prefs.getBool(AppConstants.showOvernightDutiesOnBothDaysKey) ?? true;
      _preferencesLoaded = true;
    } catch (e) {
      _logError('_loadPreferences', 'Failed to load preferences: $e');
      _showOvernightDutiesOnBothDays = true; // Default to true on error
      _preferencesLoaded = true;
    }
  }
  
  // Update the cached preference (call this when user changes the setting)
  static void updateOvernightDutiesPreference(bool showOnBothDays) {
    _showOvernightDutiesOnBothDays = showOnBothDays;
  }
  
  // Data validation method
  static bool _validateEventData(Map<String, dynamic> data) {
    try {
      // Check required fields
      if (data['id'] == null || data['title'] == null || 
          data['startDate'] == null || data['endDate'] == null) {
        return false;
      }
      
      // Validate date formats
      DateTime.parse(data['startDate']);
      DateTime.parse(data['endDate']);
      
      // Validate time objects
      if (data['startTime'] != null) {
        final startTime = data['startTime'];
        if (startTime['hour'] == null || startTime['minute'] == null) {
          return false;
        }
      }
      
      return true;
    } catch (e) {
      _logError('validateEventData', e);
      return false;
    }
  }
  
  // Create backup of events data
  static Future<void> _createBackup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final originalData = prefs.getString(AppConstants.eventsStorageKey);
      
      if (originalData != null) {
        await prefs.setString(AppConstants.eventsStorageKey + _backupSuffix, originalData);
      }
    } catch (e) {
      _logError('createBackup', e);
    }
  }
  
  // Restore from backup if main data is corrupted
  static Future<bool> _restoreFromBackup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final backupData = prefs.getString(AppConstants.eventsStorageKey + _backupSuffix);
      
      if (backupData != null) {
        // Validate backup data
        final decoded = jsonDecode(backupData);
        if (decoded is Map<String, dynamic>) {
          await prefs.setString(AppConstants.eventsStorageKey, backupData);
          _logError('restoreFromBackup', 'Successfully restored from backup');
          return true;
        }
      }
      return false;
    } catch (e) {
      _logError('restoreFromBackup', e);
      return false;
    }
  }

  // Load events for a specific month
  static Future<List<Event>> _loadEventsForMonth(DateTime month) async {
    final monthKey = '${month.year}-${month.month}';

    if (_monthlyCache.containsKey(monthKey)) {
      return _monthlyCache[monthKey]!;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final eventsJson = prefs.getString(AppConstants.eventsStorageKey);

      if (eventsJson == null || eventsJson.isEmpty) {
        _monthlyCache[monthKey] = [];
        return [];
      }

      final Map<String, dynamic> decodedData = jsonDecode(eventsJson);
      List<Event> monthEvents = [];

      for (final entry in decodedData.entries) {
        try {
          final eventDate = DateTime.parse(entry.key);
          
          // Only load events for the requested month
          if (eventDate.year == month.year && eventDate.month == month.month) {
            final List<dynamic> eventsData = entry.value;
            
            for (final eventData in eventsData) {
              try {
                // DEBUG: Log busAssignments in the JSON data before Event.fromMap
                if (eventData['title'] != null && eventData['title'].toString().startsWith('SP')) {
                  _logError('loadEventsForMonth', '📂 JSON DATA: ${eventData['title']} | busAssignments in JSON: ${eventData['busAssignments']} (${eventData['busAssignments'].runtimeType})');
                }
                
                // Validate event data before creating Event object
                if (_validateEventData(eventData)) {
                  final event = Event.fromMap(eventData);
                  
                  // DEBUG: Log busAssignments after Event.fromMap
                  if (event.title.startsWith('SP')) {
                    _logError('loadEventsForMonth', '📂 AFTER FROMMAP: ${event.title} | busAssignments: ${event.busAssignments} (${event.busAssignments.runtimeType})');
                  }
                  
                  monthEvents.add(event);
                } else {
                  _logError('loadEventsForMonth', 'Invalid event data: $eventData');
                }
              } catch (e) {
                _logError('loadEventsForMonth', 'Error parsing event: $e');
              }
            }
          }
        } catch (e) {
          _logError('loadEventsForMonth', 'Error parsing date key ${entry.key}: $e');
        }
      }

      _monthlyCache[monthKey] = monthEvents;
      return monthEvents;
    } catch (e) {
      _logError('loadEventsForMonth', e);
      
      // Try to restore from backup if main data is corrupted
      if (await _restoreFromBackup()) {
        // Retry loading after restoration
        try {
          return await _loadEventsForMonth(month);
        } catch (retryError) {
          _logError('loadEventsForMonth', 'Failed even after backup restoration: $retryError');
        }
      }
      
      _monthlyCache[monthKey] = [];
      return [];
    }
  }
  
  // Get events for a specific date (maintains same interface)
  static List<Event> getEventsForDay(DateTime day) {
    // Load preferences if not already loaded
    if (!_preferencesLoaded) {
      _loadPreferences(); // Fire and forget - will use default on first call
    }
    
    // Normalize date to remove time component for lookup
    final normalizedDate = DateTime(day.year, day.month, day.day);

    // If we have events for this date, return them with filtering
    if (_events.containsKey(_dateToKey(normalizedDate))) {
      final events = _events[_dateToKey(normalizedDate)]!;
      
      // Filter out events that end on this day if the preference is disabled
      final filteredEvents = <Event>[];
      for (final event in events) {
        final eventStartDate = DateTime(event.startDate.year, event.startDate.month, event.startDate.day);
        final eventEndDate = DateTime(event.endDate.year, event.endDate.month, event.endDate.day);
        
        // If overnight duties should not show on both days, only show on start date
        if (!_showOvernightDutiesOnBothDays && eventStartDate != eventEndDate && eventEndDate == normalizedDate) {
          // Skip this event - it's on the end date and user doesn't want to see it
          continue;
        }
        
        filteredEvents.add(event);
        
        // Focus on spare events with duties for debugging
        if (event.title.startsWith('SP') && event.assignedDuties != null && event.assignedDuties!.isNotEmpty) {
          _logError('getEventsForDay', '📅 DISPLAY: ${event.title} | duties: ${event.assignedDuties} | buses: ${event.busAssignments}');
        }
      }
      
      return filteredEvents;
    }

    // Check if month is being loaded or needs to be loaded
    final monthKey = '${day.year}-${day.month}';
    
    // If month is not cached, preload it immediately (this will populate _events)
    if (!_monthlyCache.containsKey(monthKey)) {
      _logError('getEventsForDay', 'Month $monthKey not cached, preloading...');
      
      // Use preloadMonth which awaits the loading
      preloadMonth(day).then((_) {
        // Month is now loaded, but we can't return the result here due to async nature
        // The UI will need to call this method again or use a different approach
        _logError('getEventsForDay', 'Month $monthKey preloaded successfully');
      }).catchError((error) {
        _logError('getEventsForDay', 'Failed to preload month $monthKey: $error');
      });
      
      // For immediate return, check if we can populate from already loaded cache
      _populateEventsFromCache(day);
    } else {
      // Month is cached, ensure events are populated in _events map
      // _logError('getEventsForDay', 'Month $monthKey is cached, populating events...');
      _populateEventsFromCache(day);
    }

    // Final check after population with filtering
    final rawEvents = _events[_dateToKey(normalizedDate)] ?? [];
    final finalEvents = <Event>[];
    
    // Apply the same filtering logic
    for (final event in rawEvents) {
      final eventStartDate = DateTime(event.startDate.year, event.startDate.month, event.startDate.day);
      final eventEndDate = DateTime(event.endDate.year, event.endDate.month, event.endDate.day);
      
      // If overnight duties should not show on both days, only show on start date
      if (!_showOvernightDutiesOnBothDays && eventStartDate != eventEndDate && eventEndDate == normalizedDate) {
        // Skip this event - it's on the end date and user doesn't want to see it
        continue;
      }
      
      finalEvents.add(event);
    }
    
    _logError('getEventsForDay', 'Returning ${finalEvents.length} events for ${normalizedDate.toIso8601String()}');
    
    // If we still don't have events but the month is cached, check for recovery
    if (finalEvents.isEmpty && _monthlyCache.containsKey(monthKey)) {
      // Perform recovery check asynchronously to not block the UI
      _detectAndRecoverMissingEvents(day).then((recovered) {
        if (recovered) {
          _logError('getEventsForDay', 'Recovery successful for ${normalizedDate.toIso8601String()}');
        }
      }).catchError((error) {
        _logError('getEventsForDay', 'Recovery failed for ${normalizedDate.toIso8601String()}: $error');
      });
    }
    
    // Return whatever we have (might be empty on first call, but populated on subsequent calls)
    return finalEvents;
  }

  // Helper method to populate _events from _monthlyCache
  static void _populateEventsFromCache(DateTime month) {
    final monthKey = '${month.year}-${month.month}';
    
    if (!_monthlyCache.containsKey(monthKey)) {
      _logError('populateEventsFromCache', 'No monthly cache available for $monthKey');
      return; // No cache available
    }

    final monthEvents = _monthlyCache[monthKey]!;
    bool foundStaleCache = false;
    
    for (var event in monthEvents) {
      // Focus on spare events for enhanced stale detection
      if (event.title.startsWith('SP')) {
        
        // Log all spare events for debugging
        _logError('populateEventsFromCache', '📂 LOADING: ${event.title} | duties: ${event.assignedDuties} | buses: ${event.busAssignments}');
        
        // ENHANCED STALE CACHE DETECTION - catch multiple scenarios:
        
        // Scenario 1: Spare event with duties but no bus assignments
        if (event.assignedDuties != null && event.assignedDuties!.isNotEmpty &&
            (event.busAssignments == null || event.busAssignments!.isEmpty)) {
          _logError('populateEventsFromCache', '🚨 STALE CACHE DETECTED (Type 1): ${event.title} has duties ${event.assignedDuties} but no bus assignments');
          foundStaleCache = true;
        }
        
        // Scenario 2: Recently created spare event (based on ID) with no content at all
        // Spare events with high IDs (recent) should typically have some content
        if ((event.assignedDuties == null || event.assignedDuties!.isEmpty) &&
            (event.busAssignments == null || event.busAssignments!.isEmpty)) {
          try {
            final idAsInt = int.parse(event.id);
            if (idAsInt > 1700000000000) { // Recent timestamps (approximately 2023+)
              _logError('populateEventsFromCache', '🚨 STALE CACHE DETECTED (Type 2): ${event.title} is recent but completely empty - likely data loss');
              foundStaleCache = true;
            }
          } catch (e) {
            // If ID is not parseable as int, skip this check
          }
        }
        
        // Scenario 3: Spare event with bus assignments but no duties (data corruption)
        if ((event.assignedDuties == null || event.assignedDuties!.isEmpty) &&
            event.busAssignments != null && event.busAssignments!.isNotEmpty) {
          _logError('populateEventsFromCache', '🚨 STALE CACHE DETECTED (Type 3): ${event.title} has buses ${event.busAssignments} but no duties - data corruption');
          foundStaleCache = true;
        }
      }
      
      // Add to start date
      final normalizedEventStartDate = DateTime(event.startDate.year, event.startDate.month, event.startDate.day);
      
      if (!_events.containsKey(_dateToKey(normalizedEventStartDate))) {
        _events[_dateToKey(normalizedEventStartDate)] = [];
      }
      
      // Replace or add event
      final existingEventIndex = _events[_dateToKey(normalizedEventStartDate)]!.indexWhere((e) => e.id == event.id);
      if (existingEventIndex >= 0) {
        _events[_dateToKey(normalizedEventStartDate)]![existingEventIndex] = event;
      } else {
        _events[_dateToKey(normalizedEventStartDate)]!.add(event);
      }

      // Handle multi-day events
      final normalizedEventEndDate = DateTime(event.endDate.year, event.endDate.month, event.endDate.day);
      if (normalizedEventStartDate != normalizedEventEndDate) {
        if (!_events.containsKey(_dateToKey(normalizedEventEndDate))) {
          _events[_dateToKey(normalizedEventEndDate)] = [];
        }
        
        final endDateExistingIndex = _events[_dateToKey(normalizedEventEndDate)]!.indexWhere((e) => e.id == event.id);
        if (endDateExistingIndex >= 0) {
          _events[_dateToKey(normalizedEventEndDate)]![endDateExistingIndex] = event;
        } else {
          _events[_dateToKey(normalizedEventEndDate)]!.add(event);
        }
      }
    }
    
    // CRITICAL FIX: If stale cache detected, force reload from storage
    if (foundStaleCache) {
      _logError('populateEventsFromCache', '🔄 FORCING STORAGE RELOAD due to stale cache with missing bus assignments');
      _forceReloadFromStorage(month);
    }
  }

  // CRITICAL FIX: Force reload from storage when stale cache is detected
  static Future<void> _forceReloadFromStorage(DateTime month) async {
    _logError('_forceReloadFromStorage', 'Starting forced reload from storage for month: ${month.year}-${month.month}');
    
    try {
      final monthKey = '${month.year}-${month.month}';
      
      // Clear the stale monthly cache
      _monthlyCache.remove(monthKey);
      
      // Clear events for this month from _events
      final keysToRemove = <String>[];
      for (final dateKey in _events.keys) {
        final date = _keyToDate(dateKey);
        if (date.year == month.year && date.month == month.month) {
          keysToRemove.add(dateKey);
        }
      }
      for (final key in keysToRemove) {
        _events.remove(key);
      }
      
      // Reload current month from storage
      await _loadEventsForMonth(month);
      
      // Repopulate events from fresh cache
      final freshMonthEvents = _monthlyCache[monthKey] ?? [];
      for (var event in freshMonthEvents) {
        // Log reloaded spare events
        if (event.title.startsWith('SP') && event.assignedDuties != null && event.assignedDuties!.isNotEmpty) {
          _logError('_forceReloadFromStorage', '✅ RELOADED: ${event.title} | duties: ${event.assignedDuties} | buses: ${event.busAssignments}');
        }
        
        // Add to start date
        final normalizedEventStartDate = DateTime(event.startDate.year, event.startDate.month, event.startDate.day);
        
        if (!_events.containsKey(_dateToKey(normalizedEventStartDate))) {
          _events[_dateToKey(normalizedEventStartDate)] = [];
        }
        
        // Replace or add event
        final existingEventIndex = _events[_dateToKey(normalizedEventStartDate)]!.indexWhere((e) => e.id == event.id);
        if (existingEventIndex >= 0) {
          _events[_dateToKey(normalizedEventStartDate)]![existingEventIndex] = event;
        } else {
          _events[_dateToKey(normalizedEventStartDate)]!.add(event);
        }

        // Handle multi-day events
        final normalizedEventEndDate = DateTime(event.endDate.year, event.endDate.month, event.endDate.day);
        if (normalizedEventStartDate != normalizedEventEndDate) {
          if (!_events.containsKey(_dateToKey(normalizedEventEndDate))) {
            _events[_dateToKey(normalizedEventEndDate)] = [];
          }
          
          final endDateExistingIndex = _events[_dateToKey(normalizedEventEndDate)]!.indexWhere((e) => e.id == event.id);
          if (endDateExistingIndex >= 0) {
            _events[_dateToKey(normalizedEventEndDate)]![endDateExistingIndex] = event;
          } else {
            _events[_dateToKey(normalizedEventEndDate)]!.add(event);
          }
        }
      }
      
      _logError('_forceReloadFromStorage', 'Forced reload completed successfully');
    } catch (e) {
      _logError('_forceReloadFromStorage', 'Error during forced reload: $e');
    }
  }

  // Helper method to convert date key back to DateTime
  static DateTime _keyToDate(String key) {
    try {
      // First try parsing as ISO format (in case we get full datetime strings)
      if (key.contains('T')) {
        return DateTime.parse(key);
      }
      
      // Otherwise parse as simple date format
      final parts = key.split('-');
      if (parts.length >= 3) {
        return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      }
      
      // Fallback - try direct parsing
      return DateTime.parse(key);
    } catch (e) {
      _logError('_keyToDate', 'Failed to parse date key: $key, error: $e');
      // Return current date as fallback
      return DateTime.now();
    }
  }

  // Recovery method to detect and restore missing events
  static Future<bool> _detectAndRecoverMissingEvents(DateTime date) async {
    // _logError('detectAndRecoverMissingEvents', 'Checking for missing events on ${date.toIso8601String()}');
    
    try {
      // Check if we have events in persistent storage that aren't in cache
      final prefs = await SharedPreferences.getInstance();
      final eventsJson = prefs.getString(AppConstants.eventsStorageKey);
      
      if (eventsJson == null || eventsJson.isEmpty) {
        return false;
      }

      final Map<String, dynamic> decodedData = jsonDecode(eventsJson);
      final normalizedDate = DateTime(date.year, date.month, date.day);
      final dateStr = _dateToKey(normalizedDate);
      
      if (decodedData.containsKey(dateStr)) {
        final persistentEvents = decodedData[dateStr] as List<dynamic>;
        final currentEvents = _events[_dateToKey(normalizedDate)] ?? [];
        
        if (persistentEvents.length > currentEvents.length) {
          _logError('detectAndRecoverMissingEvents', 'Found ${persistentEvents.length} events in storage but only ${currentEvents.length} in cache');
          
          // Force reload this month to recover missing events
          await _refreshSpecificMonthCache(date);
          return true;
        }
      }
      
      return false;
    } catch (e) {
      _logError('detectAndRecoverMissingEvents', 'Error during recovery check: $e');
      return false;
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
  
  // Force refresh cache for a specific month (for fixing bus assignment cache issues)
  static Future<void> refreshMonthCache(DateTime date) async {
    final monthKey = '${date.year}-${date.month}';
    
    _logError('refreshMonthCache', 'Refreshing cache for month: $monthKey');
    
    // Remove from monthly cache to force reload
    _monthlyCache.remove(monthKey);
    
          // Clear events for this month from _events cache
      _events.removeWhere((key, _) {
        final keyDate = DateTime.parse(key);
        return keyDate.year == date.year && keyDate.month == date.month;
      });
    
    // Reload the month
    await _loadEventsForMonth(date);
    _populateEventsFromCache(date);
    
    _logError('refreshMonthCache', 'Cache refresh completed for month: $monthKey');
  }

  // Enhanced cache synchronization method
  static Future<void> _synchronizeAllCaches() async {
    _logError('synchronizeAllCaches', 'Starting full cache synchronization');
    
    try {
      // Clear all in-memory caches
      final eventsBackup = Map<String, List<Event>>.from(_events);
      final monthlyBackup = Map<String, List<Event>>.from(_monthlyCache);
      
      _events.clear();
      _monthlyCache.clear();
      
      // Reload from persistent storage
      await initializeService();
      
      _logError('synchronizeAllCaches', 'Cache synchronization completed successfully');
    } catch (e, stackTrace) {
      _logError('synchronizeAllCaches', 'Cache synchronization failed: $e', stackTrace);
      rethrow;
    }
  }

  // Validate cache consistency
  static bool _validateCacheConsistency() {
    try {
      // Check that all events in _events are also in appropriate monthly caches
      for (final dateEntry in _events.entries) {
        final entryDate = DateTime.parse(dateEntry.key);
        final monthKey = '${entryDate.year}-${entryDate.month}';
        
        if (!_monthlyCache.containsKey(monthKey)) {
          _logError('validateCacheConsistency', 'Monthly cache missing for key: $monthKey');
          return false;
        }
        
        for (final event in dateEntry.value) {
          if (!_monthlyCache[monthKey]!.any((e) => e.id == event.id)) {
            _logError('validateCacheConsistency', 'Event ${event.id} missing from monthly cache');
            return false;
          }
        }
      }
      
      _logError('validateCacheConsistency', 'Cache consistency validation passed');
      return true;
    } catch (e) {
      _logError('validateCacheConsistency', 'Cache consistency validation failed: $e');
      return false;
    }
  }

  // Enhanced refresh for specific event (to be called after updates)
  static Future<void> refreshEventInCache(String eventId, DateTime eventDate) async {
    _logError('refreshEventInCache', 'Refreshing event $eventId in cache');
    
    try {
      // First, validate that the event exists in persistent storage
      final eventExists = await _verifyEventInStorage(eventId);
      if (!eventExists) {
        _logError('refreshEventInCache', 'WARNING: Event $eventId not found in persistent storage');
      }
      
      // Only refresh the specific month's cache, not all caches
      await _refreshSpecificMonthCache(eventDate);
      
      // Validate cache consistency after refresh
      if (!_validateCacheConsistency()) {
        _logError('refreshEventInCache', 'Cache inconsistency detected, performing targeted reload');
        await _refreshSpecificMonthCache(eventDate);
      }
      
      _logError('refreshEventInCache', 'Event refresh completed for $eventId');
    } catch (e) {
      _logError('refreshEventInCache', 'Failed to refresh event $eventId: $e');
      rethrow;
    }
  }

  // CRITICAL FIX: Force complete cache synchronization to prevent old cached data from interfering
  static Future<void> forceCacheSynchronization(DateTime eventDate) async {
    _logError('forceCacheSynchronization', 'Starting forced cache synchronization for date: ${eventDate.toIso8601String()}');
    
    try {
      final monthKey = '${eventDate.year}-${eventDate.month}';
      
      // Step 1: Clear ALL cached data for this month to prevent any old data interference
      _monthlyCache.remove(monthKey);
      
      // Step 2: Clear all events for this month from _events cache
      _events.removeWhere((key, _) {
        final keyDate = DateTime.parse(key);
        return keyDate.year == eventDate.year && keyDate.month == eventDate.month;
      });
      
      _logError('forceCacheSynchronization', 'Cleared all cached data for month: $monthKey');
      
      // Step 3: Force reload from persistent storage with a small delay to ensure async operations complete
      await Future.delayed(const Duration(milliseconds: 50));
      
      // Step 4: Reload the month data completely fresh from storage
      await _loadEventsForMonth(eventDate);
      
      _logError('forceCacheSynchronization', 'Reloaded month data from storage');
      
      // Step 5: Populate _events from the fresh monthly cache
      _populateEventsFromCache(eventDate);
      
      _logError('forceCacheSynchronization', 'Populated _events from fresh monthly cache');
      
      // Step 6: Verify the synchronization worked by checking the specific event
      final events = getEventsForDay(eventDate);
      for (final event in events) {
        if (event.title.startsWith('SP') && event.assignedDuties != null && event.assignedDuties!.isNotEmpty) {
          _logError('forceCacheSynchronization', '✅ SYNC VERIFY: ${event.title} | duties: ${event.assignedDuties} | buses: ${event.busAssignments}');
        }
      }
      
      _logError('forceCacheSynchronization', 'Cache synchronization completed successfully');
      
    } catch (e) {
      _logError('forceCacheSynchronization', 'Cache synchronization failed: $e');
      rethrow;
    }
  }

  // Verify that a specific event exists in persistent storage
  static Future<bool> _verifyEventInStorage(String eventId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final eventsJson = prefs.getString(AppConstants.eventsStorageKey);
      
      if (eventsJson == null || eventsJson.isEmpty) {
        return false;
      }

      final Map<String, dynamic> decodedData = jsonDecode(eventsJson);
      
      for (final entry in decodedData.entries) {
        final List<dynamic> eventsData = entry.value;
        for (final eventData in eventsData) {
          if (eventData['id'] == eventId) {
            return true;
          }
        }
      }
      
      return false;
    } catch (e) {
      _logError('verifyEventInStorage', 'Error verifying event $eventId: $e');
      return false;
    }
  }

  // Refresh only a specific month's cache without affecting other months
  static Future<void> _refreshSpecificMonthCache(DateTime date) async {
    final monthKey = '${date.year}-${date.month}';
    
    _logError('refreshSpecificMonthCache', 'Refreshing cache for month: $monthKey');
    
    try {
      // Remove only this month from caches
      _monthlyCache.remove(monthKey);
      
      // Remove events for this month from _events cache
      _events.removeWhere((key, _) {
        final keyDate = DateTime.parse(key);
        return keyDate.year == date.year && keyDate.month == date.month;
      });
      
      // Reload only this month
      await _loadEventsForMonth(date);
      _populateEventsFromCache(date);
      
      _logError('refreshSpecificMonthCache', 'Cache refresh completed for month: $monthKey');
    } catch (e) {
      _logError('refreshSpecificMonthCache', 'Failed to refresh month cache: $e');
      rethrow;
    }
  }
  
  // Add a new event (maintains same interface)
  static Future<void> addEvent(Event event) async {
    // Ensure event has an ID
    final eventWithId = event.id.isEmpty ? event.copyWith(id: DateTime.now().millisecondsSinceEpoch.toString()) : event;

    final normalizedStartDate = DateTime(
      eventWithId.startDate.year, eventWithId.startDate.month, eventWithId.startDate.day
    );

    if (_events[_dateToKey(normalizedStartDate)] == null) {
      _events[_dateToKey(normalizedStartDate)] = [];
    }

    // Make sure we're not adding a duplicate (check by ID)
    if (!_events[_dateToKey(normalizedStartDate)]!.any((e) => e.id == eventWithId.id)) {
      _events[_dateToKey(normalizedStartDate)]!.add(eventWithId);
    }

    // If event spans multiple days, add reference to end date as well
    if (eventWithId.startDate != eventWithId.endDate) {
      final normalizedEndDate = DateTime(
        eventWithId.endDate.year, eventWithId.endDate.month, eventWithId.endDate.day
      );

      if (_events[_dateToKey(normalizedEndDate)] == null) {
        _events[_dateToKey(normalizedEndDate)] = [];
      }

      if (!_events[_dateToKey(normalizedEndDate)]!.any((e) => e.id == eventWithId.id)) {
        _events[_dateToKey(normalizedEndDate)]!.add(eventWithId);
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
    // Focus only on spare events with duties
    if (newEvent.title.startsWith('SP') && (newEvent.assignedDuties?.isNotEmpty ?? false)) {
      _logError('updateEvent', '💾 SAVING SPARE: ${newEvent.title} | duties: ${newEvent.assignedDuties} | buses: ${newEvent.busAssignments}');
    }
    
    // Ensure new event has an ID, preferably the same as the old one
    final eventId = oldEvent.id.isNotEmpty ? oldEvent.id : newEvent.id.isNotEmpty ? newEvent.id : DateTime.now().millisecondsSinceEpoch.toString();
    final newEventWithId = newEvent.copyWith(id: eventId);

    // Normalize dates for searching in the cache
    final normalizedOldStartDate = DateTime(oldEvent.startDate.year, oldEvent.startDate.month, oldEvent.startDate.day);
    final normalizedOldEndDate = DateTime(oldEvent.endDate.year, oldEvent.endDate.month, oldEvent.endDate.day);
    final normalizedNewStartDate = DateTime(newEventWithId.startDate.year, newEventWithId.startDate.month, newEventWithId.startDate.day);
    final normalizedNewEndDate = DateTime(newEventWithId.endDate.year, newEventWithId.endDate.month, newEventWithId.endDate.day);

    _logError('updateEvent', 'Searching for event ${eventId} in dates: ${normalizedOldStartDate.toIso8601String()}, ${normalizedOldEndDate.toIso8601String()}');

    // Enhanced event finding logic - search more thoroughly
    bool eventFoundAndRemoved = false;
    Event? foundEvent;

    // 1. Search and remove the old event reference(s) from its original date(s)
    // Search in start date
    if (_events[_dateToKey(normalizedOldStartDate)] != null) {
      _logError('updateEvent', '🔍 SEARCHING for ${eventId} in ${_events[_dateToKey(normalizedOldStartDate)]!.length} cached events');
      for (int i = 0; i < _events[_dateToKey(normalizedOldStartDate)]!.length; i++) {
        final event = _events[_dateToKey(normalizedOldStartDate)]![i];
        _logError('updateEvent', '  Checking event: ${event.id} (${event.title})');
        if (event.id == eventId) {
          foundEvent = event;
          _events[_dateToKey(normalizedOldStartDate)]!.removeAt(i);
          eventFoundAndRemoved = true;
          _logError('updateEvent', '✅ FOUND and removed event from start date');
          break;
        }
      }
      
      if (!eventFoundAndRemoved) {
        _logError('updateEvent', '❌ EVENT NOT FOUND in cache - this might be the issue!');
      }
      
      // Clean up empty date entries
      if (_events[_dateToKey(normalizedOldStartDate)]!.isEmpty) {
        _events.remove(_dateToKey(normalizedOldStartDate));
      }
    } else {
      _logError('updateEvent', '❌ NO CACHED EVENTS for date ${normalizedOldStartDate.toIso8601String()}');
    }

    // Search in end date (if different from start date)
    if (oldEvent.startDate != oldEvent.endDate && _events[_dateToKey(normalizedOldEndDate)] != null) {
      for (int i = 0; i < _events[_dateToKey(normalizedOldEndDate)]!.length; i++) {
        final event = _events[_dateToKey(normalizedOldEndDate)]![i];
        if (event.id == eventId) {
          if (!eventFoundAndRemoved) {
            foundEvent = event;
          }
          _events[_dateToKey(normalizedOldEndDate)]!.removeAt(i);
          eventFoundAndRemoved = true;
          _logError('updateEvent', 'Found and removed event from end date');
          break;
        }
      }
      
      // Clean up empty date entries
      if (_events[_dateToKey(normalizedOldEndDate)]!.isEmpty) {
        _events.remove(_dateToKey(normalizedOldEndDate));
      }
    }

    // If not found in expected dates, search all cached events as fallback
    if (!eventFoundAndRemoved) {
      _logError('updateEvent', 'Event not found in expected dates, searching all cached events');
      
      for (final dateEntry in _events.entries) {
        for (int i = 0; i < dateEntry.value.length; i++) {
          final event = dateEntry.value[i];
          if (event.id == eventId) {
            foundEvent = event;
            dateEntry.value.removeAt(i);
            eventFoundAndRemoved = true;
            _logError('updateEvent', 'Found event in unexpected date: ${dateEntry.key}');
            
            // Clean up empty date entries
            if (dateEntry.value.isEmpty) {
              _events.remove(dateEntry.key);
            }
            break;
          }
        }
        if (eventFoundAndRemoved) break;
      }
    }

    // Also remove from monthly cache to ensure consistency
    final oldMonthKey = '${normalizedOldStartDate.year}-${normalizedOldStartDate.month}';
    if (_monthlyCache.containsKey(oldMonthKey)) {
      _monthlyCache[oldMonthKey]!.removeWhere((e) => e.id == eventId);
      if (_monthlyCache[oldMonthKey]!.isEmpty) {
        _monthlyCache.remove(oldMonthKey);
      }
    }
    
    // Also check end date month if different
    if (oldEvent.startDate != oldEvent.endDate) {
      final oldEndMonthKey = '${normalizedOldEndDate.year}-${normalizedOldEndDate.month}';
      if (oldMonthKey != oldEndMonthKey && _monthlyCache.containsKey(oldEndMonthKey)) {
        _monthlyCache[oldEndMonthKey]!.removeWhere((e) => e.id == eventId);
        if (_monthlyCache[oldEndMonthKey]!.isEmpty) {
          _monthlyCache.remove(oldEndMonthKey);
        }
      }
    }

    // 2. Add the updated event reference(s) to its new date(s)
    // Add to new start date
    if (_events[_dateToKey(normalizedNewStartDate)] == null) {
      _events[_dateToKey(normalizedNewStartDate)] = [];
    }
    
    // Always add the updated event (even if we didn't find the old one)
    if (!_events[_dateToKey(normalizedNewStartDate)]!.any((e) => e.id == eventId)) {
      _events[_dateToKey(normalizedNewStartDate)]!.add(newEventWithId);
      _logError('updateEvent', 'Added updated event to new start date');
    } else {
      // Replace existing event with same ID
      final existingIndex = _events[_dateToKey(normalizedNewStartDate)]!.indexWhere((e) => e.id == eventId);
      if (existingIndex != -1) {
        _events[_dateToKey(normalizedNewStartDate)]![existingIndex] = newEventWithId;
        _logError('updateEvent', 'Replaced existing event in new start date');
      }
    }

    // Add to new end date (if different from start date)
    if (newEventWithId.startDate != newEventWithId.endDate) {
      if (_events[_dateToKey(normalizedNewEndDate)] == null) {
        _events[_dateToKey(normalizedNewEndDate)] = [];
      }
      
      if (!_events[_dateToKey(normalizedNewEndDate)]!.any((e) => e.id == eventId)) {
        _events[_dateToKey(normalizedNewEndDate)]!.add(newEventWithId);
        _logError('updateEvent', 'Added updated event to new end date');
      } else {
        // Replace existing event with same ID
        final existingIndex = _events[_dateToKey(normalizedNewEndDate)]!.indexWhere((e) => e.id == eventId);
        if (existingIndex != -1) {
          _events[_dateToKey(normalizedNewEndDate)]![existingIndex] = newEventWithId;
          _logError('updateEvent', 'Replaced existing event in new end date');
        }
      }
    }

    // Update monthly cache
    final newMonthKey = '${normalizedNewStartDate.year}-${normalizedNewStartDate.month}';
    if (!_monthlyCache.containsKey(newMonthKey)) {
      _monthlyCache[newMonthKey] = [];
    }
    
    // Remove old version and add new version to monthly cache
    _monthlyCache[newMonthKey]!.removeWhere((e) => e.id == eventId);
    _monthlyCache[newMonthKey]!.add(newEventWithId);

    // Also update end date month if different
    if (newEventWithId.startDate != newEventWithId.endDate) {
      final newEndMonthKey = '${normalizedNewEndDate.year}-${normalizedNewEndDate.month}';
      if (newMonthKey != newEndMonthKey) {
        if (!_monthlyCache.containsKey(newEndMonthKey)) {
          _monthlyCache[newEndMonthKey] = [];
        }
        _monthlyCache[newEndMonthKey]!.removeWhere((e) => e.id == eventId);
        _monthlyCache[newEndMonthKey]!.add(newEventWithId);
      }
    }

    // --- Handle Notifications ---
    try {
      // Cancel old notification if applicable
      if (oldEvent.isWorkShift) {
        await _cancelWorkShiftNotification(oldEvent);
      }
      // Schedule new notification if applicable
      if (newEventWithId.isWorkShift) {
        await _scheduleWorkShiftNotification(newEventWithId);
      }
    } catch (notificationError) {
      _logError('updateEvent', 'Notification handling failed: $notificationError');
      // Don't fail the entire operation for notification issues
    }
    
    // CRITICAL DEBUG: Log state before save
    _logError('updateEvent', 'BEFORE SAVE - Current _events state for ${normalizedNewStartDate.toIso8601String()}:');
    if (_events.containsKey(_dateToKey(normalizedNewStartDate))) {
      for (int i = 0; i < _events[_dateToKey(normalizedNewStartDate)]!.length; i++) {
        final event = _events[_dateToKey(normalizedNewStartDate)]![i];
        _logError('updateEvent', '  [$i] ${event.id} (${event.title}) | duties: ${event.assignedDuties} | buses: ${event.busAssignments}');
      }
    } else {
      _logError('updateEvent', '  No events found for ${normalizedNewStartDate.toIso8601String()}');
    }

    // 3. Save the updated cache with enhanced error handling
    try {
      await _saveEvents();
      _logError('updateEvent', 'Successfully saved updated events');
      
      // CRITICAL DEBUG: Verify the save by checking current state
      _logError('updateEvent', 'POST SAVE VERIFICATION - Current _events state for ${normalizedNewStartDate.toIso8601String()}:');
      if (_events.containsKey(_dateToKey(normalizedNewStartDate))) {
        for (int i = 0; i < _events[_dateToKey(normalizedNewStartDate)]!.length; i++) {
          final event = _events[_dateToKey(normalizedNewStartDate)]![i];
          _logError('updateEvent', '  [$i] ${event.id} (${event.title}) | duties: ${event.assignedDuties} | buses: ${event.busAssignments}');
        }
      } else {
        _logError('updateEvent', '  WARNING: No events found for ${normalizedNewStartDate.toIso8601String()} after save!');
      }
      
    } catch (saveError) {
      _logError('updateEvent', 'Critical: Failed to save events: $saveError');
      
      // If save fails and we didn't find the original event, this is a critical error
      if (!eventFoundAndRemoved) {
        _logError('updateEvent', 'Critical: Event was not found and save failed - potential data loss');
        
        // Try to restore the event using addEvent as a recovery mechanism
        try {
          await addEvent(newEventWithId);
          _logError('updateEvent', 'Recovery: Successfully added event using addEvent');
          return;
        } catch (addError) {
          _logError('updateEvent', 'Recovery failed: Could not add event: $addError');
          rethrow;
        }
      }
      
      rethrow;
    }
    
    if (!eventFoundAndRemoved) {
      _logError('updateEvent', 'Warning: Original event was not found but update completed');
    } else {
      _logError('updateEvent', 'Update completed successfully');
    }
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

    if (_events[_dateToKey(normalizedStartDate)] != null) {
      _events[_dateToKey(normalizedStartDate)]!.removeWhere((e) => e.id == event.id);
      if (_events[_dateToKey(normalizedStartDate)]!.isEmpty) {
        _events.remove(_dateToKey(normalizedStartDate));
      }
    }

    // Remove reference from end date if it spans multiple days
    if (event.startDate != event.endDate) {
      final normalizedEndDate = DateTime(
        event.endDate.year, event.endDate.month, event.endDate.day
      );

      if (_events[_dateToKey(normalizedEndDate)] != null) {
        _events[_dateToKey(normalizedEndDate)]!.removeWhere((e) => e.id == event.id);
         if (_events[_dateToKey(normalizedEndDate)]!.isEmpty) {
           _events.remove(_dateToKey(normalizedEndDate));
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
  
  // Save events to storage with enhanced safety measures
  static Future<void> _saveEvents() async {
    // Prevent race conditions by queuing save operations
    if (_isSaving) {
      _logError('saveEvents', 'Save operation already in progress, queuing');
      return;
    }
    
    _isSaving = true;
    
    try {
      // Create backup before saving
      await _createBackup();
      
      final prefs = await SharedPreferences.getInstance();
      
      Map<String, List<Map<String, dynamic>>> encodedEvents = {};
      
      _events.forEach((date, eventsList) {
        final dateStr = date;
        // Ensure we only save unique events based on ID
        final uniqueEvents = <String, Event>{};
        for (var event in eventsList) {
          uniqueEvents[event.id] = event;
        }
        
        // Convert events to map and validate
        final validEvents = <Map<String, dynamic>>[];
        for (final event in uniqueEvents.values) {
          try {
            final eventMap = event.toMap();
            
            // DEBUG: Log busAssignments in the map before JSON encoding
            if (event.title.startsWith('SP') && event.busAssignments != null) {
              _logError('saveEvents', '💾 EVENT MAP: ${event.title} | busAssignments in map: ${eventMap['busAssignments']} (${eventMap['busAssignments'].runtimeType})');
            }
            
            if (_validateEventData(eventMap)) {
              validEvents.add(eventMap);
            } else {
              _logError('saveEvents', 'Invalid event data for event ${event.id}');
            }
          } catch (e) {
            _logError('saveEvents', 'Error converting event ${event.id} to map: $e');
          }
        }
        
        if (validEvents.isNotEmpty) {
          encodedEvents[dateStr] = validEvents;
        }
      });
      
      // Convert to JSON with error handling
      final jsonString = jsonEncode(encodedEvents);
      
      // DEBUG: Check if any spare events with busAssignments exist in the JSON
      if (jsonString.contains('SP') && jsonString.contains('busAssignments')) {
        _logError('saveEvents', '💾 JSON CHECK: JSON contains SP events with busAssignments');
        // Look for a specific pattern to see if busAssignments are preserved
        if (jsonString.contains('PZ1/41A')) {
          final startIndex = jsonString.indexOf('PZ1/41A') - 50;
          final endIndex = jsonString.indexOf('PZ1/41A') + 100;
          final snippet = jsonString.substring(
            startIndex > 0 ? startIndex : 0, 
            endIndex < jsonString.length ? endIndex : jsonString.length
          );
          _logError('saveEvents', '💾 JSON SNIPPET: ...$snippet...');
        }
      }
      
      // Validate JSON string size (SharedPreferences has limits)
      if (jsonString.length > 1024 * 1024) { // 1MB limit
        _logError('saveEvents', 'Warning: Events data is very large (${jsonString.length} characters)');
      }
      
      // Save to storage
      await prefs.setString(AppConstants.eventsStorageKey, jsonString);
      
      // Verify the save was successful by reading it back
      final verifyData = prefs.getString(AppConstants.eventsStorageKey);
      if (verifyData != jsonString) {
        throw Exception('Save verification failed - data mismatch');
      }
      
      // DO NOT clear monthly cache automatically - this causes data loss during navigation
      // The cache will be refreshed on-demand when needed
      
      _logError('saveEvents', 'Successfully saved and verified ${encodedEvents.length} date entries');
      
    } catch (e, stackTrace) {
      _logError('saveEvents', 'Critical error saving events: $e', stackTrace);
      
      // Try to restore from backup if save failed
      if (await _restoreFromBackup()) {
        _logError('saveEvents', 'Restored from backup after save failure');
      }
      
      // Re-throw to let caller know save failed
      rethrow;
    } finally {
      _isSaving = false;
    }
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
      
      for (final entry in decodedData.entries) {
        final List<dynamic> eventsData = entry.value;
        allEvents.addAll(eventsData.map((eventData) => Event.fromMap(eventData)));
      }
      
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

      for (final entry in decodedJson.entries) {
        final eventsListDynamic = entry.value;
        if (eventsListDynamic is List) {
          for (var eventDataMap in eventsListDynamic) {
            if (eventDataMap is Map<String, dynamic>) {
              try {
                Event event = Event.fromMap(eventDataMap);

                // Add to _events based on actual event.startDate
                final normalizedEventStartDate = DateTime(event.startDate.year, event.startDate.month, event.startDate.day);
                _events[_dateToKey(normalizedEventStartDate)] ??= [];
                if (!_events[_dateToKey(normalizedEventStartDate)]!.any((e) => e.id == event.id)) {
                  _events[_dateToKey(normalizedEventStartDate)]!.add(event);
                }

                // If event spans multiple days, add reference to _events for endDate as well
                final normalizedEventEndDate = DateTime(event.endDate.year, event.endDate.month, event.endDate.day);
                if (normalizedEventStartDate != normalizedEventEndDate) {
                  _events[_dateToKey(normalizedEventEndDate)] ??= [];
                  if (!_events[_dateToKey(normalizedEventEndDate)]!.any((e) => e.id == event.id)) {
                    _events[_dateToKey(normalizedEventEndDate)]!.add(event);
                  }
                }
              } catch (e) {
                // Failed to parse individual event, skip it
              }
            }
          }
        }
      }
      // Optional: Count and log number of events loaded for verification
      // To avoid counting same event twice if it spans days & is in two lists, count unique IDs
      Set<String> uniqueEventIds = {};
      for (final list in _events.values) {
        for (final event in list) {
          uniqueEventIds.add(event.id);
        }
      }


    } catch (e) {

      _events = {}; // Ensure events map is empty on error to avoid partial inconsistent state
    }
  }

  // Recover a specific event from storage when cache data seems incomplete
  static Future<void> _recoverEventFromStorage(String eventId, DateTime eventDate) async {
    try {
      _logError('_recoverEventFromStorage', 'Attempting to recover event $eventId from storage');
      
      // Force reload from storage
      await _loadEventsForMonth(eventDate);
      
      // Clear the specific day from cache and repopulate
      _events.remove(_dateToKey(eventDate));
      await preloadMonth(eventDate);
      
      // Verify the event was recovered
      final recoveredEvents = _events[_dateToKey(eventDate)] ?? [];
      final recoveredEvent = recoveredEvents.firstWhere(
        (e) => e.id == eventId,
        orElse: () => Event(
          id: '',
          title: '',
          startDate: eventDate,
          startTime: const TimeOfDay(hour: 0, minute: 0),
          endDate: eventDate,
          endTime: const TimeOfDay(hour: 0, minute: 0),
          busAssignments: {},
        ),
      );
      
      if (recoveredEvent.id.isNotEmpty) {
        _logError('_recoverEventFromStorage', 'Successfully recovered event $eventId with duties: ${recoveredEvent.assignedDuties} and buses: ${recoveredEvent.busAssignments}');
      } else {
        _logError('_recoverEventFromStorage', 'Failed to recover event $eventId - event not found in storage');
      }
    } catch (e) {
      _logError('_recoverEventFromStorage', 'Recovery failed for event $eventId: $e');
    }
  }
}


