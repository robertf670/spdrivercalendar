import 'package:spdrivercalendar/features/calendar/utils/sick_day_display.dart';
import 'package:spdrivercalendar/models/event.dart';

/// Shortens long duty labels for the month-grid cell.
String formatCalendarDayDisplayText(String text) {
  if (text.startsWith('BusCheck')) {
    return text.replaceFirst('BusCheck', 'BUSC');
  }
  return text;
}

/// Resolves the text shown inside a calendar day cell.
///
/// Priority: sick code → spare/Union/Mentor → work-shift duty code → roster letter
/// (with swap superscript when applicable).
String calendarDayDisplayText({
  required List<Event> events,
  required String rosterShift,
  required bool showDutyCodesOnCalendar,
  required bool isSwappedRestDay,
  required bool isSwappedWorkDay,
}) {
  if (!showDutyCodesOnCalendar) {
    return _rosterShiftLabel(
      rosterShift: rosterShift,
      isSwappedRestDay: isSwappedRestDay,
      isSwappedWorkDay: isSwappedWorkDay,
    );
  }

  for (final event in events) {
    if (event.sickDayType != null) {
      final sickDayCode = SickDayDisplay.displayCode(event.sickDayType);
      if (sickDayCode.isNotEmpty) {
        return sickDayCode;
      }
    }
  }

  for (final event in events) {
    if (event.isWorkShift &&
        (event.title.startsWith('SP') ||
            event.title == '22B/01' ||
            event.title == 'Union' ||
            event.title == 'Mentor')) {
      return event.title;
    }
  }

  for (final event in events) {
    if (event.isWorkShift &&
        !event.title.startsWith('SP') &&
        event.title != '22B/01' &&
        event.title != 'Union' &&
        event.title != 'Mentor' &&
        !event.title.contains('(OT)')) {
      final dutyCodes = event.getCurrentDutyCodes();
      if (dutyCodes.isNotEmpty) {
        return formatCalendarDayDisplayText(dutyCodes.first);
      }
      return formatCalendarDayDisplayText(event.title);
    }
  }

  return _rosterShiftLabel(
    rosterShift: rosterShift,
    isSwappedRestDay: isSwappedRestDay,
    isSwappedWorkDay: isSwappedWorkDay,
  );
}

String _rosterShiftLabel({
  required String rosterShift,
  required bool isSwappedRestDay,
  required bool isSwappedWorkDay,
}) {
  if (rosterShift == 'R' && isSwappedRestDay) {
    return 'Rˢ';
  }
  if (isSwappedWorkDay && rosterShift.isNotEmpty) {
    return '${rosterShift}ˢ';
  }
  return rosterShift;
}
