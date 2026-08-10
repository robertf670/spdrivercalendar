import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spdrivercalendar/features/calendar/services/roster_service.dart';
import 'package:spdrivercalendar/services/donnybrook_feature_service.dart';
import 'package:spdrivercalendar/services/jamestown_feature_service.dart';

typedef DutyCsvLoader = Future<String> Function(String assetPath);

/// Typed result for the duty times and metadata used when creating an event.
class DutyTimeLookupResult {
  const DutyTimeLookupResult({
    required this.startTime,
    required this.endTime,
    required this.isNextDay,
    this.breakStartTime,
    this.breakEndTime,
    this.workTime,
    this.routes = const [],
    this.hasExtendedDetails = true,
  });

  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final bool isNextDay;
  final TimeOfDay? breakStartTime;
  final TimeOfDay? breakEndTime;
  final Duration? workTime;
  final List<String> routes;

  /// Bus-check and training rows historically returned only basic time fields.
  final bool hasExtendedDetails;

  /// Temporary compatibility bridge while CalendarScreen call sites are
  /// migrated from their existing map contract.
  Map<String, dynamic> toLegacyMap() {
    final result = <String, dynamic>{
      'startTime': startTime,
      'endTime': endTime,
      'isNextDay': isNextDay,
    };
    if (hasExtendedDetails) {
      result.addAll({
        'breakStartTime': breakStartTime,
        'breakEndTime': breakEndTime,
        'workTime': workTime,
        'routes': routes,
      });
    }
    return result;
  }
}

/// Resolves bundled duty CSV rows into one consistent, tested result.
///
/// File-selection and parsing rules intentionally preserve the existing
/// CalendarScreen behavior. Remote CSV resolution is outside this phase.
class DutyTimeLookupService {
  DutyTimeLookupService._();

  static const _busCheckAsset = 'assets/buscheck.csv';
  static const _trainingAsset = 'assets/training_duties.csv';
  static const _uniSevenDayAsset = 'assets/UNI_7DAYs.csv';
  static const _uniWeekdayAsset = 'assets/UNI_M-F.csv';

