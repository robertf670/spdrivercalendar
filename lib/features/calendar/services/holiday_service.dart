import 'dart:convert';
import 'package:spdrivercalendar/core/constants/app_constants.dart';
import 'package:spdrivercalendar/core/services/storage_service.dart';
import 'package:spdrivercalendar/models/holiday.dart';

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
      holidays.add(holiday);
      
      final encoded = json.encode(holidays.map((h) => h.toJson()).toList());
      await StorageService.saveString(_holidaysKey, encoded);
    } catch (e) {
      print('Error adding holiday: $e');
    }
  }

  // Remove a holiday by ID
  static Future<void> removeHoliday(String id) async {
    try {
      final holidays = await getHolidays();
      holidays.removeWhere((h) => h.id == id);
      
      final encoded = json.encode(holidays.map((h) => h.toJson()).toList());
      await StorageService.saveString(_holidaysKey, encoded);
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