import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/utils/calendar_day_display_text.dart';
import 'package:spdrivercalendar/models/event.dart';

Event _event({
  required String title,
  String? sickDayType,
}) {
  return Event(
    id: 'e1',
    title: title,
    startDate: DateTime(2026, 8, 4),
    endDate: DateTime(2026, 8, 4),
    startTime: const TimeOfDay(hour: 5, minute: 0),
    endTime: const TimeOfDay(hour: 13, minute: 0),
    sickDayType: sickDayType,
  );
}

void main() {
  test('shortens BusCheck labels', () {
    expect(formatCalendarDayDisplayText('BusCheck 1'), 'BUSC 1');
    expect(formatCalendarDayDisplayText('PZ1/01'), 'PZ1/01');
  });

  test('when duty codes disabled, returns roster letter with swap mark', () {
    expect(
      calendarDayDisplayText(
        events: [_event(title: 'PZ1/01')],
        rosterShift: 'E',
        showDutyCodesOnCalendar: false,
        isSwappedRestDay: false,
        isSwappedWorkDay: true,
      ),
      'Eˢ',
    );
  });

  test('sick day code beats duty title', () {
    expect(
      calendarDayDisplayText(
        events: [
          _event(title: 'PZ1/01', sickDayType: 'self-certified'),
        ],
        rosterShift: 'E',
        showDutyCodesOnCalendar: true,
        isSwappedRestDay: false,
        isSwappedWorkDay: false,
      ),
      'SC',
    );
  });

  test('spare and Union titles are shown as-is', () {
    expect(
      calendarDayDisplayText(
        events: [_event(title: 'SP0515')],
        rosterShift: 'E',
        showDutyCodesOnCalendar: true,
        isSwappedRestDay: false,
        isSwappedWorkDay: false,
      ),
      'SP0515',
    );
    expect(
      calendarDayDisplayText(
        events: [_event(title: 'Union')],
        rosterShift: 'E',
        showDutyCodesOnCalendar: true,
        isSwappedRestDay: false,
        isSwappedWorkDay: false,
      ),
      'Union',
    );
  });

  test('regular work shift shows duty title', () {
    expect(
      calendarDayDisplayText(
        events: [_event(title: 'PZ1/74')],
        rosterShift: 'E',
        showDutyCodesOnCalendar: true,
        isSwappedRestDay: false,
        isSwappedWorkDay: false,
      ),
      'PZ1/74',
    );
  });

  test('overtime alone falls back to roster letter', () {
    expect(
      calendarDayDisplayText(
        events: [_event(title: 'PZ1/01A (OT)')],
        rosterShift: 'R',
        showDutyCodesOnCalendar: true,
        isSwappedRestDay: true,
        isSwappedWorkDay: false,
      ),
      'Rˢ',
    );
  });
}
