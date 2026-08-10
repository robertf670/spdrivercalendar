import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/dialogs/overtime_selection_dialog.dart';

void main() {
  Future<void> pumpDialog(
    WidgetTester tester, {
    required int initialDurationMinutes,
    Future<void> Function(int durationMinutes)? onSave,
    Future<void> Function()? onSaveOneHour,
  }) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OvertimeSelectionDialog(
            initialDurationMinutes: initialDurationMinutes,
            onSave: onSave ?? (_) async {},
            onSaveOneHour: onSaveOneHour ?? () async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('fits a 320px viewport and keeps the initial duration', (
    tester,
  ) async {
    await pumpDialog(tester, initialDurationMinutes: 40);

    final dialogRect = tester.getRect(find.byType(AlertDialog));
    expect(dialogRect.left, greaterThanOrEqualTo(0));
    expect(dialogRect.right, lessThanOrEqualTo(320));
    expect(find.text('40 mins'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('invokes save and one-hour callbacks', (tester) async {
    final savedDurations = <int>[];
    var oneHourCalls = 0;

    await pumpDialog(
      tester,
      initialDurationMinutes: 30,
      onSave: (duration) async {
        savedDurations.add(duration);
      },
      onSaveOneHour: () async {
        oneHourCalls++;
      },
    );

    await tester.tap(find.text('1 Hour (Common)'));
    await tester.pump();
    expect(oneHourCalls, 1);

    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(savedDurations, [30]);
  });
}
