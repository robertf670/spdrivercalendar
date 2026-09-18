import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spdrivercalendar/core/constants/app_constants.dart';

/// Per-day colour overrides, independent of roster, events, and notes.
class DayColorService {
  static Map<String, int> _dayColors = {};
  static bool _isLoaded = false;

  static String dateToKey(DateTime date) {
    return DateTime(date.year, date.month, date.day).toIso8601String();
  }

  static Future<void> load() async {
    if (_isLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(AppConstants.dayColorsStorageKey);
      if (json != null) {
        final decoded = jsonDecode(json) as Map<String, dynamic>?;
        if (decoded != null) {
          _dayColors = decoded.map((key, value) => MapEntry(key, value as int));
        }
      }
      _isLoaded = true;
    } catch (_) {
      _dayColors = {};
      _isLoaded = true;
    }
  }

  static Color? colorForDate(DateTime date) {
    final value = _dayColors[dateToKey(date)];
    if (value == null) return null;
    return Color(value);
  }

  static bool hasOverride(DateTime date) => colorForDate(date) != null;

  static Future<void> setColor(DateTime date, Color color) async {
    await load();
    _dayColors[dateToKey(date)] = color.toARGB32();
    await _persist();
  }

  static Future<void> clearColor(DateTime date) async {
    await load();
    _dayColors.remove(dateToKey(date));
    await _persist();
  }

  static Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        AppConstants.dayColorsStorageKey,
        jsonEncode(_dayColors),
      );
    } catch (_) {}
  }

  static void invalidateCache() {
    _isLoaded = false;
    _dayColors = {};
  }
}
