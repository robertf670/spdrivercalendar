import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/dialogs/holiday_year_picker_dialog.dart';

void main() {
  testWidgets('fits 320px, shows counts, and selects a year', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    int? selectedYear;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HolidayYearPickerDialog(
            title: 'Select Year for Winter Holiday',
            infoText: 'Select a year to choose your winter holiday start date',
            icon: Icons.ac_unit,
            accent: Colors.blue,
            startYear: 2026,
            loadHolidayCounts: () async => {2026: 1, 2027: 0},
            onYearSelected: (year) {
              selectedYear = year;
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final dialogRect = tester.getRect(find.byType(AlertDialog));
    expect(dialogRect.left, greaterThanOrEqualTo(0));
    expect(dialogRect.right, lessThanOrEqualTo(320));
    expect(find.text('Select Year for Winter Holiday'), findsOneWidget);
    expect(find.text('2026'), findsOneWidget);
    expect(find.text('1 holiday'), findsOneWidget);
    expect(find.text('2027'), findsOneWidget);

    await tester.tap(find.text('2027'));
    await tester.pumpAndSettle();

    expect(selectedYear, 2027);
    expect(tester.takeException(), isNull);
  });
}
