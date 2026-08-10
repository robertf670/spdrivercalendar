import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/widgets/existing_holidays_section.dart';
import 'package:spdrivercalendar/models/holiday.dart';

void main() {
  testWidgets('fits 320px, expands year, and deletes a holiday', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    Holiday? deleted;
    var afterDelete = false;

    final holidays = [
      Holiday(
        id: 'w1',
        startDate: DateTime(2026, 12, 20),
        endDate: DateTime(2026, 12, 26),
        type: 'winter',
      ),
      Holiday(
        id: 'o1',
        startDate: DateTime(2026, 3, 1),
        endDate: DateTime(2026, 3, 1),
        type: 'other',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ExistingHolidaysSection(
              holidays: holidays,
              onDeleteHoliday: (holiday) async {
                deleted = holiday;
              },
              onAfterDelete: () {
                afterDelete = true;
              },
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Existing Holidays'), findsOneWidget);
    expect(find.textContaining('2 holidays across 1 year'), findsOneWidget);
    expect(find.text('2026'), findsOneWidget);

    // Collapsed by default — holiday titles hidden until expand.
    expect(find.text('Winter Holiday'), findsNothing);

    await tester.tap(find.text('2026'));
    await tester.pumpAndSettle();

    expect(find.text('Winter Holiday'), findsOneWidget);
    expect(find.text('Holiday'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pumpAndSettle();
    expect(find.text('Remove Holiday'), findsOneWidget);

    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    expect(deleted?.id, 'o1');
    expect(afterDelete, isTrue);
    expect(find.textContaining('Holiday removed successfully'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
