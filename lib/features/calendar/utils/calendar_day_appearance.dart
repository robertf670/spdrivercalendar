import 'package:flutter/material.dart';
import 'package:spdrivercalendar/models/event.dart';
import 'package:spdrivercalendar/models/holiday.dart';
import 'package:spdrivercalendar/models/shift_info.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';

/// Resolved presentation inputs for [CalendarDayCell].
class CalendarDayAppearance {
  const CalendarDayAppearance({
    required this.backgroundColor,
    required this.cellColor,
    required this.selectedBorderColor,
    required this.isDayInLieu,
    required this.isHoliday,
    required this.hasEvents,
    required this.hasNotes,
    required this.hasBankHolidayRedundant,
    required this.isBankHoliday,
  });

  final Color? backgroundColor;
  final Color cellColor;
  final Color selectedBorderColor;
  final bool isDayInLieu;
  final bool isHoliday;
  final bool hasEvents;
  final bool hasNotes;
  final bool hasBankHolidayRedundant;
  final bool isBankHoliday;
}

/// Resolves day-cell colours and badge flags from calendar day state.
///
/// Colour priority matches the previous CalendarScreen implementation:
/// sick → rest-on-holiday → day-in-lieu → unpaid → holiday → WFO → workout → shift.
CalendarDayAppearance resolveCalendarDayAppearance({
  required DateTime date,
  required List<Event> events,
  required String rosterShift,
  required Map<String, ShiftInfo> shiftInfoMap,
  required List<Holiday> holidays,
  required bool highlightWorkoutDays,
  required Set<DateTime>? workoutDates,
  required bool hasDayNote,
  required bool isBankHoliday,
  required bool isBankHolidayRedundantMarked,
  required Color dayInLieuColor,
  required Color workoutColor,
  required Color? Function(String? sickDayType) sickDayColor,
  required Color themePrimaryColor,
  required Color schemePrimaryColor,
  Color holidayColor = AppTheme.holidayColor,
  Color unpaidLeaveColor = Colors.purple,
}) {
  final hasEvents = events.isNotEmpty;
  final isHoliday = holidays.any((h) => h.containsDate(date));
  final isDayInLieu = holidays.any(
    (h) => h.containsDate(date) && h.type == 'day_in_lieu',
  );
  final isUnpaidLeave = holidays.any(
    (h) => h.containsDate(date) && h.type == 'unpaid_leave',
  );

  final hasWfoEvent = events.any((event) => event.isWorkForOthers);
  final wfoColor = shiftInfoMap['WFO']?.color;

  final dayKey = DateTime(date.year, date.month, date.day);
  final hasWorkoutOnDay =
      highlightWorkoutDays && workoutDates != null && workoutDates.contains(dayKey);

  final hasNotes =
      events.any((event) => event.hasNoteContent) || hasDayNote;

  final hasBankHolidayRedundant = isBankHoliday &&
      (isBankHolidayRedundantMarked ||
          events.any((e) => e.isWorkShift && e.bankHolidayRedundant));

  String? sickDayType;
  for (final event in events) {
    if (event.sickDayType != null) {
      sickDayType = event.sickDayType;
      break;
    }
  }
  final hasSickDay = sickDayType != null;
  final resolvedSickColor = hasSickDay ? sickDayColor(sickDayType) : null;

  final isRestDay = rosterShift == 'R';
  final restDayColor = shiftInfoMap['R']?.color;
  final useRestDayColorForHoliday = isRestDay &&
      restDayColor != null &&
      (isDayInLieu || isUnpaidLeave || isHoliday);

  final shiftInfo = shiftInfoMap[rosterShift];

  final Color? backgroundColor;
  final Color cellColor;

  if (hasSickDay && resolvedSickColor != null) {
    backgroundColor = resolvedSickColor.withValues(alpha: 0.3);
    cellColor = resolvedSickColor;
  } else if (useRestDayColorForHoliday) {
    backgroundColor = restDayColor.withValues(alpha: 0.3);
    cellColor = restDayColor;
  } else if (isDayInLieu) {
    backgroundColor = dayInLieuColor.withValues(alpha: 0.3);
    cellColor = dayInLieuColor;
  } else if (isUnpaidLeave) {
    backgroundColor = unpaidLeaveColor.withValues(alpha: 0.3);
    cellColor = unpaidLeaveColor;
  } else if (isHoliday) {
    backgroundColor = holidayColor.withValues(alpha: 0.3);
    cellColor = holidayColor;
  } else if (hasWfoEvent && wfoColor != null) {
    backgroundColor = wfoColor.withValues(alpha: 0.3);
    cellColor = wfoColor;
  } else if (hasWorkoutOnDay) {
    backgroundColor = workoutColor.withValues(alpha: 0.3);
    cellColor = workoutColor;
  } else {
    backgroundColor = shiftInfo?.color.withValues(alpha: 0.3);
    cellColor = shiftInfo?.color ?? themePrimaryColor;
  }

  return CalendarDayAppearance(
    backgroundColor: backgroundColor,
    cellColor: cellColor,
    selectedBorderColor:
        isBankHoliday ? Colors.red : schemePrimaryColor,
    isDayInLieu: isDayInLieu,
    isHoliday: isHoliday,
    hasEvents: hasEvents,
    hasNotes: hasNotes,
    hasBankHolidayRedundant: hasBankHolidayRedundant,
    isBankHoliday: isBankHoliday,
  );
}
