import 'package:spdrivercalendar/core/utils/location_utils.dart';
import 'package:spdrivercalendar/features/calendar/services/zone2_duties.dart';

/// Meal vs walking time from duty CSV columns.
///
/// Only Zone 1 and Route 13. Walking time is garage → a different take-up,
/// or a different meal point → garage take-up. [breakreport] is when the
/// meal ends; [finishbreak] is take-up. The gap is walk, not extra break.
class DutyBreakClock {
  DutyBreakClock._();

  static final _walkSuffix = RegExp(r'\s+walk\s+(\d+)m\b', caseSensitive: false);
  static final _timePair = RegExp(r'(\d{1,2}:\d{2})\s*-\s*(\d{1,2}:\d{2})');

  static const workout = 'Workout';
  static const noBreak = 'No break';
  static const noBreakInfo = 'No break info';

  static String fromCsvParts(
    List<String> parts, {
    bool equalTimesAreWorkout = false,
  }) {
    if (parts.length < 6) return noBreakInfo;
    return fromTimes(
      startBreak: _cell(parts, 5),
      breakReport: _cell(parts, 7),
      finishBreak: _cell(parts, 8),
      startLocation: _cell(parts, 6),
      finishLocation: _cell(parts, 9),
      shiftCode: _cell(parts, 0),
      equalTimesAreWorkout: equalTimesAreWorkout,
    );
  }

  static bool walkingTimeApplies(String shiftCode) {
    final code = shiftCode.trim();
    if (code.isEmpty) return false;
    if (Zone2Duties.isRoute13Code(code)) return true;
    final upper = code.toUpperCase();
    if (upper.startsWith('PZ1/')) return true;
    return RegExp(r'^1/\S+$').hasMatch(code);
  }

  static String fromTimes({
    required String startBreak,
    required String breakReport,
    required String finishBreak,
    String startLocation = '',
    String finishLocation = '',
    String shiftCode = '',
    bool equalTimesAreWorkout = false,
  }) {
    if (_isWorkoutToken(startBreak) || _isWorkoutToken(finishBreak)) {
      return workout;
    }

    final start = _parseClock(startBreak);
    final finish = _parseClock(finishBreak);
    if (start == null || finish == null) return workout;

    if (equalTimesAreWorkout && start.sameClock(finish)) {
      return workout;
    }

    final report = _parseClock(breakReport);
    final walk = walkingTimeApplies(shiftCode)
        ? _walkMinutes(
            report: report,
            finish: finish,
            startLocation: startLocation,
            finishLocation: finishLocation,
          )
        : null;

    if (start.sameClock(finish)) {
      return equalTimesAreWorkout ? workout : noBreak;
    }

    final range = '${start.format()} - ${finish.format()}';
    if (walk == null) return range;
    return '$range walk ${walk}m';
  }

  /// `18:38 - 19:45` with any walk suffix removed.
  static String clockRange(String breakTime) {
    final match = _timePair.firstMatch(breakTime);
    if (match == null) return breakTime;
    return '${match.group(1)} - ${match.group(2)}';
  }

  static int? walkMinutes(String breakTime) {
    final match = _walkSuffix.firstMatch(breakTime);
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }

  /// Meal duration, plus walk when present. Compact drops the space in `1h 7m`.
  static String? durationParen(String breakTime, {required bool compact}) {
    if (breakTime.toLowerCase().contains('workout')) return null;
    final match = _timePair.firstMatch(breakTime);
    if (match == null) return null;

    final start = _parseClock(match.group(1)!);
    final end = _parseClock(match.group(2)!);
    if (start == null || end == null) return null;

    final span = _minutesBetween(start, end);
    if (span == null || span <= 0) return null;

    final walk = walkMinutes(breakTime) ?? 0;
    final meal = span - walk;
    if (meal <= 0) return _formatDuration(span, compact: compact);
    final mealLabel = _formatDuration(meal, compact: compact);
    if (walk <= 0) return mealLabel;
    return '$mealLabel, ${walk}m walk';
  }

