import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/dialogs/multi_date_holiday_picker_dialog.dart';

void main() {
  testWidgets('fits 320px and confirms selected dates', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    List<DateTime>? confirmed;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MultiDateHolidayPickerDialog<int>(
            title: 'Select Holiday Dates',
            icon: Icons.event,
            accent: MultiDateHolidayPickerAccent.materialGreen(),
            confirmLabelSingular: 'Add Holiday',
            confirmLabelPlural: 'Add Holidays',
            onConfirm: (dates) async {
              confirmed = dates;
              return dates.length;
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final dialogRect = tester.getRect(find.byType(Dialog));
    expect(dialogRect.left, greaterThanOrEqualTo(0));
    expect(dialogRect.right, lessThanOrEqualTo(320));
    expect(find.text('Select Holiday Dates'), findsOneWidget);
    // Empty selection uses plural label (matches prior calendar-screen behaviour).
    expect(find.text('Add Holidays'), findsOneWidget);

    final disabledButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Add Holidays'),
    );
    expect(disabledButton.onPressed, isNull);

    final today = DateTime.now();
    await tester.tap(find.text('${today.day}').first);
    await tester.pumpAndSettle();

    expect(find.text('1 day selected'), findsOneWidget);
    expect(find.text('Add Holiday'), findsOneWidget);

    await tester.tap(find.text('Add Holiday'));
    await tester.pumpAndSettle();

    expect(confirmed, isNotNull);
    expect(confirmed, hasLength(1));
    expect(confirmed!.first.day, today.day);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows day-in-lieu balance header and warning', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MultiDateHolidayPickerDialog<int>(
            title: 'Select Day In Lieu Dates',
            icon: Icons.event_available,
            accent: MultiDateHolidayPickerAccent.solid(Colors.teal),
            confirmLabelSingular: 'Add Day In Lieu',
            confirmLabelPlural: 'Add Days In Lieu',
            topContent: const DayInLieuBalanceHeader(
              used: 3,
              remaining: 0,
            ),
            onConfirm: (_) async => 0,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Remaining'), findsOneWidget);
    expect(find.text('Used'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(DayInLieuBalanceHeader),
        matching: find.text('0'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(DayInLieuBalanceHeader),
        matching: find.text('3'),
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining('no days in lieu remaining'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
