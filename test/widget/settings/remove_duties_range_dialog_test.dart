import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/settings/dialogs/remove_duties_range_dialog.dart';
import 'package:spdrivercalendar/models/event.dart';

Event _duty(String id, DateTime date) {
  return Event(
    id: id,
    title: 'PZ2/04',
    startDate: date,
    endDate: date,
    startTime: const TimeOfDay(hour: 6, minute: 0),
    endTime: const TimeOfDay(hour: 14, minute: 0),
  );
}

void main() {
  testWidgets('fits 320px and confirms duties in the chosen range',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    List<Event>? removed;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () async {
                  removed = await showDialog<List<Event>>(
                    context: context,
                    builder: (_) => RemoveDutiesRangeDialog(
                      initialFrom: DateTime(2026, 12, 1),
                      initialTo: DateTime(2026, 12, 31),
                      loadEvents: () async => [
                        _duty('in', DateTime(2026, 12, 15)),
                        _duty('out', DateTime(2026, 11, 30)),
                      ],
                    ),
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final dialogRect = tester.getRect(find.byType(AlertDialog).first);
    expect(dialogRect.left, greaterThanOrEqualTo(0));
    expect(dialogRect.right, lessThanOrEqualTo(320));
    expect(find.text('1 Dec 2026'), findsOneWidget);
    expect(find.text('31 Dec 2026'), findsOneWidget);

    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    expect(find.textContaining('1 duty from 1 Dec 2026'), findsOneWidget);

    await tester.tap(find.text('Remove').last);
    await tester.pumpAndSettle();

    expect(removed, isNotNull);
    expect(removed!.map((e) => e.id), ['in']);
    expect(tester.takeException(), isNull);
  });
}
