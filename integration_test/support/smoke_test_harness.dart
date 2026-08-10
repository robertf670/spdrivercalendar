import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spdrivercalendar/core/constants/app_constants.dart';
import 'package:spdrivercalendar/features/calendar/services/event_service.dart';
import 'package:spdrivercalendar/features/calendar/widgets/calendar_day_cell.dart';
import 'package:spdrivercalendar/features/calendar/widgets/calendar_grid.dart';
import 'package:spdrivercalendar/features/calendar/widgets/event_card.dart';
import 'package:spdrivercalendar/main.dart' as app;
import 'package:spdrivercalendar/models/event.dart';

/// Seeds SharedPreferences so the smoke suite prefers the calendar home route.
Future<void> seedSmokeTestPreferences() async {
  final prefs = await SharedPreferences.getInstance();
  final packageInfo = await PackageInfo.fromPlatform();

  await prefs.setBool(AppConstants.hasSeenWelcomeKey, true);
  await prefs.setBool(AppConstants.hasCompletedGoogleLoginKey, true);
  await prefs.setBool(AppConstants.hasSetDaysInLieuKey, true);
  await prefs.setBool(AppConstants.hasSetAnnualLeaveKey, true);
  await prefs.setString(AppConstants.lastSeenVersionKey, packageInfo.version);
  await prefs.setString(
    AppConstants.startDateKey,
    DateTime(2024, 1, 7).toIso8601String(),
  );
  await prefs.setInt(AppConstants.startWeekKey, 0);
}

/// Boots the real app and navigates past onboarding/startup blockers.
Future<void> launchAppForSmokeTest(WidgetTester tester) async {
  await seedSmokeTestPreferences();
  await app.main();
  await pumpFor(tester, const Duration(seconds: 2));
  await reachCalendarHome(tester);
}

/// Clears welcome / what's-new / setup dialogs until the calendar is usable.
Future<void> reachCalendarHome(WidgetTester tester) async {
  final end = DateTime.now().add(const Duration(seconds: 45));

  while (DateTime.now().isBefore(end)) {
    await pumpFor(tester, const Duration(milliseconds: 300));
    await dismissTransientDialogs(tester);

    if (isOnCalendarHome()) {
      return;
    }

    final next = find.widgetWithText(ElevatedButton, 'Next');
    if (next.evaluate().isNotEmpty) {
      await tester.tap(next);
      continue;
    }
    final getStarted = find.widgetWithText(ElevatedButton, 'Get Started');
    if (getStarted.evaluate().isNotEmpty) {
      await tester.tap(getStarted);
      continue;
    }

    final continueButton = find.widgetWithText(ElevatedButton, 'Continue');
    if (continueButton.evaluate().isNotEmpty) {
      await tester.tap(continueButton);
      continue;
    }

    final skipLeave = find.text('Skip (Set to 0)');
    if (skipLeave.evaluate().isNotEmpty) {
      await tester.tap(skipLeave.first);
      continue;
    }

    final chooseRestDays = find.text('Choose rest days:');
    final saveButton = find.widgetWithText(FilledButton, 'Save');
    if (chooseRestDays.evaluate().isNotEmpty &&
        saveButton.evaluate().isNotEmpty) {
      await tester.tap(saveButton);
      continue;
    }
  }

  fail(
    'Timed out reaching calendar home. Visible texts: ${visibleTexts(tester)}',
  );
}

bool isOnCalendarHome() {
  final weekView = find.byTooltip('Week View');
  final search = find.byTooltip('Search Shifts');
  final grid = find.byType(CalendarGrid);
  return weekView.evaluate().isNotEmpty &&
      search.evaluate().isNotEmpty &&
      grid.evaluate().isNotEmpty;
}

Future<void> pumpFor(WidgetTester tester, Duration duration) async {
  final end = DateTime.now().add(duration);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> waitForFinder(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
  fail('Timed out waiting for $finder. Visible texts: ${visibleTexts(tester)}');
}

Future<void> dismissTransientDialogs(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await pumpFor(tester, const Duration(milliseconds: 250));

    final later = find.text('Later');
    if (later.evaluate().isNotEmpty) {
      await tester.tap(later);
      await pumpFor(tester, const Duration(milliseconds: 400));
      continue;
    }

    final cancel = find.widgetWithText(TextButton, 'Cancel');
    final updateTitle = find.text('Update Available');
    if (updateTitle.evaluate().isNotEmpty && cancel.evaluate().isNotEmpty) {
      await tester.tap(cancel.first);
      await pumpFor(tester, const Duration(milliseconds: 400));
      continue;
    }

    break;
  }
}

