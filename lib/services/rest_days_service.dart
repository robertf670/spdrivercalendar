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
          print('Error parsing date: $dateStr');
          return null;
        }
      }).whereType<DateTime>().toList();
      
      _isInitialized = true;
    } catch (e) {
      print('Error initializing RestDaysService: $e');
      _restDays = [];
    }
  }

  static List<DateTime> getRestDays() {
    if (!_isInitialized) {
      print('Warning: RestDaysService not initialized');
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
      print('Error setting rest days: $e');
      rethrow;
    }
  }

  static Future<void> addRestDay(DateTime date) async {
    if (!_isInitialized) {
      print('Warning: RestDaysService not initialized');
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
      print('Warning: RestDaysService not initialized');
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
      print('Warning: RestDaysService not initialized');
      return false;
    }

    // Normalize the date to midnight to avoid time component issues
    final normalizedDate = DateTime(date.year, date.month, date.day);
    
    return _restDays.any((d) => 
      d.year == normalizedDate.year && 
      d.month == normalizedDate.month && 
      d.day == normalizedDate.day
    );
  }

  static Future<void> clearRestDays() async {
    if (!_isInitialized) {
      print('Warning: RestDaysService not initialized');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_restDaysKey);
      _restDays = [];
    } catch (e) {
      print('Error clearing rest days: $e');
      rethrow;
    }
  }
} 