import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/dialogs/booked_holidays_dialog.dart';
import 'package:spdrivercalendar/models/holiday.dart';

void main() {
  testWidgets('fits 320px and lists booked annual leave', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final holiday = Holiday(
      id: 'h1',
      type: 'summer',
      startDate: DateTime(2026, 7, 1),
      endDate: DateTime(2026, 7, 7),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BookedHolidaysDialog(
            holidayType: 'annualLeave',
            initialHolidays: [holiday],
            onDeleteHoliday: (_) async => const [],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final dialogRect = tester.getRect(find.byType(Dialog));
    expect(dialogRect.left, greaterThanOrEqualTo(0));
    expect(dialogRect.right, lessThanOrEqualTo(320));
    expect(find.text('Booked Annual Leave'), findsOneWidget);
    expect(find.text('Summer Holiday'), findsOneWidget);
    expect(find.textContaining('7 days'), findsOneWidget);
  });
}