  static Future<DutyTimeLookupResult?> lookup({
    required String zone,
    required String shiftNumber,
    required DateTime shiftDate,
    bool isOvertimeShift = false,
    DutyCsvLoader? csvLoader,
  }) async {
    final dayOfWeek = RosterService.getDayOfWeek(shiftDate);
    final loadCsv = csvLoader ?? rootBundle.loadString;

    try {
      if (zone == 'Uni/Euro') {
        return _lookupUni(
          shiftNumber: shiftNumber,
          dayOfWeek: dayOfWeek,
          loadCsv: loadCsv,
        );
      }

      final csvPath = _resolveAssetPath(
        zone: zone,
        shiftDate: shiftDate,
        dayOfWeek: dayOfWeek,
      );
      final csv = await loadCsv(csvPath);
      final lines = csv.split('\n');

      for (var index = 1; index < lines.length; index++) {
        final line = lines[index].trim().replaceAll('\r', '');
        if (line.isEmpty) continue;
        final parts = line.split(',');

        if (zone == 'Bus Check') {
          final result = _parseBusCheck(
            parts: parts,
            shiftNumber: shiftNumber,
            dayType: _busCheckDayType(dayOfWeek),
          );
          if (result != null) return result;
        } else if (zone == JamestownFeatureService.zoneLabel ||
            zone == 'Jamestown Road') {
          final result = _parseJamestown(
            parts: parts,
            shiftNumber: shiftNumber,
            isOvertimeShift: isOvertimeShift,
          );
          if (result != null) return result;
        } else if (zone == 'Training') {
          final result = _parseTraining(
            parts: parts,
            shiftNumber: shiftNumber,
          );
          if (result != null) return result;
        } else {
          final result = _parseRegularDuty(
            parts: parts,
            shiftNumber: shiftNumber,
            isOvertimeShift: isOvertimeShift,
          );
          if (result != null) return result;
        }
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  static Future<DutyTimeLookupResult?> _lookupUni({
    required String shiftNumber,
    required String dayOfWeek,
    required DutyCsvLoader loadCsv,
  }) async {
    final isWeekend = dayOfWeek == 'Saturday' || dayOfWeek == 'Sunday';
    final filesToTry = <String>[
      _uniSevenDayAsset,
      if (!isWeekend) _uniWeekdayAsset,
    ];

    for (final filePath in filesToTry) {
      try {
        final csv = await loadCsv(filePath);
        final lines = csv.split('\n');
        for (var index = 1; index < lines.length; index++) {
          final line = lines[index].trim().replaceAll('\r', '');
          if (line.isEmpty) continue;
          final result = _parseUni(
            parts: line.split(','),
            shiftNumber: shiftNumber,
          );
          if (result != null) return result;
        }
      } catch (_) {
        // Preserve the existing fallback to the next applicable UNI file.
      }
    }

    return null;
  }

  static String _resolveAssetPath({
    required String zone,
    required DateTime shiftDate,
    required String dayOfWeek,
  }) {
    if (zone == 'Bus Check') return _busCheckAsset;
    if (zone == JamestownFeatureService.zoneLabel) {
      return JamestownFeatureService.duties30HrCsvAsset;
    }
    if (zone == 'Jamestown Road') {
      return JamestownFeatureService.dutiesMainCsvAsset;
    }
    if (zone == DonnybrookFeatureService.zoneLabel) {
      return DonnybrookFeatureService.resolveDutyCsvAsset(shiftDate);
    }
    if (zone == 'Training') return _trainingAsset;

    final zoneNumber = zone.replaceAll('Zone ', '');
    final dayForFilename = switch (dayOfWeek) {
      'Saturday' => 'SAT',
      'Sunday' => 'SUN',
      _ => 'M-F',
    };
    final filename = RosterService.getShiftFilename(
      zoneNumber,
      dayForFilename,
      shiftDate,
    );
    return 'assets/$filename';
  }

  static DutyTimeLookupResult? _parseBusCheck({
    required List<String> parts,
    required String shiftNumber,
    required String dayType,
  }) {
    if (parts.length < 4 ||
        parts[0].trim() != shiftNumber ||
        parts[1].trim() != dayType) {
      return null;
    }
    return _basicResult(
      startTime: parseTimeOfDay(parts[2].trim()),
      endTime: parseTimeOfDay(parts[3].trim()),
    );
  }

  static DutyTimeLookupResult? _parseTraining({
    required List<String> parts,
    required String shiftNumber,
  }) {
    if (parts.length < 5 || parts[0].trim() != shiftNumber) return null;
    return _basicResult(
      startTime: parseTimeOfDay(parts[1].trim()),
      endTime: parseTimeOfDay(parts[2].trim()),
    );
  }

  static DutyTimeLookupResult? _parseUni({
    required List<String> parts,
    required String shiftNumber,
  }) {
    if (parts.length < 15 || parts[0].trim() != shiftNumber) return null;

    final startTime = parseTimeOfDay(parts[2].trim());
    final endTime = parseTimeOfDay(parts[10].trim());
    if (startTime == null || endTime == null) return null;

    final breakTimes = _parseBreakTimes(
      start: _part(parts, 5),
      end: _part(parts, 8),
      equalTimesAreWorkout: true,
    );
    final route = _part(parts, 16);

    return DutyTimeLookupResult(
      startTime: startTime,
      endTime: endTime,
      isNextDay: _isNextDay(startTime, endTime),
      breakStartTime: breakTimes.$1,
      breakEndTime: breakTimes.$2,
      workTime: _parseDuration(_part(parts, 14)),
      routes: _validValue(route) ? [route] : const [],
    );
  }

  static DutyTimeLookupResult? _parseJamestown({
    required List<String> parts,
    required String shiftNumber,
    required bool isOvertimeShift,
  }) {
    if (parts.length < 17 || parts[0].trim() != shiftNumber) return null;

    final startTime = parseTimeOfDay(
      parts[isOvertimeShift ? 3 : 2].trim(),
    );
    final endTime = parseTimeOfDay(parts[10].trim());
    if (startTime == null || endTime == null) return null;

    final breakTimes = _parseBreakTimes(
      start: _part(parts, 5),
      end: _part(parts, 8),
      equalTimesAreWorkout: true,
    );
    final route = _part(parts, 16);

    return DutyTimeLookupResult(
      startTime: startTime,
      endTime: endTime,
      isNextDay: _isNextDay(startTime, endTime),
      breakStartTime: breakTimes.$1,
      breakEndTime: breakTimes.$2,
      workTime: _parseDuration(_part(parts, 14)),
      routes: _validValue(route) ? [route] : const [],
    );
  }

  static DutyTimeLookupResult? _parseRegularDuty({
    required List<String> parts,
    required String shiftNumber,
    required bool isOvertimeShift,
  }) {
    if (parts.length < 15 || parts[0].trim() != shiftNumber) return null;

    final startTime = parseTimeOfDay(
      parts[isOvertimeShift ? 3 : 2].trim(),
    );
    final endTime = parseTimeOfDay(parts[12].trim());
    if (startTime == null || endTime == null) return null;

    final startBreak = _part(parts, 5);
    final finishBreak = _part(parts, 8);
    final isWorkout = !_validBreak(startBreak) || !_validBreak(finishBreak);
    final routes = _extractRegularRoutes(
      parts: parts,
      isWorkout: isWorkout,
    );

    return DutyTimeLookupResult(
      startTime: startTime,
      endTime: endTime,
      isNextDay: _isNextDay(startTime, endTime),
      breakStartTime: isWorkout ? null : parseTimeOfDay(startBreak),
      breakEndTime: isWorkout ? null : parseTimeOfDay(finishBreak),
      workTime: _parseDuration(_part(parts, 14)),
      routes: routes,
    );
  }

  static DutyTimeLookupResult? _basicResult({
    required TimeOfDay? startTime,
    required TimeOfDay? endTime,
  }) {
    if (startTime == null || endTime == null) return null;
    return DutyTimeLookupResult(
      startTime: startTime,
      endTime: endTime,
      isNextDay: _isNextDay(startTime, endTime),
      hasExtendedDetails: false,
    );
  }

  static (TimeOfDay?, TimeOfDay?) _parseBreakTimes({
    required String start,
    required String end,
    required bool equalTimesAreWorkout,
  }) {
    final isWorkout = !_validBreak(start) ||
        !_validBreak(end) ||
        (equalTimesAreWorkout && start == end);
    if (isWorkout) return (null, null);
    return (parseTimeOfDay(start), parseTimeOfDay(end));
  }

  static List<String> _extractRegularRoutes({
    required List<String> parts,
    required bool isWorkout,
  }) {
    final startLocation = _part(parts, 4);
    final breakStartLocation = _part(parts, 6);
    final breakFinishLocation = _part(parts, 9);
    final finishLocation = _part(parts, 11);
    final routes = <String>[];

    if (isWorkout) {
      final route = _extractRoute(startLocation) ??
          _extractRoute(finishLocation) ??
          _extractRoute(breakStartLocation);
      if (route != null) routes.add(route);
      return routes;
    }

    final firstRoute =
        _extractRoute(breakStartLocation) ?? _extractRoute(startLocation);
    final secondRoute =
        _extractRoute(breakFinishLocation) ?? _extractRoute(finishLocation);
    if (firstRoute != null) routes.add(firstRoute);
    if (secondRoute != null && !routes.contains(secondRoute)) {
      routes.add(secondRoute);
    }
    return routes;
  }

  static String? _extractRoute(String location) {
    if (location.isEmpty ||
        location.toLowerCase() == 'nan' ||
        location.toUpperCase() == 'GARAGE') {
      return null;
    }
    final dashIndex = location.indexOf('-');
    if (dashIndex > 0) {
      final route = location.substring(0, dashIndex);
      if (route.contains('/')) {
        return RegExp(r'([A-Z]+)').firstMatch(route)?.group(1);
      }
      return route;
    }
    return RegExp(r'\((\d+)\)').firstMatch(location)?.group(1);
  }

  static String _busCheckDayType(String dayOfWeek) {
    return switch (dayOfWeek) {
      'Saturday' => 'SAT',
      'Sunday' => 'SUN',
      _ => 'MF',
    };
  }

  static bool _isNextDay(TimeOfDay startTime, TimeOfDay endTime) {
    return endTime.hour < startTime.hour ||
        (endTime.hour == startTime.hour && endTime.minute < startTime.minute);
  }

  static bool _validBreak(String value) {
    return _validValue(value) && value.toLowerCase() != 'workout';
  }

  static bool _validValue(String value) {
    return value.isNotEmpty && value.toLowerCase() != 'nan';
  }

  static String _part(List<String> parts, int index) {
    return parts.length > index ? parts[index].trim() : '';
  }

  static Duration? _parseDuration(String value) {
    if (!_validValue(value)) return null;
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final hours = int.tryParse(parts[0]);
    final minutes = int.tryParse(parts[1]);
    if (hours == null || minutes == null) return null;
    return Duration(hours: hours, minutes: minutes);
  }

  static TimeOfDay? parseTimeOfDay(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      final parts = value.split(':');
      if (parts.length < 2) return null;
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) return null;
      if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
      return TimeOfDay(hour: hour, minute: minute);
    } catch (_) {
      return null;
    }
  }
}