  static String formatLine({
    required String breakTime,
    String? startLocation,
    String? endLocation,
    required bool compact,
  }) {
    if (breakTime.toLowerCase().contains('workout')) return workout;

    var clock = clockRange(breakTime);
    if (compact) clock = clock.replaceFirst(' - ', '–');
    final buffer = StringBuffer();
    final start = startLocation?.trim() ?? '';
    final end = endLocation?.trim() ?? '';
    if (start.isNotEmpty) buffer.write('$start ');
    buffer.write(clock);
    if (end.isNotEmpty) buffer.write(' $end');

    final paren = durationParen(breakTime, compact: compact);
    if (paren != null) buffer.write(' ($paren)');
    return buffer.toString();
  }

  /// First-half end / second-half start for OT overlays.
  /// Clock end is take-up, including walking duties.
  static (String start, String end)? overlayTimes(String breakTime) {
    final match = _timePair.firstMatch(breakTime);
    if (match == null) return null;
    return (match.group(1)!, match.group(2)!);
  }

  static String _cell(List<String> parts, int index) {
    if (index >= parts.length) return '';
    return parts[index].trim();
  }

  static bool _isWorkoutToken(String raw) {
    final value = raw.trim().toLowerCase();
    return value.isEmpty ||
        value == 'nan' ||
        value == 'workout' ||
        value == 'n/a';
  }

  static _Clock? _parseClock(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (minute < 0 || minute > 59) return null;
    return _Clock(rawHour: hour, minute: minute);
  }

  static int? _walkMinutes({
    required _Clock? report,
    required _Clock finish,
    required String startLocation,
    required String finishLocation,
  }) {
    if (report == null) return null;
    if (!_isGarageWalkPair(startLocation, finishLocation)) return null;
    final minutes = _minutesBetween(report, finish);
    if (minutes == null || minutes <= 0) return null;
    return minutes;
  }

  /// Garage meal + street take-up, or street meal + garage take-up.
  static bool _isGarageWalkPair(String startLocation, String finishLocation) {
    if (startLocation.trim().isEmpty || finishLocation.trim().isEmpty) {
      return false;
    }
    final startGarage = _isGarage(startLocation);
    final finishGarage = _isGarage(finishLocation);
    return startGarage != finishGarage;
  }

  static bool _isGarage(String location) {
    final mapped = mapLocationName(location.trim()).trim().toLowerCase();
    if (mapped == 'garage') return true;
    final raw = location.trim().toUpperCase();
    return raw == 'GARAGE' ||
        raw == 'GAR' ||
        raw.startsWith('GARAGE(') ||
        raw.startsWith('PHIBPO') ||
        raw.startsWith('PHIBPI');
  }

  static int? _minutesBetween(_Clock start, _Clock end) {
    var minutes = end.totalMinutes - start.totalMinutes;
    if (minutes < 0) minutes += 24 * 60;
    return minutes;
  }

  static String _formatDuration(int minutes, {required bool compact}) {
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final remaining = minutes % 60;
    if (remaining == 0) return '${hours}h';
    if (compact) return '${hours}h$remaining';
    return '${hours}h ${remaining}m';
  }
}

class _Clock {
  const _Clock({required this.rawHour, required this.minute});

  final int rawHour;
  final int minute;

  int get displayHour {
    var hour = rawHour;
    while (hour >= 24) {
      hour -= 24;
    }
    while (hour < 0) {
      hour += 24;
    }
    return hour;
  }

  int get totalMinutes => rawHour * 60 + minute;

  bool sameClock(_Clock other) =>
      displayHour == other.displayHour && minute == other.minute;

  String format() {
    final hour = displayHour.toString().padLeft(2, '0');
    final min = minute.toString().padLeft(2, '0');
    return '$hour:$min';
  }
}
