import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/dialogs/event_duty_notes_dialog.dart';
import 'package:spdrivercalendar/models/event.dart';

void main() {
  late Event event;

  setUp(() {
    event = Event(
      id: 'event-1',
      title: 'PZ1/42',
      startDate: DateTime(2026, 7, 23),
      startTime: const TimeOfDay(hour: 8, minute: 0),
      endDate: DateTime(2026, 7, 23),
      endTime: const TimeOfDay(hour: 16, minute: 0),
      notes: 'Existing note',
    );
  });

  testWidgets('fits a 320px viewport and closes without persisting', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var saveCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (_) => EventDutyNotesDialog(
                      event: event,
                      scaffoldContext: context,
                      onSave: (notes, imagePaths) async {
                        saveCalls++;
                      },
                    ),
                  );
                },
                child: const Text('Open notes'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open notes'));
    await tester.pumpAndSettle();

    final dialogRect = tester.getRect(find.byType(Dialog));
    expect(dialogRect.left, greaterThanOrEqualTo(0));
    expect(dialogRect.right, lessThanOrEqualTo(320));
    expect(dialogRect.top, greaterThanOrEqualTo(0));
    expect(dialogRect.bottom, lessThanOrEqualTo(800));
    expect(find.text('Existing note'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.byType(EventDutyNotesDialog), findsNothing);
    expect(saveCalls, 0);
    expect(tester.takeException(), isNull);
  });
}
