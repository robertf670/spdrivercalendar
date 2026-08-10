import 'package:flutter/material.dart';
import 'package:spdrivercalendar/core/constants/app_constants.dart';
import 'package:spdrivercalendar/core/constants/training_constants.dart';
import 'package:spdrivercalendar/features/calendar/dialogs/work_shift_dialog.dart';
import 'package:spdrivercalendar/features/calendar/services/event_service.dart';
import 'package:spdrivercalendar/features/calendar/services/roster_service.dart';
import 'package:spdrivercalendar/features/calendar/services/shift_service.dart';
import 'package:spdrivercalendar/features/calendar/utils/work_shift_title.dart';
import 'package:spdrivercalendar/features/calendar/widgets/custom_training_form.dart';
import 'package:spdrivercalendar/models/bank_holiday.dart';
import 'package:spdrivercalendar/models/event.dart';
import 'package:spdrivercalendar/services/donnybrook_feature_service.dart';
import 'package:spdrivercalendar/services/jamestown_feature_service.dart';

typedef WorkShiftTimesLookup = Future<Map<String, dynamic>?> Function(
  String zone,
  String shiftNumber,
  DateTime shiftDate,
);

typedef WorkShiftEventSink = Future<void> Function(Event event);
typedef WorkShiftEventsForDay = List<Event> Function(DateTime date);
typedef WorkShiftBankHolidayLookup = BankHoliday? Function(DateTime date);
typedef WorkShiftCreatedCallback = Future<void> Function(Event event);

/// Outcome of persisting an Add Work Shift selection.
enum WorkShiftPersistStatus {
  success,
  missingCustomTrainingTimes,
  shiftTimesUnavailable,
}

class WorkShiftPersistResult {
  const WorkShiftPersistResult({
    required this.status,
    this.primaryEvent,
  });

  final WorkShiftPersistStatus status;
  final Event? primaryEvent;
}

/// Creates work-shift events (including weekly / roster auto-fill repeats).
///
/// UI (dialog dismiss, snackbars, setState) stays with the caller.
class WorkShiftEventPersister {
  WorkShiftEventPersister({
    required WorkShiftTimesLookup lookupShiftTimes,
    WorkShiftEventSink? addEvent,
    WorkShiftEventsForDay? eventsForDay,
    WorkShiftBankHolidayLookup? bankHolidayForDate,
    WorkShiftCreatedCallback? onEventCreated,
    DateTime Function()? now,
  })  : _lookupShiftTimes = lookupShiftTimes,
        _addEvent = addEvent ?? EventService.addEvent,
        _eventsForDay = eventsForDay ?? EventService.getEventsForDay,
        _bankHolidayForDate = bankHolidayForDate ??
            ((date) =>
                ShiftService.getBankHoliday(date, ShiftService.bankHolidays)),
        _onEventCreated = onEventCreated,
        _now = now ?? DateTime.now;

  final WorkShiftTimesLookup _lookupShiftTimes;
  final WorkShiftEventSink _addEvent;
  final WorkShiftEventsForDay _eventsForDay;
  final WorkShiftBankHolidayLookup _bankHolidayForDate;
  final WorkShiftCreatedCallback? _onEventCreated;
  final DateTime Function() _now;

