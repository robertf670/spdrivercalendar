import 'dart:convert';
import 'package:spdrivercalendar/core/constants/app_constants.dart';
import 'package:spdrivercalendar/core/services/storage_service.dart';
import 'package:spdrivercalendar/core/services/cache_service.dart';
import 'package:spdrivercalendar/models/holiday.dart';
import 'package:spdrivercalendar/google_calendar_service.dart';
import 'package:spdrivercalendar/calendar_test_helper.dart';

class HolidayService {
  static const String _holidaysKey = 'holidays';
  static const String _backupSuffix = '_backup';
  static const String _cacheKey = 'holidays_list_cache'; // Cache key used in calendar screen
  
  // Save operation synchronization
  static bool _isSaving = false;
  
  // Cache service instance
  static final CacheService _cacheService = CacheService();
  
  // Enhanced error logging
  static void _logError(String operation, dynamic error, [StackTrace? stackTrace]) {
    // Error logging removed
  }
  
  // Invalidate holidays cache
  static void _invalidateCache() {
    try {
      // Invalidate both the service's cache and create a new instance to ensure calendar cache is cleared
      _cacheService.remove(_cacheKey);
      
      // CRITICAL FIX: Also clear cache using a fresh CacheService instance 
      // to ensure the calendar screen's cache is invalidated
      final freshCacheService = CacheService();
      freshCacheService.remove(_cacheKey);
      
      // CRITICAL FIX: Also clear StorageService's internal cache for the holidays key
      // This ensures we always read fresh data from SharedPreferences on next access
      StorageService.clearCacheForKey(_holidaysKey);
      
      _logError('_invalidateCache', 'Successfully invalidated holidays cache (all instances including StorageService)');
    } catch (e) {
      _logError('_invalidateCache', 'Failed to invalidate cache: $e');
    }
  }
  
  // Data validation method
  static bool _validateHolidayData(Map<String, dynamic> data) {
    try {
      // Check required fields
      if (data['id'] == null || data['startDate'] == null || 
          data['endDate'] == null || data['type'] == null) {
        return false;
      }
      
      // Validate date formats
      DateTime.parse(data['startDate']);
      DateTime.parse(data['endDate']);
      
      // Validate type
      if (!['winter', 'summer', 'other', 'unpaid_leave', 'day_in_lieu'].contains(data['type'])) {
        return false;
      }
      
      return true;
    } catch (e) {
      _logError('validateHolidayData', e);
      return false;
    }
  }
  
  // Create backup of holidays data
  static Future<void> _createBackup() async {
    try {
      final originalData = await StorageService.getString(_holidaysKey);
      if (originalData != null) {
        await StorageService.saveString(_holidaysKey + _backupSuffix, originalData);
      }
    } catch (e) {
      _logError('createBackup', e);
    }
  }
  
  // Restore from backup if main data is corrupted
  static Future<bool> _restoreFromBackup() async {
    try {
      final backupData = await StorageService.getString(_holidaysKey + _backupSuffix);
      if (backupData != null) {
        // Validate backup data
        final decoded = json.decode(backupData);
        if (decoded is List) {
          await StorageService.saveString(_holidaysKey, backupData);
          _logError('restoreFromBackup', 'Successfully restored holidays from backup');
          return true;
        }
      }
      return false;
    } catch (e) {
      _logError('restoreFromBackup', e);
      return false;
    }
  }
  
  // Safe save operation with backup and validation
  static Future<void> _safeHolidaysSave(List<Holiday> holidays) async {
    if (_isSaving) {
      _logError('safeHolidaysSave', 'Save operation already in progress');
      return;
    }
    
    _isSaving = true;
    
    try {
      // Create backup before saving
      await _createBackup();
      
      // Validate all holiday data before saving
      final validHolidays = <Holiday>[];
      for (final holiday in holidays) {
        try {
          final holidayMap = holiday.toJson();
          if (_validateHolidayData(holidayMap)) {
            validHolidays.add(holiday);
          } else {
            _logError('safeHolidaysSave', 'Invalid holiday data for ${holiday.id}');
          }
        } catch (e) {
          _logError('safeHolidaysSave', 'Error validating holiday ${holiday.id}: $e');
        }
      }
      
      final encoded = json.encode(validHolidays.map((h) => h.toJson()).toList());
      
      // Validate JSON string size
      if (encoded.length > 512 * 1024) { // 512KB limit for holidays
        _logError('safeHolidaysSave', 'Warning: Holidays data is very large (${encoded.length} characters)');
      }
      
      await StorageService.saveString(_holidaysKey, encoded);
      _logError('safeHolidaysSave', 'Successfully saved ${validHolidays.length} holidays');
      
    } catch (e, stackTrace) {
      _logError('safeHolidaysSave', 'Critical error saving holidays: $e', stackTrace);
      
      // Try to restore from backup if save failed
      if (await _restoreFromBackup()) {
        _logError('safeHolidaysSave', 'Restored holidays from backup after save failure');
      }
      
      rethrow;
    } finally {
      _isSaving = false;
    }
  }

