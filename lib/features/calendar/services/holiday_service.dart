import 'dart:convert';
import 'package:spdrivercalendar/core/constants/app_constants.dart';
import 'package:spdrivercalendar/core/services/storage_service.dart';
import 'package:spdrivercalendar/models/holiday.dart';
import 'package:spdrivercalendar/google_calendar_service.dart';
import 'package:spdrivercalendar/calendar_test_helper.dart';

class HolidayService {
  static const String _holidaysKey = 'holidays';

  // Get all holidays
  static Future<List<Holiday>> getHolidays() async {
    try {
      final holidaysJson = await StorageService.getString(_holidaysKey);
      if (holidaysJson == null) return [];

      final List<dynamic> decoded = json.decode(holidaysJson);
      return decoded.map((json) => Holiday.fromJson(json)).toList();
    } catch (e) {
      print('Error loading holidays: $e');
      return [];
    }
  }

  // Add a new holiday
  static Future<void> addHoliday(Holiday holiday) async {
    try {
      final holidays = await getHolidays();
      if (holidays.any((h) => h.id == holiday.id)) {
        print('Holiday with ID ${holiday.id} already exists.');
        return;
      }
      holidays.add(holiday);
      
      final encoded = json.encode(holidays.map((h) => h.toJson()).toList());
      await StorageService.saveString(_holidaysKey, encoded);
      print('Holiday added locally: ${holiday.id}');

      final syncEnabled = await StorageService.getBool(AppConstants.syncToGoogleCalendarKey, defaultValue: false);
      final isSignedIn = await GoogleCalendarService.isSignedIn();

      if (syncEnabled && isSignedIn) {
        print('Auto-sync enabled, attempting to add holiday to Google Calendar...');
        await CalendarTestHelper.addHolidayToCalendar(holiday);
      } else {
        print('Auto-sync not enabled or user not signed in, skipping Google Calendar sync.');
      }
    } catch (e) {
      print('Error adding holiday: $e');
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
        print('Holiday with ID $id not found for removal.');
        holidayToRemove = null;
      }

      final initialLength = holidays.length;
      holidays.removeWhere((h) => h.id == id);

      if (holidays.length < initialLength && holidayToRemove != null) {
        final encoded = json.encode(holidays.map((h) => h.toJson()).toList());
        await StorageService.saveString(_holidaysKey, encoded);
        print('Holiday removed locally: $id');

        final syncEnabled = await StorageService.getBool(AppConstants.syncToGoogleCalendarKey, defaultValue: false);
        final isSignedIn = await GoogleCalendarService.isSignedIn();

        if (syncEnabled && isSignedIn) {
          print('Auto-sync enabled, attempting to remove holiday from Google Calendar...');
          await CalendarTestHelper.deleteHolidayFromCalendar(holidayToRemove);
        } else {
          print('Auto-sync not enabled or user not signed in, skipping Google Calendar removal.');
        }
      } else if (holidayToRemove == null) {
        print('Skipping save and Google Calendar removal as holiday $id was not found.');
      }

    } catch (e) {
      print('Error removing holiday: $e');
    }
  }

  // Check if a date is within any holiday period
  static Future<bool> isHoliday(DateTime date) async {
    try {
      final holidays = await getHolidays();
      return holidays.any((holiday) => holiday.containsDate(date));
    } catch (e) {
      print('Error checking holiday status: $e');
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