  Future<WorkShiftPersistResult> persist({
    required DateTime shiftDate,
    required WorkShiftDialogSelection selection,
    required bool isMFMarkedIn,
    required bool isShiftMarkedIn,
    required String markedInZone,
    required bool jamestownEnabled,
  }) async {
    final selectedZone = selection.selectedZone;
    final selectedShiftNumber = selection.selectedShiftNumber;
    final title = buildWorkShiftTitle(
      selectedZone: selectedZone,
      selectedShiftNumber: selectedShiftNumber,
    );

    final shiftTimes = await _resolveShiftTimes(
      selectedZone: selectedZone,
      selectedShiftNumber: selectedShiftNumber,
      shiftDate: shiftDate,
      customTrainingData: selection.customTrainingData,
    );

    if (shiftTimes == null) {
      if (selectedZone == 'Training' &&
          selectedShiftNumber == TrainingConstants.customTrainingShiftOption &&
          selection.customTrainingData == null) {
        return const WorkShiftPersistResult(
          status: WorkShiftPersistStatus.missingCustomTrainingTimes,
        );
      }
      return const WorkShiftPersistResult(
        status: WorkShiftPersistStatus.shiftTimesUnavailable,
      );
    }

    final customTrainingData = selection.customTrainingData;
    final event = Event(
      id: _now().millisecondsSinceEpoch.toString(),
      title: title,
      startDate: shiftDate,
      startTime: shiftTimes['startTime']!,
      endDate: shiftTimes['isNextDay'] == true
          ? shiftDate.add(const Duration(days: 1))
          : shiftDate,
      endTime: shiftTimes['endTime']!,
      breakStartTime: shiftTimes['breakStartTime'] as TimeOfDay?,
      breakEndTime: shiftTimes['breakEndTime'] as TimeOfDay?,
      workTime: shiftTimes['workTime'] as Duration?,
      routes: shiftTimes['routes'] as List<String>?,
      trainingDescription: customTrainingData?.description,
      startLocation: customTrainingData?.location,
    );

    await _addEvent(event);

    if (selection.repeatUniEuroThisWeek &&
        isMFMarkedIn &&
        selectedZone == 'Uni/Euro') {
      await _repeatUniEuroThisWeek(
        shiftDate: shiftDate,
        title: title,
        selectedZone: selectedZone,
        selectedShiftNumber: selectedShiftNumber,
        selection: selection,
        fallbackShiftTimes: shiftTimes,
      );
    }

    final isJamestownRepeatZone =
        selectedZone == JamestownFeatureService.zoneLabel;
    final isRepeatableDutyZone = selectedZone == 'Zone 1' ||
        selectedZone == 'Zone 2' ||
        selectedZone == 'Zone 3' ||
        selectedZone == 'Zone 4' ||
        selectedZone == DonnybrookFeatureService.zoneLabel ||
        (isJamestownRepeatZone && jamestownEnabled);
    final zoneMatchesMarkedIn = selectedZone == markedInZone ||
        (isMFMarkedIn && isJamestownRepeatZone && jamestownEnabled);
    if (selection.repeatDutyThisWeek &&
        (isShiftMarkedIn || isMFMarkedIn) &&
        isRepeatableDutyZone &&
        zoneMatchesMarkedIn) {
      await _repeatDutyThisWeek(
        shiftDate: shiftDate,
        title: title,
        selectedZone: selectedZone,
        selectedShiftNumber: selectedShiftNumber,
        selection: selection,
        fallbackShiftTimes: shiftTimes,
      );
    }

    if (selection.fillNext12Weeks &&
        isMFMarkedIn &&
        selectedZone == 'Zone 1') {
      await _fillZone1MfRoster(
        shiftDate: shiftDate,
        selectedZone: selectedZone,
        selectedShiftNumber: selectedShiftNumber,
      );
    }

    if (AppConstants.enableZone1ShiftDutyRosterAutoFill &&
        selection.fillNext15Weeks &&
        isShiftMarkedIn &&
        selectedZone == 'Zone 1') {
      await _fillZone1ShiftRoster(
        shiftDate: shiftDate,
        selectedZone: selectedZone,
        selectedShiftNumber: selectedShiftNumber,
      );
    }

    if (selection.fillNext10Weeks &&
        isShiftMarkedIn &&
        selectedZone == 'Zone 3') {
      await _fillZone3ShiftRoster(
        shiftDate: shiftDate,
        selectedZone: selectedZone,
        selectedShiftNumber: selectedShiftNumber,
      );
    }

    await _notifyCreated(event);

    return WorkShiftPersistResult(
      status: WorkShiftPersistStatus.success,
      primaryEvent: event,
    );
  }

