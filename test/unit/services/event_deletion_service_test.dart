import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/services/event_deletion_service.dart';
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
  testWidgets('deletes local only when sync disabled', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    final context = tester.element(find.byType(SizedBox));

    var localDeletes = 0;
    var googleDeletes = 0;
    final service = EventDeletionService(
      deleteLocal: (_) async {
        localDeletes++;
      },
      isSyncEnabled: () async => false,
      isSignedIn: () async => true,
      deleteFromGoogle: ({
        required context,
        required title,
        eventStartTime,
      }) async {
        googleDeletes++;
        return true;
      },
    );

    await service.deleteEvent(
      event: _event(),
      context: context,
      isMounted: () => true,
    );

    expect(localDeletes, 1);
    expect(googleDeletes, 0);
  });

  testWidgets('also deletes from Google when enabled and signed in',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    final context = tester.element(find.byType(SizedBox));

    String? deletedTitle;
    final service = EventDeletionService(
      deleteLocal: (_) async {},
      isSyncEnabled: () async => true,
      isSignedIn: () async => true,
      deleteFromGoogle: ({
        required context,
        required title,
        eventStartTime,
      }) async {
        deletedTitle = title;
        return true;
      },
    );

    await service.deleteEvent(
      event: _event(),
      context: context,
      isMounted: () => true,
    );

    expect(deletedTitle, 'PZ1/01');
  });
}
