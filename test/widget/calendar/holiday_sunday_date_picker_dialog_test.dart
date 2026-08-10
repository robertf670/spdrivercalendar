import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:spdrivercalendar/features/calendar/dialogs/holiday_sunday_date_picker_dialog.dart';

void main() {
  testWidgets('fits 320px, disables booked Sundays, and confirms selection',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final sundays = [
      DateTime(2026, 1, 4),
      DateTime(2026, 1, 11),
      DateTime(2026, 1, 18),
    ];
    DateTime? confirmed;
    var backTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HolidaySundayDatePickerDialog(
            title: 'Select Winter Holiday Start Date',
            subtitle: 'Year: 2026',
            icon: Icons.ac_unit,
            accent: Colors.blue,
            sundays: sundays,
            loadHasHolidayFlags: () async => [true, false, false],
            onBack: () {
              backTapped = true;
            },
            onConfirm: (date) async {
              confirmed = date;
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final dialogRect = tester.getRect(find.byType(AlertDialog));
    expect(dialogRect.left, greaterThanOrEqualTo(0));
    expect(dialogRect.right, lessThanOrEqualTo(320));
    expect(find.text('Select Winter Holiday Start Date'), findsOneWidget);
    expect(find.text('Already added'), findsOneWidget);

    await tester.tap(find.text(DateFormat('MMM d, yyyy').format(sundays[0])));
    await tester.pumpAndSettle();
    expect(confirmed, isNull);

    await tester.tap(find.text(DateFormat('MMM d, yyyy').format(sundays[1])));
    await tester.pumpAndSettle();
    expect(confirmed, sundays[1]);

    await tester.tap(find.text('Change Year'));
    await tester.pumpAndSettle();
    expect(backTapped, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows summer end preview line', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final sunday = DateTime(2026, 7, 5);
    final end = sunday.add(const Duration(days: 13));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HolidaySundayDatePickerDialog(
            title: 'Select Summer Holiday Start Date',
            subtitle: 'Year: 2026 • 1 Week',
            icon: Icons.wb_sunny,
            accent: Colors.orange,
            sundays: [sunday],
            loadHasHolidayFlags: () async => [false],
            onBack: () {},
            endPreviewFor: (date) => date.add(const Duration(days: 13)),
            onConfirm: (_) async {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.text('Ends: ${DateFormat('MMM d, yyyy').format(end)}'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
