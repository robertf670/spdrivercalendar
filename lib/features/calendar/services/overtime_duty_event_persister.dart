import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spdrivercalendar/features/calendar/services/duty_time_lookup_service.dart';
import 'package:spdrivercalendar/features/calendar/services/event_service.dart';
import 'package:spdrivercalendar/features/calendar/services/roster_service.dart';
import 'package:spdrivercalendar/features/calendar/utils/overtime_duty_title.dart';
import 'package:spdrivercalendar/features/calendar/utils/overtime_half_timing.dart';
import 'package:spdrivercalendar/models/event.dart';
import 'package:uuid/uuid.dart';

typedef OvertimeTimesLookup = Future<Map<String, dynamic>?> Function(
  String zone,
  String shiftNumber,
  DateTime shiftDate, {
  bool isOvertimeShift,
});

typedef OvertimeEventSink = Future<void> Function(Event event);
typedef OvertimeCsvLoader = Future<String> Function(String assetPath);
typedef OvertimeIdFactory = String Function();

/// Outcome of persisting an overtime duty selection.
enum OvertimeDutyPersistStatus {
  success,
  shiftTimesUnavailable,
  error,
}

class OvertimeDutyPersistResult {
  const OvertimeDutyPersistResult({
    required this.status,
    this.event,
    this.title,
    this.error,
  });

  final OvertimeDutyPersistStatus status;
  final Event? event;
  final String? title;
  final Object? error;
}

/// Builds and saves an overtime half-duty event from a picker selection.
///
/// Dialog dismiss / snackbars / calendar refresh stay with the caller.
class OvertimeDutyEventPersister {
  OvertimeDutyEventPersister({
    required OvertimeTimesLookup lookupShiftTimes,
    OvertimeEventSink? addEvent,
    OvertimeCsvLoader? loadCsv,
    OvertimeIdFactory? idFactory,
    TimeOfDay? Function(String? value)? parseTimeOfDay,
  })  : _lookupShiftTimes = lookupShiftTimes,
        _addEvent = addEvent ?? EventService.addEvent,
        _loadCsv = loadCsv ?? rootBundle.loadString,
        _idFactory = idFactory ?? (() => const Uuid().v4()),
        _parseTimeOfDay =
            parseTimeOfDay ?? DutyTimeLookupService.parseTimeOfDay;

  final OvertimeTimesLookup _lookupShiftTimes;
  final OvertimeEventSink _addEvent;
  final OvertimeCsvLoader _loadCsv;
  final OvertimeIdFactory _idFactory;
  final TimeOfDay? Function(String? value) _parseTimeOfDay;

  Future<OvertimeDutyPersistResult> persist({
    required String overtimeHalfType,
    required DateTime shiftDate,
    required String selectedZone,
    required String selectedShiftNumber,
  }) async {
    final isEATypeTraining = selectedShiftNumber.contains('EA Type Training');
    final title = buildOvertimeDutyTitle(
      selectedShiftNumber: selectedShiftNumber,
      overtimeHalfType: overtimeHalfType,
    );

    try {
      final shiftTimes = await _resolveShiftTimes(
        selectedZone: selectedZone,
        selectedShiftNumber: selectedShiftNumber,
        shiftDate: shiftDate,
      );
      if (shiftTimes == null) {
        return OvertimeDutyPersistResult(
          status: OvertimeDutyPersistStatus.shiftTimesUnavailable,
          title: title,
        );
      }

      final startTime = shiftTimes['startTime'] as TimeOfDay;
      final endTime = shiftTimes['endTime'] as TimeOfDay;
      var breakStartTime = shiftTimes['breakStartTime'] as TimeOfDay?;
      var breakEndTime = shiftTimes['breakEndTime'] as TimeOfDay?;

      if (!isEATypeTraining &&
          (breakStartTime == null || breakEndTime == null)) {
        final fallback = await _lookupBreakTimesFromCsv(
          selectedZone: selectedZone,
          selectedShiftNumber: selectedShiftNumber,
          shiftDate: shiftDate,
        );
        breakStartTime ??= fallback.$1;
        breakEndTime ??= fallback.$2;
      }

      final adjusted = adjustOvertimeHalfTimes(
        startTime: startTime,
        endTime: endTime,
        overtimeHalfType: overtimeHalfType,
        breakStartTime: breakStartTime,
        breakEndTime: breakEndTime,
        isEATypeTraining: isEATypeTraining,
      );

      final event = Event(
        id: _idFactory(),
        title: title,
        startDate: shiftDate,
        startTime: adjusted.startTime,
        endDate: shiftDate,
        endTime: adjusted.endTime,
        workTime: Duration(
          hours: (adjusted.endTime.hour - adjusted.startTime.hour) % 24,
          minutes: (adjusted.endTime.minute - adjusted.startTime.minute) % 60,
        ),
      );

      await _addEvent(event);

      return OvertimeDutyPersistResult(
        status: OvertimeDutyPersistStatus.success,
        event: event,
        title: title,
      );
    } catch (e) {
      return OvertimeDutyPersistResult(
        status: OvertimeDutyPersistStatus.error,
        title: title,
        error: e,
      );
    }
  }

