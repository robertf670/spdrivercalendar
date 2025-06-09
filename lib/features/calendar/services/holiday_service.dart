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
      // Failed to load holidays, return empty list
      return [];
    }
  }

  // Add a new holiday
  static Future<void> addHoliday(Holiday holiday) async {
    try {
      final holidays = await getHolidays();
      if (holidays.any((h) => h.id == holiday.id)) {

        return;
      }
      holidays.add(holiday);
      
      final encoded = json.encode(holidays.map((h) => h.toJson()).toList());
      await StorageService.saveString(_holidaysKey, encoded);


      final syncEnabled = await StorageService.getBool(AppConstants.syncToGoogleCalendarKey, defaultValue: false);
      final isSignedIn = await GoogleCalendarService.isSignedIn();

      if (syncEnabled && isSignedIn) {

        await CalendarTestHelper.addHolidayToCalendar(holiday);
      } else {

      }
    } catch (e) {
      // Failed to add holiday, ignore error
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
        // Holiday with this ID not found
        holidayToRemove = null;
      }

      final initialLength = holidays.length;
      holidays.removeWhere((h) => h.id == id);

      if (holidays.length < initialLength && holidayToRemove != null) {
        final encoded = json.encode(holidays.map((h) => h.toJson()).toList());
        await StorageService.saveString(_holidaysKey, encoded);


        final syncEnabled = await StorageService.getBool(AppConstants.syncToGoogleCalendarKey, defaultValue: false);
        final isSignedIn = await GoogleCalendarService.isSignedIn();

        if (syncEnabled && isSignedIn) {

          await CalendarTestHelper.deleteHolidayFromCalendar(holidayToRemove);
        } else {

        }
      } else if (holidayToRemove == null) {

      }

    } catch (e) {
      // Failed to remove holiday, ignore error
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
