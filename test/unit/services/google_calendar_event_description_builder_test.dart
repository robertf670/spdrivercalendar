import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/core/constants/app_constants.dart';
import 'package:spdrivercalendar/features/calendar/services/google_calendar_event_description_builder.dart';
import 'package:spdrivercalendar/models/event.dart';

Event _event({
  String title = 'PZ1/01',
  bool isWorkForOthers = false,
  String? sickDayType,
  String? firstHalfBus,
  String? secondHalfBus,
  Map<String, String>? busAssignments,
}) {
  return Event(
    id: 'e1',
    title: title,
    startDate: DateTime(2026, 8, 4),
    endDate: DateTime(2026, 8, 4),
    startTime: const TimeOfDay(hour: 5, minute: 0),
    endTime: const TimeOfDay(hour: 13, minute: 0),
    isWorkForOthers: isWorkForOthers,
    sickDayType: sickDayType,
    firstHalfBus: firstHalfBus,
    secondHalfBus: secondHalfBus,
    busAssignments: busAssignments,
  );
}

void main() {
  test('includes break, WFO, sick day, and bus lines with links', () async {
    final prefs = <String, bool>{
      AppConstants.includeBusAssignmentsInGoogleCalendarKey: true,
      AppConstants.includeBustimesLinksInGoogleCalendarKey: true,
    };

    final description = await GoogleCalendarEventDescriptionBuilder.build(
      event: _event(
        isWorkForOthers: true,
        sickDayType: 'normal',
        firstHalfBus: '1234',
        secondHalfBus: '5678',
      ),
      getBreakTime: (_) async => '09:00-10:00',
      isWorkingOnRestDay: (_) => true,
      busUrlLookup: (bus) async => 'https://bustimes.org/$bus',
      readBool: (key, {required defaultValue}) async =>
          prefs[key] ?? defaultValue,
    );

    expect(description, contains('Break Times: 09:00-10:00'));
    expect(description, contains('(Work For Others)'));
    expect(description, isNot(contains('(Working on Rest Day)')));
    expect(description, contains('Sick Day: Normal Sick Day'));
    expect(description, contains('First Half: 1234 (https://bustimes.org/1234)'));
    expect(description, contains('Second Half: 5678 (https://bustimes.org/5678)'));
  });

  test('marks working on rest day when not WFO', () async {
    final description = await GoogleCalendarEventDescriptionBuilder.build(
      event: _event(),
      getBreakTime: (_) async => null,
      isWorkingOnRestDay: (_) => true,
      readBool: (key, {required defaultValue}) async => false,
    );

    expect(description, '(Working on Rest Day)');
  });

  test('formats workout bus as a single Bus line', () async {
    final line = await GoogleCalendarEventDescriptionBuilder.formatBusAssignment(
      event: _event(title: 'Workout', firstHalfBus: '9999'),
      busUrlLookup: (_) async => null,
      readBool: (key, {required defaultValue}) async => true,
    );

    expect(line, 'Bus: 9999');
  });
}
