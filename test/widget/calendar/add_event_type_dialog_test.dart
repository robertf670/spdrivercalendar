import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/dialogs/add_event_type_dialog.dart';

void main() {
  Future<void> pumpDialog(
    WidgetTester tester, {
    Size surfaceSize = const Size(320, 800),
    bool showBankHolidaySection = false,
    bool hasWorkShiftOnDay = false,
    bool isDayOnlyRedundant = false,
    bool showWorkForOthers = false,
    bool showSwapRestDay = false,
    Future<void> Function(bool marked)? onToggleDayOnlyRedundant,
    VoidCallback? onNormalEvent,
    VoidCallback? onWorkShift,
    VoidCallback? onOvertime,
    VoidCallback? onWorkForOthers,
    VoidCallback? onSwapRestDay,
  }) async {
    await tester.binding.setSurfaceSize(surfaceSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AddEventTypeDialog(
            showBankHolidaySection: showBankHolidaySection,
            hasWorkShiftOnDay: hasWorkShiftOnDay,
            isDayOnlyRedundant: isDayOnlyRedundant,
            showWorkForOthers: showWorkForOthers,
            showSwapRestDay: showSwapRestDay,
            onToggleDayOnlyRedundant:
                onToggleDayOnlyRedundant ?? (_) async {},
            onNormalEvent: onNormalEvent ?? () {},
            onWorkShift: onWorkShift ?? () {},
            onOvertime: onOvertime ?? () {},
            onWorkForOthers: onWorkForOthers ?? () {},
            onSwapRestDay: onSwapRestDay ?? () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('fits a 320px viewport with core actions', (tester) async {
    await pumpDialog(tester);

    final dialogRect = tester.getRect(find.byType(AlertDialog));
    expect(dialogRect.left, greaterThanOrEqualTo(0));
    expect(dialogRect.right, lessThanOrEqualTo(320));
    expect(find.text('Add Event'), findsOneWidget);
    expect(find.text('Normal Event'), findsOneWidget);
    expect(find.text('Work Shift'), findsOneWidget);
    expect(find.text('Overtime'), findsOneWidget);
    expect(find.text('Work For Others'), findsNothing);
    expect(find.text('Swap Rest Day'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows optional actions and invokes callbacks', (tester) async {
    var normalCalls = 0;
    var workShiftCalls = 0;
    var overtimeCalls = 0;
    var workForOthersCalls = 0;
    var swapCalls = 0;

    await pumpDialog(
      tester,
      surfaceSize: const Size(400, 800),
      showWorkForOthers: true,
      showSwapRestDay: true,
      onNormalEvent: () => normalCalls++,
      onWorkShift: () => workShiftCalls++,
      onOvertime: () => overtimeCalls++,
      onWorkForOthers: () => workForOthersCalls++,
      onSwapRestDay: () => swapCalls++,
    );

    await tester.tap(find.text('Normal Event'));
    await tester.tap(find.text('Work Shift'));
    await tester.tap(find.text('Overtime'));
    await tester.tap(find.text('Work For Others'));
    await tester.tap(find.text('Swap Rest Day'));
    await tester.pump();

    expect(normalCalls, 1);
    expect(workShiftCalls, 1);
    expect(overtimeCalls, 1);
    expect(workForOthersCalls, 1);
    expect(swapCalls, 1);
  });

  testWidgets('shows bank-holiday guidance when a work shift exists', (
    tester,
  ) async {
    await pumpDialog(
      tester,
      showBankHolidaySection: true,
      hasWorkShiftOnDay: true,
    );

    expect(find.text('Bank holiday redundant'), findsOneWidget);
    expect(find.byType(SwitchListTile), findsNothing);
  });

  testWidgets('toggles day-only redundant marking when no work shift', (
    tester,
  ) async {
    final toggles = <bool>[];

    await pumpDialog(
      tester,
      showBankHolidaySection: true,
      hasWorkShiftOnDay: false,
      isDayOnlyRedundant: false,
      onToggleDayOnlyRedundant: (marked) async {
        toggles.add(marked);
      },
    );

    expect(find.text('Bank holiday redundant (day off)'), findsOneWidget);
    final switchFinder = find.byType(Switch);
    await tester.ensureVisible(switchFinder);
    await tester.pumpAndSettle();
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();
    expect(toggles, [true]);
  });
}
