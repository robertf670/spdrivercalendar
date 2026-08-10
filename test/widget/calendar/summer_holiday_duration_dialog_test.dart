import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/dialogs/summer_holiday_duration_dialog.dart';

void main() {
  testWidgets('fits 320px and selects duration weeks', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    int? selectedWeeks;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SummerHolidayDurationDialog(
            onDurationSelected: (weeks) {
              selectedWeeks = weeks;
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final dialogRect = tester.getRect(find.byType(AlertDialog));
    expect(dialogRect.left, greaterThanOrEqualTo(0));
    expect(dialogRect.right, lessThanOrEqualTo(320));
    expect(find.text('Select Duration'), findsOneWidget);
    expect(find.text('1 Week'), findsOneWidget);
    expect(find.text('2 Weeks'), findsOneWidget);

    await tester.tap(find.text('2 Weeks'));
    await tester.pumpAndSettle();

    expect(selectedWeeks, 2);
    expect(tester.takeException(), isNull);
  });
}
