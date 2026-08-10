import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/dialogs/work_shift_dialog.dart';

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
}
