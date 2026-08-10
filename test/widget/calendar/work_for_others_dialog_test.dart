import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/dialogs/work_for_others_dialog.dart';

void main() {
  testWidgets('fits 320px and adds the selected shift', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    String? savedZone;
    String? savedShift;
    final loadedZones = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WorkForOthersDialog(
            shiftDate: DateTime(2026, 8, 4),
            loadShiftNumbers: (zone) async {
              loadedZones.add(zone);
              await Future<void>.delayed(const Duration(milliseconds: 10));
              return const ['01', '02'];
            },
            onAddShift: ({
              required selectedZone,
              required selectedShiftNumber,
            }) async {
              savedZone = selectedZone;
              savedShift = selectedShiftNumber;
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final dialogRect = tester.getRect(find.byType(AlertDialog));
    expect(dialogRect.left, greaterThanOrEqualTo(0));
    expect(dialogRect.right, lessThanOrEqualTo(320));
    expect(find.textContaining('Add Work For Others'), findsOneWidget);
    expect(loadedZones, ['Zone 1']);

    await tester.tap(find.text('Add Shift'));
    await tester.pumpAndSettle();

    expect(savedZone, 'Zone 1');
    expect(savedShift, '01');
    expect(tester.takeException(), isNull);
  });
}