  Future<Map<String, dynamic>?> _resolveShiftTimes({
    required String selectedZone,
    required String selectedShiftNumber,
    required DateTime shiftDate,
    required CustomTrainingFormData? customTrainingData,
  }) async {
    if (selectedZone == '22B/01') {
      return {
        'startTime': const TimeOfDay(hour: 4, minute: 30),
        'endTime': const TimeOfDay(hour: 10, minute: 0),
      };
    }
    if (selectedZone == 'Union' || selectedZone == 'Mentor') {
      return {
        'startTime': const TimeOfDay(hour: 9, minute: 0),
        'endTime': const TimeOfDay(hour: 15, minute: 0),
      };
    }
    if (selectedZone == 'Spare') {
      return _spareShiftTimes(selectedShiftNumber);
    }
    if (selectedZone == 'Training' &&
        selectedShiftNumber == TrainingConstants.customTrainingShiftOption) {
      if (customTrainingData == null) return null;
      return customTrainingShiftTimes(customTrainingData);
    }
    return _lookupShiftTimes(selectedZone, selectedShiftNumber, shiftDate);
  }

  Map<String, dynamic> _spareShiftTimes(String selectedShiftNumber) {
    final timeParts = selectedShiftNumber.split(':');
    if (timeParts.length == 2) {
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      var endHour = hour + 8;
      var endMinute = minute + 38;
      if (endMinute >= 60) {
        endHour += 1;
        endMinute -= 60;
      }
      if (endHour >= 24) {
        endHour -= 24;
      }
      return {
        'startTime': TimeOfDay(hour: hour, minute: minute),
        'endTime': TimeOfDay(hour: endHour, minute: endMinute),
      };
    }
    return {
      'startTime': const TimeOfDay(hour: 4, minute: 0),
      'endTime': const TimeOfDay(hour: 12, minute: 38),
    };
  }

  Future<void> _repeatUniEuroThisWeek({
    required DateTime shiftDate,
    required String title,
    required String selectedZone,
    required String selectedShiftNumber,
    required WorkShiftDialogSelection selection,
    required Map<String, dynamic> fallbackShiftTimes,
  }) async {
    final weekday = shiftDate.weekday;
    final daysToSunday = weekday == 7 ? 0 : weekday;
    final weekStart = shiftDate.subtract(Duration(days: daysToSunday));

    for (var dayIndex = 1; dayIndex <= 5; dayIndex++) {
      if (!(selection.uniEuroSelectedDays[dayIndex] ?? false)) continue;
      final targetDate = weekStart.add(Duration(days: dayIndex));
      if (_isSameDay(targetDate, shiftDate)) continue;
      if (_eventsForDay(targetDate).any((e) => e.title == title)) continue;
      if (_bankHolidayForDate(targetDate) != null) continue;

      final targetShiftTimes =
          await _lookupShiftTimes(selectedZone, selectedShiftNumber, targetDate);
      final finalShiftTimes = targetShiftTimes ?? fallbackShiftTimes;

      final weekEvent = Event(
        id: '${title}_${targetDate.millisecondsSinceEpoch}',
        title: title,
        startDate: targetDate,
        startTime: finalShiftTimes['startTime']!,
        endDate: finalShiftTimes['isNextDay'] == true
            ? targetDate.add(const Duration(days: 1))
            : targetDate,
        endTime: finalShiftTimes['endTime']!,
        breakStartTime: finalShiftTimes['breakStartTime'] as TimeOfDay?,
        breakEndTime: finalShiftTimes['breakEndTime'] as TimeOfDay?,
        workTime: finalShiftTimes['workTime'] as Duration?,
        routes: finalShiftTimes['routes'] as List<String>?,
      );

      await _addEvent(weekEvent);
      await _notifyCreated(weekEvent);
    }
  }