Future<void> dismissOpenDialog(WidgetTester tester) async {
  final cancel = find.widgetWithText(TextButton, 'Cancel');
  if (cancel.evaluate().isNotEmpty) {
    await tester.tap(cancel.first);
    await pumpFor(tester, const Duration(milliseconds: 500));
    return;
  }

  // Barrier tap for dialogs without Cancel.
  await tester.tapAt(const Offset(8, 8));
  await pumpFor(tester, const Duration(milliseconds: 500));
}

Future<void> selectVisibleDay(WidgetTester tester, {int index = 10}) async {
  final dayCells = find.byType(CalendarDayCell);
  expect(dayCells, findsWidgets);
  await tester.tap(dayCells.at(index));
  await pumpFor(tester, const Duration(milliseconds: 800));
  await dismissTransientDialogs(tester);
  await waitForFinder(tester, find.textContaining('Events ('));
}

/// Selects today's month-grid cell (triggers a rebuild after EventService seeds).
Future<void> selectToday(WidgetTester tester) async {
  final today = find.byWidgetPredicate(
    (widget) => widget is CalendarDayCell && widget.isToday,
  );
  await waitForFinder(tester, today, timeout: const Duration(seconds: 15));
  await tester.ensureVisible(today.first);
  await tester.tap(today.first);
  await pumpFor(tester, const Duration(milliseconds: 800));
  await dismissTransientDialogs(tester);
  await waitForFinder(tester, find.textContaining('Events ('));
}

/// Opens Edit Event from the day-detail [EventCard], not the grid marker.
Future<void> openEditEventFromDayDetail(
  WidgetTester tester,
  String titleFragment,
) async {
  final cards = find.byType(EventCard);
  await waitForFinder(tester, cards, timeout: const Duration(seconds: 15));

  Finder? target;
  for (final element in cards.evaluate()) {
    final card = element.widget as EventCard;
    if (card.event.title.contains(titleFragment)) {
      target = find.byWidget(card);
      break;
    }
  }
  expect(
    target,
    isNotNull,
    reason: 'No EventCard for "$titleFragment". Texts: ${visibleTexts(tester)}',
  );

  await tester.ensureVisible(target!);
  await tester.tap(target);
  await pumpFor(tester, const Duration(milliseconds: 800));
  await waitForFinder(tester, find.text('Edit Event'));
}

Future<void> openAddEventDialog(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.add_circle));
  await pumpFor(tester, const Duration(milliseconds: 600));
  await waitForFinder(tester, find.text('What type of event would you like to add?'));
}

/// Forces the calendar screen to rebuild by leaving and returning via Settings.
Future<void> refreshCalendarViaSettings(WidgetTester tester) async {
  await dismissTransientDialogs(tester);
  await tester.tap(find.byIcon(Icons.settings));
  await pumpFor(tester, const Duration(milliseconds: 500));
  final settingsItem = find.text('Settings');
  if (settingsItem.evaluate().isNotEmpty) {
    await tester.tap(settingsItem.first);
    await pumpFor(tester, const Duration(seconds: 1));
    await tester.pageBack();
    await pumpFor(tester, const Duration(seconds: 1));
  } else {
    // Menu already closed or settings opened directly.
    await tester.pageBack();
    await pumpFor(tester, const Duration(milliseconds: 800));
  }
  await waitForFinder(tester, find.byType(CalendarGrid));
  await dismissTransientDialogs(tester);
}

/// Inserts a work shift directly so edit/status dialogs can be exercised.
Future<DateTime> seedSmokeWorkShiftEvent() async {
  final day = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
  await EventService.addEvent(
    Event(
      id: 'smoke-work-${day.millisecondsSinceEpoch}',
      title: 'PZ1/01',
      startDate: day,
      startTime: const TimeOfDay(hour: 8, minute: 0),
      endDate: day,
      endTime: const TimeOfDay(hour: 16, minute: 0),
    ),
  );
  await EventService.preloadMonth(day);
  return day;
}

List<String> visibleTexts(WidgetTester tester) {
  final texts = <String>[];
  for (final element in find.byType(Text).evaluate()) {
    final widget = element.widget;
    if (widget is Text && widget.data != null && widget.data!.trim().isNotEmpty) {
      texts.add(widget.data!);
    }
    if (texts.length >= 30) break;
  }
  return texts;
}