  Future<Map<String, dynamic>?> _resolveShiftTimes({
    required String selectedZone,
    required String selectedShiftNumber,
    required DateTime shiftDate,
  }) async {
    if (selectedZone == 'Spare') {
      final parts = selectedShiftNumber.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final startTime = TimeOfDay(hour: hour, minute: minute);
      final endHour = (hour + 4) % 24;
      final endTime = TimeOfDay(hour: endHour, minute: minute);
      return {
        'startTime': startTime,
        'endTime': endTime,
      };
    }

    return _lookupShiftTimes(
      selectedZone.replaceAll('Zone ', ''),
      selectedShiftNumber,
      shiftDate,
      isOvertimeShift: true,
    );
  }

  /// Preserves the prior CalendarScreen CSV break fallback when lookup has none.
  Future<(TimeOfDay?, TimeOfDay?)> _lookupBreakTimesFromCsv({
    required String selectedZone,
    required String selectedShiftNumber,
    required DateTime shiftDate,
  }) async {
    TimeOfDay? breakStartTime;
    TimeOfDay? breakEndTime;

    final dayOfWeek = RosterService.getDayOfWeek(shiftDate);
    final csvFilename = selectedZone == 'Uni/Euro'
        ? 'UNI_7DAYs.csv'
        : RosterService.getShiftFilename(
            selectedZone.replaceAll('Zone ', ''),
            dayOfWeek == 'Saturday'
                ? 'SAT'
                : dayOfWeek == 'Sunday'
                    ? 'SUN'
                    : 'M-F',
            shiftDate,
          );

    try {
      final csv = await _loadCsv('assets/$csvFilename');
      final lines = csv.split('\n');

      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        final parts = line.split(',');
        if (parts.isEmpty || parts[0].trim() != selectedShiftNumber) {
          continue;
        }

        if (selectedZone == 'Uni/Euro') {
          if (parts.length >= 5) {
            final breakStartStr = parts[2].trim();
            final breakEndStr = parts[3].trim();
            if (breakStartStr.toLowerCase() != 'nan' &&
                breakEndStr.toLowerCase() != 'nan') {
              breakStartTime ??= _parseTimeOfDay(breakStartStr);
              breakEndTime ??= _parseTimeOfDay(breakEndStr);
            }
          }
        } else if (parts.length >= 9) {
          final breakStartStr = parts[5].trim();
          final breakEndStr = parts[8].trim();
          if (breakStartStr.toLowerCase() != 'nan' &&
              breakStartStr.toLowerCase() != 'workout' &&
              breakEndStr.toLowerCase() != 'nan' &&
              breakEndStr.toLowerCase() != 'workout') {
            breakStartTime ??= _parseTimeOfDay(breakStartStr);
            breakEndTime ??= _parseTimeOfDay(breakEndStr);
          }
        }
        break;
      }

      if (selectedZone == 'Uni/Euro' &&
          breakStartTime == null &&
          dayOfWeek != 'Saturday' &&
          dayOfWeek != 'Sunday') {
        final csvMF = await _loadCsv('assets/UNI_M-F.csv');
        final linesMF = csvMF.split('\n');
        for (final line in linesMF) {
          if (line.trim().isEmpty) continue;
          final parts = line.split(',');
          if (parts.isEmpty || parts[0].trim() != selectedShiftNumber) {
            continue;
          }
          if (parts.length >= 5) {
            final breakStartStr = parts[2].trim();
            final breakEndStr = parts[3].trim();
            if (breakStartStr.toLowerCase() != 'nan' &&
                breakEndStr.toLowerCase() != 'nan') {
              breakStartTime = _parseTimeOfDay(breakStartStr);
              breakEndTime = _parseTimeOfDay(breakEndStr);
            }
          }
          break;
        }
      }
    } catch (_) {
      // Preserve silent CSV failure behaviour from the calendar screen.
    }

    return (breakStartTime, breakEndTime);
  }
}
