import 'dart:convert';

import 'package:spdrivercalendar/core/constants/app_constants.dart';
import 'package:spdrivercalendar/core/services/storage_service.dart';

class RosterScheduleChange {
  final DateTime effectiveDate;
  final int startWeek;

  const RosterScheduleChange({
    required this.effectiveDate,
    required this.startWeek,
  });

  Map<String, dynamic> toJson() => {
        'effectiveDate': _dateKey(effectiveDate),
        'startWeek': startWeek,
      };

  factory RosterScheduleChange.fromJson(Map<String, dynamic> json) {
    final effectiveDate =
        DateTime.tryParse(json['effectiveDate'] as String? ?? '');
    final startWeek = json['startWeek'];
    if (effectiveDate == null ||
        startWeek is! int ||
        startWeek < 0 ||
        startWeek > 4) {
      throw const FormatException('Invalid roster schedule change');
    }

    return RosterScheduleChange(
      effectiveDate: _dateOnly(effectiveDate),
      startWeek: startWeek,
    );
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

class RosterScheduleAnchor {
  final DateTime startDate;
  final int startWeek;

  const RosterScheduleAnchor({
    required this.startDate,
    required this.startWeek,
  });
}

class RosterScheduleService {
  static List<RosterScheduleChange> _changes = [];
  static bool _isInitialized = false;

  static Future<void> initialize({bool forceReload = false}) async {
    if (_isInitialized && !forceReload) return;

    try {
      final stored =
          await StorageService.getString(AppConstants.rosterScheduleChangesKey);
      if (stored == null || stored.isEmpty) {
        _changes = [];
      } else {
        final decoded = jsonDecode(stored) as List<dynamic>;
        _changes = decoded
            .whereType<Map>()
            .map((item) => RosterScheduleChange.fromJson(
                  Map<String, dynamic>.from(item),
                ))
            .toList()
          ..sort((a, b) => a.effectiveDate.compareTo(b.effectiveDate));
      }
    } catch (_) {
      _changes = [];
    }

    _isInitialized = true;
  }

  static RosterScheduleAnchor resolveAnchor({
    required DateTime date,
    required DateTime fallbackStartDate,
    required int fallbackStartWeek,
  }) {
    var anchor = RosterScheduleAnchor(
      startDate: fallbackStartDate,
      startWeek: fallbackStartWeek,
    );
    final normalizedDate = _dateOnly(date);

    for (final change in _changes) {
      if (change.effectiveDate.isAfter(normalizedDate)) break;
      anchor = RosterScheduleAnchor(
        startDate: change.effectiveDate,
        startWeek: change.startWeek,
      );
    }

    return anchor;
  }

  static Future<void> setChange({
    required DateTime effectiveDate,
    required int startWeek,
  }) async {
    await initialize();
    if (startWeek < 0 || startWeek > 4) {
      throw ArgumentError.value(
          startWeek, 'startWeek', 'Must be between 0 and 4');
    }

    final normalizedDate = sundayOfWeek(effectiveDate);
    _changes.removeWhere(
      (change) => _sameDate(change.effectiveDate, normalizedDate),
    );
    _changes.add(
      RosterScheduleChange(
        effectiveDate: normalizedDate,
        startWeek: startWeek,
      ),
    );
    _changes.sort((a, b) => a.effectiveDate.compareTo(b.effectiveDate));
    await _persist();
  }

  static Future<void> removeChange(DateTime effectiveDate) async {
    await initialize();
    final normalizedDate = sundayOfWeek(effectiveDate);
    _changes.removeWhere(
      (change) => _sameDate(change.effectiveDate, normalizedDate),
    );
    await _persist();
  }

  static List<RosterScheduleChange> get changes => List.unmodifiable(_changes);

  static DateTime sundayOfWeek(DateTime date) {
    final normalized = _dateOnly(date);
    return normalized.subtract(Duration(days: normalized.weekday % 7));
  }

  static Future<void> _persist() async {
    await StorageService.saveString(
      AppConstants.rosterScheduleChangesKey,
      jsonEncode(_changes.map((change) => change.toJson()).toList()),
    );
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static bool _sameDate(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  static void resetForTesting() {
    _changes = [];
    _isInitialized = false;
  }
}
