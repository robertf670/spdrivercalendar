import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:spdrivercalendar/features/calendar/services/google_calendar_event_sync_service.dart';
import 'package:spdrivercalendar/models/event.dart';

Event _event() {
  return Event(
    id: 'e1',
    title: 'PZ1/01',
    startDate: DateTime(2026, 8, 4),
    endDate: DateTime(2026, 8, 4),
    startTime: const TimeOfDay(hour: 5, minute: 0),
    endTime: const TimeOfDay(hour: 13, minute: 0),
  );
}

void main() {
  testWidgets('syncNewEvent skips when sync disabled', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    final context = tester.element(find.byType(SizedBox));

    var addCalls = 0;
    final service = GoogleCalendarEventSyncService(
      buildDescription: (_) async => 'desc',
      isSyncEnabled: () async => false,
      isSignedIn: () async => true,
      addWorkShift: ({
        required context,
        required title,
        required startTime,
        required endTime,
        description,
      }) async {
        addCalls++;
        return true;
      },
    );

    final added = await service.syncNewEvent(
      event: _event(),
      context: context,
      isMounted: () => true,
    );

    expect(added, isFalse);
    expect(addCalls, 0);
  });

  testWidgets('syncNewEvent adds when enabled and signed in', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    final context = tester.element(find.byType(SizedBox));

    String? addedTitle;
    String? addedDescription;
    final service = GoogleCalendarEventSyncService(
      buildDescription: (_) async => 'Break Times: 09:00',
      isSyncEnabled: () async => true,
      isSignedIn: () async => true,
      addWorkShift: ({
        required context,
        required title,
        required startTime,
        required endTime,
        description,
      }) async {
        addedTitle = title;
        addedDescription = description;
        return true;
      },
    );

    final added = await service.syncNewEvent(
      event: _event(),
      context: context,
      isMounted: () => true,
    );

    expect(added, isTrue);
    expect(addedTitle, 'PZ1/01');
    expect(addedDescription, 'Break Times: 09:00');
  });

  test('syncBusAssignments updates matching Google event description', () async {
    calendar.Event? updated;
    final existing = calendar.Event(
      id: 'g1',
      summary: 'PZ1/01',
      start: calendar.EventDateTime(
        dateTime: DateTime.utc(2026, 8, 4, 4, 0), // 05:00 IST / Dublin summer
      ),
      end: calendar.EventDateTime(
        dateTime: DateTime.utc(2026, 8, 4, 12, 0),
      ),
    );

    final service = GoogleCalendarEventSyncService(
      buildDescription: (_) async => 'Bus Assignment:\n1234',
      isSyncEnabled: () async => true,
      isSignedIn: () async => true,
      listEvents: ({required startTime, required endTime}) async => [existing],
      updateEvent: ({required eventId, required event}) async {
        updated = event;
      },
    );

    await service.syncBusAssignments(_event());

    expect(updated, isNotNull);
    expect(updated!.id, 'g1');
    expect(updated!.description, 'Bus Assignment:\n1234');
  });

  test('syncBusAssignments no-ops when not signed in', () async {
    var listCalls = 0;
    final service = GoogleCalendarEventSyncService(
      buildDescription: (_) async => 'desc',
      isSyncEnabled: () async => true,
      isSignedIn: () async => false,
      listEvents: ({required startTime, required endTime}) async {
        listCalls++;
        return const [];
      },
    );

    await service.syncBusAssignments(_event());
    expect(listCalls, 0);
  });
}