  Future<void> _repeatDutyThisWeek({
    required DateTime shiftDate,
    required String title,
    required String selectedZone,
    required String selectedShiftNumber,
    required WorkShiftDialogSelection selection,
    required Map<String, dynamic> fallbackShiftTimes,
  }) async {
    final weekday = shiftDate.weekday;
    final daysToSunday = weekday == 7 ? 0 : weekday;
    final weekStart = shiftDate.subtract(Duration(days: daysToSunday));

    for (var dayIndex = 1; dayIndex <= 5; dayIndex++) {
      if (!(selection.selectedDays[dayIndex] ?? false)) continue;
      final targetDate = weekStart.add(Duration(days: dayIndex));
      if (_isSameDay(targetDate, shiftDate)) continue;
      if (_eventsForDay(targetDate).any((e) => e.title == title)) continue;

      Map<String, dynamic>? targetShiftTimes;
      if (selectedZone == 'Zone 1' ||
          selectedZone == 'Zone 2' ||
          selectedZone == 'Zone 3' ||
          selectedZone == 'Zone 4' ||
          selectedZone == DonnybrookFeatureService.zoneLabel ||
          selectedZone == JamestownFeatureService.zoneLabel) {
        targetShiftTimes = await _lookupShiftTimes(
          selectedZone,
          selectedShiftNumber,
          targetDate,
        );
      }
      final finalShiftTimes = targetShiftTimes ?? fallbackShiftTimes;

      final repeatEvent = Event(
        id: '${title}_${targetDate.millisecondsSinceEpoch}',
        title: title,
        startDate: targetDate,
        startTime: finalShiftTimes['startTime']!,
        endDate: finalShiftTimes['isNextDay'] == true
            ? targetDate.add(const Duration(days: 1))
            : targetDate,
        endTime: finalShiftTimes['endTime']!,
        breakStartTime: finalShiftTimes['breakStartTime'] as TimeOfDay?,
        breakEndTime: finalShiftTimes['breakEndTime'] as TimeOfDay?,
        workTime: finalShiftTimes['workTime'] as Duration?,
        routes: finalShiftTimes['routes'] as List<String>?,
      );

      await _addEvent(repeatEvent);
      await _notifyCreated(repeatEvent);
    }
  }

  Future<void> _fillZone1MfRoster({
    required DateTime shiftDate,
    required String selectedZone,
    required String selectedShiftNumber,
  }) async {
    await RosterService.loadZone1MFRoster();
    final weekIndex = RosterService.getZone1MFWeekIndex(selectedShiftNumber);
    if (weekIndex == null) return;

    final anchorMonday = RosterService.getMondayOfWeek(shiftDate);
    for (var w = 0; w < 12; w++) {
      final weekStart = anchorMonday.add(Duration(days: w * 7));
      for (var d = 0; d < 5; d++) {
        final targetDate = weekStart.add(Duration(days: d));
        if (_isSameDay(targetDate, shiftDate)) continue;
        if (_eventsForDay(targetDate).any((e) => !e.isHoliday)) continue;
        if (_bankHolidayForDate(targetDate) != null) continue;
        final dutyIndex = (weekIndex + w) % 12;
        final dutyCode = RosterService.getZone1MFDutyForWeekIndex(dutyIndex);
        if (dutyCode == null) continue;
        final targetShiftTimes =
            await _lookupShiftTimes(selectedZone, dutyCode, targetDate);
        if (targetShiftTimes == null) continue;
        final rosterEvent = _eventFromTimes(
          id: '${dutyCode}_${targetDate.millisecondsSinceEpoch}',
          title: dutyCode,
          date: targetDate,
          times: targetShiftTimes,
        );
        await _addEvent(rosterEvent);
        await _notifyCreated(rosterEvent);
      }
    }
  }

