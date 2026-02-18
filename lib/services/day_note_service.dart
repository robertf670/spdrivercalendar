import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spdrivercalendar/core/constants/app_constants.dart';

/// Service for storing and retrieving notes attached to specific calendar days.
/// Day notes are independent of events - they can be added to any day (including rest days).
class DayNoteService {
  static Map<String, String> _dayNotes = {};
  static bool _isLoaded = false;

  static String _dateToKey(DateTime date) {
    return DateTime(date.year, date.month, date.day).toIso8601String();
  }

  /// Load day notes from storage. Call early (e.g. in CalendarScreen initState)
  /// to ensure notes are available for display.
  static Future<void> loadDayNotes() async {
    if (_isLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(AppConstants.dayNotesStorageKey);
      if (json != null) {
        final decoded = jsonDecode(json) as Map<String, dynamic>?;
        if (decoded != null) {
          _dayNotes = decoded.map((k, v) => MapEntry(k, v as String));
        }
      }
      _isLoaded = true;
    } catch (_) {
      _dayNotes = {};
      _isLoaded = true;
    }
  }

  /// Check if a day has a note (synchronous - uses in-memory cache).
  static bool hasNoteForDate(DateTime date) {
    final note = getDayNote(date);
    return note != null && note.trim().isNotEmpty;
  }

  /// Get the note for a date (synchronous - uses in-memory cache).
  static String? getDayNote(DateTime date) {
    return _dayNotes[_dateToKey(date)];
  }

  /// Get all day notes as (date, note) pairs. Ensures notes are loaded first.
  static Future<List<({DateTime date, String note})>> getAllDayNotes() async {
    await loadDayNotes();
    return _dayNotes.entries
        .where((e) => e.value.trim().isNotEmpty)
        .map((e) => (date: DateTime.parse(e.key), note: e.value))
        .toList();
  }

  /// Save or clear a note for a date.
  static Future<void> saveDayNote(DateTime date, String? note) async {
    final key = _dateToKey(date);
    if (note == null || note.trim().isEmpty) {
      _dayNotes.remove(key);
    } else {
      _dayNotes[key] = note.trim();
    }
    await _persist();
  }

  static Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(_dayNotes);
      await prefs.setString(AppConstants.dayNotesStorageKey, json);
    } catch (_) {
      // Persist failed - in-memory state is still updated
    }
  }

  /// Notify that day notes may have changed externally (e.g. after restore).
  static void invalidateCache() {
    _isLoaded = false;
  }
}
