/// Emulator/device smoke suite for Spare Driver Calendar.
///
/// Covers launch/navigation plus the Step 8 feature flows that were extracted
/// into dialogs/helpers (add-event type picker, overtime half, rest-day swap,
/// work-for-others entry, edit/status dialogs).
///
/// Run (PowerShell):
/// ```
/// flutter test integration_test/app_smoke_test.dart -d emulator-5554 --reporter expanded
/// ```
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:spdrivercalendar/features/calendar/widgets/calendar_grid.dart';

import 'support/smoke_test_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('calendar smoke: navigation and extracted feature flows', (
    tester,
  ) async {
    await launchAppForSmokeTest(tester);

    expect(find.byType(CalendarGrid), findsOneWidget);
    expect(find.byTooltip('Week View'), findsOneWidget);
    expect(find.byTooltip('Search Shifts'), findsOneWidget);

    // --- Navigation ---
    await tester.tap(find.byIcon(Icons.chevron_right));
    await pumpFor(tester, const Duration(milliseconds: 800));
    await dismissTransientDialogs(tester);
    expect(find.byType(CalendarGrid), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_left));
    await pumpFor(tester, const Duration(milliseconds: 800));
    expect(find.byType(CalendarGrid), findsOneWidget);

    await selectVisibleDay(tester);

    await tester.tap(find.byTooltip('Week View'));
    await pumpFor(tester, const Duration(seconds: 1));
    await waitForFinder(tester, find.text('Week View'));
    await tester.pageBack();
    await pumpFor(tester, const Duration(seconds: 1));
    await waitForFinder(tester, find.byType(CalendarGrid));

    await tester.tap(find.byTooltip('Search Shifts'));
    await pumpFor(tester, const Duration(seconds: 1));
    await waitForFinder(tester, find.text('Search Shifts'));
    await tester.pageBack();
    await pumpFor(tester, const Duration(seconds: 1));
    await waitForFinder(tester, find.byType(CalendarGrid));

    await tester.tap(find.byIcon(Icons.settings));
    await pumpFor(tester, const Duration(milliseconds: 500));
    await tester.tap(find.text('Settings'));
    await pumpFor(tester, const Duration(seconds: 1));
    await waitForFinder(tester, find.text('Settings'));
    await tester.pageBack();
    await pumpFor(tester, const Duration(seconds: 1));
    await waitForFinder(tester, find.byType(CalendarGrid));

    // --- Add Event type dialog ---
    await selectVisibleDay(tester);
    await openAddEventDialog(tester);
    expect(find.text('Normal Event'), findsOneWidget);
    expect(find.text('Work Shift'), findsOneWidget);
    expect(find.text('Overtime'), findsOneWidget);
    expect(find.text('Swap Rest Day'), findsOneWidget);

    // --- Overtime half picker ---
    await tester.tap(find.text('Overtime'));
    await pumpFor(tester, const Duration(milliseconds: 700));
    await waitForFinder(tester, find.text('Select Overtime Half'));
    expect(find.text('First Half'), findsOneWidget);
    expect(find.text('Second Half'), findsOneWidget);
    await dismissOpenDialog(tester);
    await waitForFinder(tester, find.byType(CalendarGrid));

    // --- Rest day swap picker / feedback ---
    await openAddEventDialog(tester);
    await tester.tap(find.text('Swap Rest Day'));
    await pumpFor(tester, const Duration(milliseconds: 900));
    final swapPicker = find.textContaining('Swap with');
    final removeSwap = find.text('Remove rest day swap');
    final noSwapSnack = find.textContaining('No suitable day to swap');
    final selectDaySnack = find.textContaining('Select a work day or rest day');
    expect(
      swapPicker.evaluate().isNotEmpty ||
          removeSwap.evaluate().isNotEmpty ||
          noSwapSnack.evaluate().isNotEmpty ||
          selectDaySnack.evaluate().isNotEmpty,
      isTrue,
      reason: 'Expected swap UI or snackbar. Texts: ${visibleTexts(tester)}',
    );
    if (swapPicker.evaluate().isNotEmpty || removeSwap.evaluate().isNotEmpty) {
      await dismissOpenDialog(tester);
    }
    await pumpFor(tester, const Duration(milliseconds: 500));

    // --- Work For Others (scan nearby days for a rest day) ---
    var foundWorkForOthers = false;
    for (var dayIndex = 5; dayIndex < 20; dayIndex++) {
      await selectVisibleDay(tester, index: dayIndex);
      await openAddEventDialog(tester);
      if (find.text('Work For Others').evaluate().isNotEmpty) {
        foundWorkForOthers = true;
        await tester.tap(find.text('Work For Others'));
        await pumpFor(tester, const Duration(milliseconds: 900));
        await waitForFinder(
          tester,
          find.textContaining('Add Work For Others'),
          timeout: const Duration(seconds: 10),
        );
        expect(find.text('Zone:'), findsOneWidget);
        expect(find.text('Add Shift'), findsOneWidget);
        await dismissOpenDialog(tester);
        break;
      }
      await dismissOpenDialog(tester);
    }
    expect(
      foundWorkForOthers,
      isTrue,
      reason: 'Could not find a rest day offering Work For Others',
    );

    // --- Normal event + Edit Event entry ---
    await selectVisibleDay(tester, index: 12);
    await openAddEventDialog(tester);
    await tester.tap(find.text('Normal Event'));
    await pumpFor(tester, const Duration(milliseconds: 700));
    await waitForFinder(tester, find.widgetWithText(TextButton, 'Save'));
    await tester.enterText(find.byType(TextFormField).first, 'Smoke Normal');
    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await pumpFor(tester, const Duration(seconds: 1));
    await waitForFinder(tester, find.textContaining('Smoke Normal'));

    await openEditEventFromDayDetail(tester, 'Smoke Normal');
    expect(find.text('Notes'), findsOneWidget);
    await dismissOpenDialog(tester);

    // --- Break / sick status dialogs via seeded work shift ---
    await seedSmokeWorkShiftEvent();
    await refreshCalendarViaSettings(tester);
    await selectToday(tester);
    await openEditEventFromDayDetail(tester, 'PZ1/01');

    expect(find.text('Break & Finish'), findsOneWidget);
    expect(find.text('Sick Day Status'), findsOneWidget);

    await tester.tap(find.text('Break & Finish'));
    await pumpFor(tester, const Duration(milliseconds: 700));
    await waitForFinder(tester, find.text('Break & Finish Status'));
    expect(find.text('Full Break'), findsOneWidget);
    expect(find.text('Late Finish'), findsOneWidget);
    await dismissOpenDialog(tester);
    await pumpFor(tester, const Duration(milliseconds: 500));

    // Re-open edit for sick day
    await openEditEventFromDayDetail(tester, 'PZ1/01');
    await waitForFinder(tester, find.text('Sick Day Status'));
    await tester.tap(find.text('Sick Day Status'));
    await pumpFor(tester, const Duration(milliseconds: 700));
    await waitForFinder(tester, find.text('Select sick day type:'));
    expect(find.text('Normal Sick'), findsOneWidget);
    expect(find.text('Self-Certified'), findsOneWidget);
    expect(find.text('Force Majeure'), findsOneWidget);
    await dismissOpenDialog(tester);

    expect(tester.takeException(), isNull);
  });
}