  Future<void> _fillZone1ShiftRoster({
    required DateTime shiftDate,
    required String selectedZone,
    required String selectedShiftNumber,
  }) async {
    await RosterService.loadZone1ShiftRoster();
    final dayIndex = shiftDate.weekday % 7;
    final weekIndex =
        RosterService.getZone1ShiftWeekIndex(dayIndex, selectedShiftNumber);
    if (weekIndex == null) return;

    final weekStartSunday = RosterService.getSundayOfWeek(shiftDate);
    for (var w = 0; w < 15; w++) {
      for (var d = 0; d < 7; d++) {
        final targetDate = weekStartSunday.add(Duration(days: w * 7 + d));
        if (_isSameDay(targetDate, shiftDate)) continue;
        final duty =
            RosterService.getZone1ShiftDayDuty((weekIndex + w) % 86, d);
        if (duty == null || duty == 'R') continue;
        if (_eventsForDay(targetDate).any((e) => !e.isHoliday)) continue;
        if (_bankHolidayForDate(targetDate) != null) continue;
        if (RosterService.isSaturdayService(targetDate)) continue;
        final targetShiftTimes =
            await _lookupShiftTimes(selectedZone, duty, targetDate);
        if (targetShiftTimes == null) continue;
        final rosterEvent = _eventFromTimes(
          id: '${duty}_${targetDate.millisecondsSinceEpoch}',
          title: duty,
          date: targetDate,
          times: targetShiftTimes,
        );
        await _addEvent(rosterEvent);
        await _notifyCreated(rosterEvent);
      }
    }
  }

  Future<void> _fillZone3ShiftRoster({
    required DateTime shiftDate,
    required String selectedZone,
    required String selectedShiftNumber,
  }) async {
    await RosterService.loadZone3ShiftRoster();
    final dayIndex = shiftDate.weekday % 7;
    final weekIndex =
        RosterService.getZone3ShiftWeekIndex(dayIndex, selectedShiftNumber);
    if (weekIndex == null) return;

    final weekStartSunday = RosterService.getSundayOfWeek(shiftDate);
    for (var w = 0; w < 10; w++) {
      for (var d = 0; d < 7; d++) {
        final targetDate = weekStartSunday.add(Duration(days: w * 7 + d));
        if (_isSameDay(targetDate, shiftDate)) continue;
        final duty =
            RosterService.getZone3ShiftDayDuty((weekIndex + w) % 10, d);
        if (duty == null || duty == 'R') continue;
        if (_eventsForDay(targetDate).any((e) => !e.isHoliday)) continue;
        if (_bankHolidayForDate(targetDate) != null) continue;
        if (RosterService.isSaturdayService(targetDate)) continue;
        final targetShiftTimes =
            await _lookupShiftTimes(selectedZone, duty, targetDate);
        if (targetShiftTimes == null) continue;
        final rosterEvent = _eventFromTimes(
          id: '${duty}_${targetDate.millisecondsSinceEpoch}',
          title: duty,
          date: targetDate,
          times: targetShiftTimes,
        );
        await _addEvent(rosterEvent);
        await _notifyCreated(rosterEvent);
      }
    }
  }

  Event _eventFromTimes({
    required String id,
    required String title,
    required DateTime date,
    required Map<String, dynamic> times,
  }) {
    return Event(
      id: id,
      title: title,
      startDate: date,
      startTime: times['startTime']!,
      endDate: times['isNextDay'] == true
          ? date.add(const Duration(days: 1))
          : date,
      endTime: times['endTime']!,
      breakStartTime: times['breakStartTime'] as TimeOfDay?,
      breakEndTime: times['breakEndTime'] as TimeOfDay?,
      workTime: times['workTime'] as Duration?,
      routes: times['routes'] as List<String>?,
    );
  }

  Future<void> _notifyCreated(Event event) async {
    final callback = _onEventCreated;
    if (callback != null) {
      await callback(event);
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
