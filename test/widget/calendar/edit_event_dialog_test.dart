import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/dialogs/edit_event_dialog.dart';
import 'package:spdrivercalendar/models/event.dart';

void main() {
  Event buildEvent() {
    return Event(
      id: '1',
      title: 'PZ1/01',
      startDate: DateTime(2026, 8, 4),
      startTime: const TimeOfDay(hour: 8, minute: 0),
      endDate: DateTime(2026, 8, 4),
      endTime: const TimeOfDay(hour: 16, minute: 0),
    );
  }

  testWidgets('fits 320px and exposes extracted edit actions', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var notes = false;
    var breakFinish = false;
    var sick = false;
    var deleted = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EditEventDialog(
            event: buildEvent(),
            displayTitle: 'PZ1/01',
            showBankHolidayRedundant: true,
            loadBoard: () async => null,
            onViewBoard: (_) {},
            onNotes: () => notes = true,
            onEditTraining: () async {},
            onBreakFinish: () => breakFinish = true,
            onSickDayStatus: () => sick = true,
            onBankHolidayRedundantChanged: (_) async {},
            onDelete: () async {
              deleted = true;
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final dialogRect = tester.getRect(find.byType(AlertDialog));
    expect(dialogRect.left, greaterThanOrEqualTo(0));
    expect(dialogRect.right, lessThanOrEqualTo(320));
    expect(find.text('Edit Event'), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);
    expect(find.text('Break & Finish'), findsOneWidget);
    expect(find.text('Sick Day Status'), findsOneWidget);
    expect(find.text('Bank holiday — redundant'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);

    await tester.tap(find.text('Notes'));
    await tester.pumpAndSettle();
    expect(notes, isTrue);

    await tester.tap(find.text('Break & Finish'));
    await tester.pumpAndSettle();
    expect(breakFinish, isTrue);

    await tester.tap(find.text('Sick Day Status'));
    await tester.pumpAndSettle();
    expect(sick, isTrue);

    await tester.ensureVisible(find.text('Delete'));
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(deleted, isTrue);
  });
}