  // Get all holidays
  static Future<List<Holiday>> getHolidays() async {
    try {
      final holidaysJson = await StorageService.getString(_holidaysKey);
      if (holidaysJson == null) {
        _logError('getHolidays', 'No holidays found in storage (null)');
        return [];
      }

      final List<dynamic> decoded = json.decode(holidaysJson);
      final holidays = <Holiday>[];
      
      _logError('getHolidays', 'Decoded ${decoded.length} holidays from storage');
      
      for (final holidayData in decoded) {
        try {
          if (_validateHolidayData(holidayData)) {
            holidays.add(Holiday.fromJson(holidayData));
          } else {
            _logError('getHolidays', 'Invalid holiday data: $holidayData');
          }
        } catch (e) {
          _logError('getHolidays', 'Error parsing holiday: $e');
        }
      }
      
      _logError('getHolidays', 'Returning ${holidays.length} valid holidays');
      return holidays;
    } catch (e, stackTrace) {
      _logError('getHolidays', 'Failed to load holidays: $e', stackTrace);
      
      // Try to restore from backup if main data is corrupted
      if (await _restoreFromBackup()) {
        try {
          return await getHolidays();
        } catch (retryError) {
          _logError('getHolidays', 'Failed even after backup restoration: $retryError');
        }
      }
      
      return [];
    }
  }

  // Add a new holiday
  static Future<void> addHoliday(Holiday holiday) async {
    try {
      _logError('addHoliday', 'Starting to add holiday ${holiday.id} (type: ${holiday.type})');
      
      final holidays = await getHolidays();
      _logError('addHoliday', 'Loaded ${holidays.length} existing holidays from storage');
      
      if (holidays.any((h) => h.id == holiday.id)) {
        _logError('addHoliday', 'Holiday ${holiday.id} already exists');
        return;
      }
      
      holidays.add(holiday);
      _logError('addHoliday', 'Added new holiday, total count now: ${holidays.length}');
      
      await _safeHolidaysSave(holidays);
      _logError('addHoliday', 'Successfully saved ${holidays.length} holidays to storage');
      
      // Invalidate cache after successful save
      _invalidateCache();
      
      // Verify the save by reading back
      final verifyHolidays = await getHolidays();
      _logError('addHoliday', 'Verification: Read back ${verifyHolidays.length} holidays from storage');
      if (verifyHolidays.length != holidays.length) {
        _logError('addHoliday', 'WARNING: Holiday count mismatch after save! Expected ${holidays.length}, got ${verifyHolidays.length}');
      }

      final syncEnabled = await StorageService.getBool(AppConstants.syncToGoogleCalendarKey, defaultValue: false);
      final isSignedIn = await GoogleCalendarService.isSignedIn();

      if (syncEnabled && isSignedIn) {
        _logError('addHoliday', 'Attempting to sync holiday ${holiday.id} to Google Calendar');
        await CalendarTestHelper.addHolidayToCalendar(holiday);
      } else {
        _logError('addHoliday', 'Skipping Google Calendar sync - not enabled or not signed in');
      }
    } catch (e, stackTrace) {
      _logError('addHoliday', 'Failed to add holiday: $e', stackTrace);
      rethrow;
    }
  }

  // Remove a holiday by ID
  static Future<void> removeHoliday(String id) async {
    Holiday? holidayToRemove;
    try {
      final holidays = await getHolidays();
      try {
        holidayToRemove = holidays.firstWhere((h) => h.id == id);
      } catch (e) {
        _logError('removeHoliday', 'Holiday with ID $id not found');
        return;
      }

      final initialLength = holidays.length;
      holidays.removeWhere((h) => h.id == id);

      if (holidays.length < initialLength) {
        await _safeHolidaysSave(holidays);
        
        // Invalidate cache after successful removal
        _invalidateCache();

        final syncEnabled = await StorageService.getBool(AppConstants.syncToGoogleCalendarKey, defaultValue: false);
        final isSignedIn = await GoogleCalendarService.isSignedIn();

        if (syncEnabled && isSignedIn) {
          _logError('removeHoliday', 'Attempting to remove holiday ${holidayToRemove.id} from Google Calendar');
          await CalendarTestHelper.deleteHolidayFromCalendar(holidayToRemove);
        } else {
          _logError('removeHoliday', 'Skipping Google Calendar removal - not enabled or not signed in');
        }
      }

    } catch (e, stackTrace) {
      _logError('removeHoliday', 'Failed to remove holiday: $e', stackTrace);
      rethrow;
    }
  }

  // Check if a date is within any holiday period
  static Future<bool> isHoliday(DateTime date) async {
    try {
      final holidays = await getHolidays();
      return holidays.any((holiday) => holiday.containsDate(date));
    } catch (e) {
      // Failed to check holiday, assume false
      return false;
    }
  }

  // Get holiday for a specific date
  static Future<Holiday?> getHolidayForDate(DateTime date) async {
    try {
      final holidays = await getHolidays();
      return holidays.firstWhere(
        (holiday) => holiday.containsDate(date),
        orElse: () => throw Exception('No holiday found'),
      );
    } catch (e) {
      return null;
    }
  }
} 
