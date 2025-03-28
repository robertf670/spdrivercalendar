import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class RestDaysService {
  static const String _restDaysKey = 'rest_days';
  static List<DateTime> _restDays = [];
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final restDaysJson = prefs.getStringList(_restDaysKey) ?? [];
      
      _restDays = restDaysJson.map((dateStr) {
        try {
          return DateTime.parse(dateStr);
        } catch (e) {
          return null;
        }
      }).whereType<DateTime>().toList();
      
      _isInitialized = true;
    } catch (e) {
      _restDays = [];
    }
  }

  static List<DateTime> getRestDays() {
    if (!_isInitialized) {
      return [];
    }
    return List.unmodifiable(_restDays);
  }

  static Future<void> setRestDays(List<DateTime> restDays) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final restDaysJson = restDays.map((date) => date.toIso8601String()).toList();
      await prefs.setStringList(_restDaysKey, restDaysJson);
      _restDays = restDays;
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> addRestDay(DateTime date) async {
    if (!_isInitialized) {
      return;
    }

    // Normalize the date to midnight to avoid time component issues
    final normalizedDate = DateTime(date.year, date.month, date.day);
    
    // Check if the date already exists
    if (!isRestDay(normalizedDate)) {
      _restDays.add(normalizedDate);
      await setRestDays(_restDays);
    }
  }

  static Future<void> removeRestDay(DateTime date) async {
    if (!_isInitialized) {
      return;
    }

    // Normalize the date to midnight to avoid time component issues
    final normalizedDate = DateTime(date.year, date.month, date.day);
    
    _restDays.removeWhere((d) => 
      d.year == normalizedDate.year && 
      d.month == normalizedDate.month && 
      d.day == normalizedDate.day
    );
    await setRestDays(_restDays);
  }

  static bool isRestDay(DateTime date) {
    if (!_isInitialized) {
      return false;
    }

    // Normalize the input date to midnight UTC to avoid timezone issues in comparison
    final normalizedInputDate = DateTime.utc(date.year, date.month, date.day);
    
    // Check if ANY date in the list matches year, month, and day in UTC
    return _restDays.any((storedDate) {
      // Also normalize the stored date to midnight UTC for a robust comparison
      final normalizedStoredDate = DateTime.utc(storedDate.year, storedDate.month, storedDate.day);
      bool match = normalizedStoredDate.isAtSameMomentAs(normalizedInputDate);
      return match;
    });
  }

  static Future<void> clearRestDays() async {
    if (!_isInitialized) {
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_restDaysKey);
      _restDays = [];
    } catch (e) {
      rethrow;
    }
  }
} 