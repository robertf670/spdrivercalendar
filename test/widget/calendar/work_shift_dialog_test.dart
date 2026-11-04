import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/dialogs/work_shift_dialog.dart';
import 'package:spdrivercalendar/features/calendar/services/roster_service.dart';
import 'package:spdrivercalendar/features/calendar/utils/jamestown_road.dart';

void main() {
  testWidgets('fits 320px and adds the selected work shift', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    WorkShiftDialogSelection? saved;
    final loadedZones = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WorkShiftDialog(
            shiftDate: DateTime(2026, 8, 4),
            isMFMarkedIn: false,
            isShiftMarkedIn: false,
            markedInZone: '',
            jamestownEnabled: false,
            donnybrook1Enabled: false,
            loadShiftNumbers: (zone) async {
              loadedZones.add(zone);
              await Future<void>.delayed(const Duration(milliseconds: 10));
              return const ['PZ1/01', 'PZ1/02'];
            },
            dayHasBlockingEvent: (_) => false,
            onAddShift: (selection) async {
              saved = selection;
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final dialogRect = tester.getRect(find.byType(AlertDialog));
    expect(dialogRect.left, greaterThanOrEqualTo(0));
    expect(dialogRect.right, lessThanOrEqualTo(320));
    expect(find.textContaining('Add Work Shift'), findsOneWidget);
    expect(loadedZones, ['Zone 1']);

    await tester.tap(find.text('Add Shift'));
    await tester.pumpAndSettle();

    expect(saved, isNotNull);
    expect(saved!.selectedZone, 'Zone 1');
    expect(saved!.selectedShiftNumber, 'PZ1/01');
    expect(tester.takeException(), isNull);
  });

  testWidgets('marked in on Zone 2 defaults the picker from 10 Oct 2026',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final loadedZones = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WorkShiftDialog(
            shiftDate: DateTime(2026, 10, 12),
            isMFMarkedIn: false,
            isShiftMarkedIn: true,
            markedInZone: 'Route 13',
            jamestownEnabled: false,
            donnybrook1Enabled: false,
            loadShiftNumbers: (zone) async {
              loadedZones.add(zone);
              return const ['13/01', '13/02'];
            },
            dayHasBlockingEvent: (_) => false,
            onAddShift: (_) async {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(loadedZones, ['Route 13']);
    expect(find.text('13/01'), findsOneWidget);
    expect(find.text('Would you like to repeat this duty this week?'),
        findsOneWidget);
    expect(find.text('Auto-fill the next 35 weeks from my roster?'),
        findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Zone 2 roster fill checkbox appears when pinned and enabled',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    expect(await RosterService.loadZone2ShiftRoster(), isTrue);

    WorkShiftDialogSelection? saved;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WorkShiftDialog(
            shiftDate: DateTime(2026, 10, 13),
            isMFMarkedIn: false,
            isShiftMarkedIn: true,
            markedInZone: 'Route 13',
            jamestownEnabled: false,
            donnybrook1Enabled: false,
            zone2RosterEnabled: true,
            loadShiftNumbers: (_) async => const ['13/33', '13/01'],
            dayHasBlockingEvent: (_) => false,
            onAddShift: (selection) async {
              saved = selection;
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final fillLabel = find.text('Auto-fill the next 35 weeks from my roster?');
    expect(fillLabel, findsOneWidget);
    await tester.ensureVisible(fillLabel);
    await tester.tap(find.byType(Checkbox).last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Add Shift'));
    await tester.tap(find.text('Add Shift'));
    await tester.pumpAndSettle();

    expect(saved, isNotNull);
    expect(saved!.selectedShiftNumber, '13/33');
    expect(saved!.fillNext35Weeks, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Zone 4 marked in does not offer the Route 13 fill',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    expect(await RosterService.loadZone4ShiftRoster(), isTrue);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WorkShiftDialog(
            shiftDate: DateTime(2026, 8, 23),
            isMFMarkedIn: false,
            isShiftMarkedIn: true,
            markedInZone: 'Zone 4',
            jamestownEnabled: false,
            donnybrook1Enabled: false,
            zone2RosterEnabled: true,
            zone4RosterEnabled: true,
            loadShiftNumbers: (zone) async =>
                zone == 'Zone 4' ? const ['PZ4/05'] : const ['13/01'],
            dayHasBlockingEvent: (_) => false,
            onAddShift: (_) async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Auto-fill the next 45 weeks from my roster?'),
      findsOneWidget,
    );
    expect(
      find.text('Auto-fill the next 35 weeks from my roster?'),
      findsNothing,
    );

    await tester.tap(find.byType(DropdownButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Route 13').last);
    await tester.pumpAndSettle();

    expect(
      find.text('Auto-fill the next 35 weeks from my roster?'),
      findsNothing,
    );
    expect(
      find.text('Auto-fill the next 45 weeks from my roster?'),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('nights roster offers duty repeat on a weekday work day',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WorkShiftDialog(
            shiftDate: DateTime(2024, 4, 9),
            isMFMarkedIn: false,
            isShiftMarkedIn: false,
            markedInZone: '',
            jamestownEnabled: false,
            donnybrook1Enabled: false,
            isNightsRoster: true,
            isNightsWorkDay: (date) =>
                date.weekday >= DateTime.monday &&
                date.weekday <= DateTime.thursday,
            loadShiftNumbers: (_) async => const ['PZ1/91'],
            dayHasBlockingEvent: (_) => false,
            onAddShift: (_) async {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Would you like to repeat this duty this week?'),
        findsOneWidget);
  });

  testWidgets('nights roster does not offer duty repeat on Saturday',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WorkShiftDialog(
            shiftDate: DateTime(2024, 4, 13),
            isMFMarkedIn: false,
            isShiftMarkedIn: false,
            markedInZone: '',
            jamestownEnabled: false,
            donnybrook1Enabled: false,
            isNightsRoster: true,
            isNightsWorkDay: (_) => true,
            loadShiftNumbers: (_) async => const ['PZ1/91'],
            dayHasBlockingEvent: (_) => false,
            onAddShift: (_) async {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Would you like to repeat this duty this week?'),
        findsNothing);
  });

  testWidgets('Jamestown marked-in defaults to Jamestown Road duties',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final loadedZones = <String>[];
    WorkShiftDialogSelection? saved;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WorkShiftDialog(
            shiftDate: DateTime(2026, 10, 12),
            isMFMarkedIn: true,
            isShiftMarkedIn: false,
            markedInZone: JamestownRoad.zoneLabel,
            jamestownEnabled: false,
            donnybrook1Enabled: false,
            loadShiftNumbers: (zone) async {
              loadedZones.add(zone);
              return const ['811/01', '311/01'];
            },
            dayHasBlockingEvent: (_) => false,
            onAddShift: (selection) async {
              saved = selection;
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(loadedZones, [JamestownRoad.zoneLabel]);
    expect(find.text('811/01'), findsOneWidget);
    expect(find.text('Would you like to repeat this duty this week?'),
        findsOneWidget);

    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    expect(find.text('M'), findsOneWidget);
    expect(find.text('F'), findsOneWidget);

    await tester.tap(find.text('Add Shift'));
    await tester.pumpAndSettle();
    expect(saved, isNotNull);
    expect(saved!.repeatDutyThisWeek, isTrue);
    expect(saved!.selectedDays[1], isTrue);
    expect(saved!.selectedDays[2], isTrue);
    expect(saved!.selectedDays[3], isTrue);
    expect(saved!.selectedDays[4], isTrue);
    expect(saved!.selectedDays[5], isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('zone 1 fill note wraps at 320px with large text', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(() {
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      tester.binding.setSurfaceSize(null);
    });
    expect(await RosterService.loadZone1ShiftRoster(), isTrue);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WorkShiftDialog(
            shiftDate: DateTime(2026, 11, 3),
            isMFMarkedIn: false,
            isShiftMarkedIn: true,
            markedInZone: 'Zone 1',
            jamestownEnabled: false,
            donnybrook1Enabled: false,
            zone1RosterEnabled: true,
            loadShiftNumbers: (_) async => const ['PZ1/65'],
            dayHasBlockingEvent: (_) => false,
            onAddShift: (_) async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final label = find.text('Auto-fill the next 85 weeks from my roster?');
    expect(label, findsOneWidget);
    await tester.ensureVisible(label);
    await tester.tap(
      find.descendant(
        of: find.ancestor(of: label, matching: find.byType(Row)).first,
        matching: find.byType(Checkbox),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Google Calendar sync'), findsOneWidget);
    final dialogRect = tester.getRect(find.byType(AlertDialog));
    expect(dialogRect.left, greaterThanOrEqualTo(0));
    expect(dialogRect.right, lessThanOrEqualTo(320));
    final note = tester.getRect(find.textContaining('Google Calendar sync'));
    expect(note.left, greaterThanOrEqualTo(dialogRect.left));
    expect(note.right, lessThanOrEqualTo(dialogRect.right));
    expect(tester.takeException(), isNull);
  });

  testWidgets('rest day hides repeat and autofill', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    expect(await RosterService.loadZone1ShiftRoster(), isTrue);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WorkShiftDialog(
            shiftDate: DateTime(2026, 11, 3),
            isMFMarkedIn: false,
            isShiftMarkedIn: true,
            markedInZone: 'Zone 1',
            jamestownEnabled: false,
            donnybrook1Enabled: false,
            zone1RosterEnabled: true,
            isRosteredRestDay: (date) =>
                date.year == 2026 && date.month == 11 && date.day == 3,
            loadShiftNumbers: (_) async => const ['PZ1/65'],
            dayHasBlockingEvent: (_) => false,
            onAddShift: (_) async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Would you like to repeat this duty this week?'),
        findsNothing);
    expect(find.text('Auto-fill the next 85 weeks from my roster?'),
        findsNothing);
    expect(tester.takeException(), isNull);
  });
}
