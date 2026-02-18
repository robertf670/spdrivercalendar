import 'dart:convert';
import 'package:spdrivercalendar/core/constants/app_constants.dart';
import 'package:spdrivercalendar/core/services/storage_service.dart';
import 'package:spdrivercalendar/features/calendar/services/roster_service.dart';

/// Represents a rest day swap: work day becomes rest, rest day becomes work.
/// Swapped work days do NOT count as "working on rest day" for pay/badges.
class RestDaySwap {
  final DateTime workDate; // Was work, now rest (swapped rest - needs indicator)
  final DateTime restDate; // Was rest, now work (swapped work - normal rate)
  final String shiftType; // E/L/M - the shift moved to restDate

  RestDaySwap({
    required this.workDate,
    required this.restDate,
    required this.shiftType,
  });

  Map<String, dynamic> toJson() => {
        'workDate': _dateToKey(workDate),
        'restDate': _dateToKey(restDate),
        'shiftType': shiftType,
      };

  factory RestDaySwap.fromJson(Map<String, dynamic> json) {
    final workDate = _keyToDate(json['workDate'] as String?);
    final restDate = _keyToDate(json['restDate'] as String?);
    if (workDate == null || restDate == null) {
      throw FormatException('Invalid RestDaySwap date');
    }
    return RestDaySwap(
      workDate: workDate,
      restDate: restDate,
      shiftType: json['shiftType'] as String? ?? 'L',
    );
  }

  static String _dateToKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  static DateTime? _keyToDate(String? key) {
    if (key == null || key.length != 10) return null;
    return DateTime.tryParse(key);
  }
}

/// Result of shift lookup, includes swap context for badge/rate logic.
class ShiftLookupResult {
  final String shift; // E, L, M, R, W, etc.
  final bool isSwappedRest; // True if this is a rest day due to swap (show indicator)
  final bool isSwappedWork; // True if this is work due to swap (NOT rest day rate)

  const ShiftLookupResult({
    required this.shift,
    this.isSwappedRest = false,
    this.isSwappedWork = false,
  });
}

class RestDaySwapService {
  static List<RestDaySwap> _swaps = [];
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      final json =
          await StorageService.getString(AppConstants.restDaySwapsKey);
      if (json != null && json.isNotEmpty) {
        final list = jsonDecode(json) as List<dynamic>;
        _swaps = list
            .map((e) => RestDaySwap.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _swaps = [];
      }
      _isInitialized = true;
    } catch (_) {
      _swaps = [];
      _isInitialized = true;
    }
  }

  static bool _sameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static Future<void> _persist() async {
    final json = jsonEncode(_swaps.map((s) => s.toJson()).toList());
    await StorageService.saveString(AppConstants.restDaySwapsKey, json);
  }

  /// Add a swap: workDate (was work) becomes rest, restDate (was rest) gets work shift.
  static Future<void> addSwap({
    required DateTime workDate,
    required DateTime restDate,
    required String shiftType,
  }) async {
    await initialize();
    final normWork = DateTime(workDate.year, workDate.month, workDate.day);
    final normRest = DateTime(restDate.year, restDate.month, restDate.day);
    _swaps.removeWhere((s) =>
        _sameDate(s.workDate, normWork) || _sameDate(s.restDate, normRest));
    _swaps.add(RestDaySwap(
      workDate: normWork,
      restDate: normRest,
      shiftType: shiftType,
    ));
    await _persist();
  }

  /// Remove swap that affects this date (either as work or rest).
  static Future<void> removeSwapForDate(DateTime date) async {
    await initialize();
    final norm = DateTime(date.year, date.month, date.day);
    _swaps
        .removeWhere((s) => _sameDate(s.workDate, norm) || _sameDate(s.restDate, norm));
    await _persist();
  }

  /// Remove a specific swap by work and rest dates.
  static Future<void> removeSwap({
    required DateTime workDate,
    required DateTime restDate,
  }) async {
    await initialize();
    final normWork = DateTime(workDate.year, workDate.month, workDate.day);
    final normRest = DateTime(restDate.year, restDate.month, restDate.day);
    _swaps.removeWhere((s) =>
        _sameDate(s.workDate, normWork) && _sameDate(s.restDate, normRest));
    await _persist();
  }

  static List<RestDaySwap> getSwaps() {
    if (!_isInitialized) return [];
    return List.unmodifiable(_swaps);
  }

  /// Get shift for date with swap overrides. Requires roster params for fallback.
  /// Returns ShiftLookupResult with shift and swap flags.
  static ShiftLookupResult getShiftForDate(
    DateTime date, {
    required DateTime? startDate,
    required int startWeek,
    String Function(DateTime)? rosterGetter,
  }) {
    if (!_isInitialized) {
      final shift = rosterGetter != null
          ? rosterGetter(date)
          : (startDate != null
              ? RosterService.getShiftForDate(date, startDate, startWeek)
              : '');
      return ShiftLookupResult(shift: shift);
    }

    final norm = DateTime(date.year, date.month, date.day);

    for (final s in _swaps) {
      if (_sameDate(s.workDate, norm)) {
        return ShiftLookupResult(shift: 'R', isSwappedRest: true);
      }
      if (_sameDate(s.restDate, norm)) {
        return ShiftLookupResult(shift: s.shiftType, isSwappedWork: true);
      }
    }

    final shift = rosterGetter != null
        ? rosterGetter(date)
        : (startDate != null
            ? RosterService.getShiftForDate(date, startDate, startWeek)
            : '');
    return ShiftLookupResult(shift: shift);
  }

  /// True if date is a swapped rest day (was work, now rest - show indicator).
  static bool isSwappedRestDay(DateTime date) {
    if (!_isInitialized) return false;
    final norm = DateTime(date.year, date.month, date.day);
    return _swaps.any((s) => _sameDate(s.workDate, norm));
  }

  /// True if date is a swapped work day (was rest, now work - NOT rest day rate).
  static bool isSwappedWorkDay(DateTime date) {
    if (!_isInitialized) return false;
    final norm = DateTime(date.year, date.month, date.day);
    return _swaps.any((s) => _sameDate(s.restDate, norm));
  }

  static Future<void> clearAll() async {
    _swaps = [];
    await _persist();
  }
}
