import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/dialogs/overtime_half_type_dialog.dart';

void main() {
  testWidgets('fits 320px and invokes half callbacks', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var firstHalfCalls = 0;
    var secondHalfCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OvertimeHalfTypeDialog(
            onFirstHalf: () => firstHalfCalls++,
            onSecondHalf: () => secondHalfCalls++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final dialogRect = tester.getRect(find.byType(AlertDialog));
    expect(dialogRect.left, greaterThanOrEqualTo(0));
    expect(dialogRect.right, lessThanOrEqualTo(320));
    expect(find.text('Select Overtime Half'), findsOneWidget);

    await tester.tap(find.text('First Half'));
    await tester.tap(find.text('Second Half'));
    await tester.pump();

    expect(firstHalfCalls, 1);
    expect(secondHalfCalls, 1);
    expect(tester.takeException(), isNull);
  });
}
