import 'package:spdrivercalendar/core/utils/location_utils.dart';

/// One duty row from a zone bill CSV.
class BillDuty {
  const BillDuty({
    required this.shift,
    required this.dutyNumber,
    required this.report,
    required this.depart,
    required this.location,
    required this.startBreak,
    required this.startBreakLocation,
    required this.breakReport,
    required this.finishBreak,
    required this.finishBreakLocation,
    required this.finish,
    required this.finishLocation,
    required this.signOff,
    required this.spread,
    required this.work,
    required this.relief,
    this.routes,
  });

  final String shift;
  final String dutyNumber;
  final String report;
  final String depart;
  final String location;
  final String startBreak;
  final String startBreakLocation;
  final String breakReport;
  final String finishBreak;
  final String finishBreakLocation;
  final String finish;
  final String finishLocation;
  final String signOff;
  final String spread;
  final String work;
  final String relief;
  final String? routes;

  bool get isWorkout {
    final value = startBreak.trim().toLowerCase();
    return value == 'workout' || value == 'nan' || value.isEmpty;
  }

  bool get hasMealBreak {
    if (isWorkout) return false;
    return !isBlank(startBreak);
  }

  bool get hasDistinctSignOff {
    final end = displayTime(signOff);
    final finishTime = displayTime(finish);
    return end.isNotEmpty && finishTime.isNotEmpty && end != finishTime;
  }

  String get displayReport => displayTime(report);
  String get displayDepart => displayTime(depart);
  String get displayFinish => displayTime(finish);
  String get displaySignOff {
    final sign = displayTime(signOff);
    if (sign.isNotEmpty) return sign;
    return displayFinish;
  }

  String get displaySpread => displayDuration(spread);
  String get displayWork => displayDuration(work);
  String get displayRelief => displayDuration(relief);

  String get takeUpLocation => mappedLocation(location);
  String get breakStartLocation => mappedLocation(startBreakLocation);
  String get breakEndLocation => mappedLocation(finishBreakLocation);
  String get endLocation => mappedLocation(finishLocation);

  String get displayStartBreak => displayTime(startBreak);
  String get displayFinishBreak => displayTime(finishBreak);
  String get displayBreakReport => displayTime(breakReport);

  String get routesLabel {
    final value = routes?.trim() ?? '';
    if (value.isEmpty || isBlank(value)) return '';
    return value;
  }

  /// The part after the slash, e.g. PZ1/67 → 67, PZ1/1X → 1X.
  String get shortCode {
    final slash = shift.lastIndexOf('/');
    if (slash < 0 || slash == shift.length - 1) return shift;
    return shift.substring(slash + 1);
  }

  String get timeRange {
    if (displayReport.isEmpty && displaySignOff.isEmpty) return '';
    if (displayReport.isEmpty) return displaySignOff;
    if (displaySignOff.isEmpty) return displayReport;
    return '$displayReport  →  $displaySignOff';
  }

  bool matchesQuery(String query) {
    final raw = query.trim().toLowerCase();
    if (raw.isEmpty) return true;
    final compact = raw.replaceAll(RegExp(r'\s+'), '');

    bool hit(String value) {
      if (value.isEmpty) return false;
      final lower = value.toLowerCase();
      if (lower.contains(raw)) return true;
      return lower.replaceAll(RegExp(r'\s+'), '').contains(compact);
    }

    return hit(shift) ||
        hit(dutyNumber) ||
        hit(displayReport) ||
        hit(displayDepart) ||
        hit(displayFinish) ||
        hit(displaySignOff) ||
        hit(displayStartBreak) ||
        hit(displayFinishBreak) ||
        hit(displayBreakReport) ||
        hit(report) ||
        hit(depart) ||
        hit(startBreak) ||
        hit(finishBreak) ||
        hit(finish) ||
        hit(signOff) ||
        hit(takeUpLocation) ||
        hit(breakStartLocation) ||
        hit(breakEndLocation) ||
        hit(endLocation) ||
        hit(location) ||
        hit(startBreakLocation) ||
        hit(finishBreakLocation) ||
        hit(finishLocation) ||
        hit(routesLabel);
  }

  static bool isBlank(String raw) {
    final value = raw.trim().toLowerCase();
    return value.isEmpty || value == 'nan';
  }

  static String mappedLocation(String raw) {
    if (isBlank(raw)) return '';
    return mapLocationName(raw.trim());
  }

  static String displayTime(String raw) {
    if (isBlank(raw)) return '';
    final value = raw.trim();
    if (value.toUpperCase() == 'WORKOUT') return 'W/O';
    final parts = value.split(':');
    if (parts.length >= 2 &&
        parts[0].isNotEmpty &&
        parts[1].isNotEmpty) {
      return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
    }
    return value;
  }

  static String displayDuration(String raw) {
    if (isBlank(raw)) return '';
    final parts = raw.trim().split(':');
    if (parts.length < 2) return raw.trim();
    final hours = int.tryParse(parts[0]) ?? 0;
    final minutes = int.tryParse(parts[1]) ?? 0;
    if (hours == 0 && minutes == 0) return '';
    if (hours == 0) return '${minutes}m';
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
  }
}
