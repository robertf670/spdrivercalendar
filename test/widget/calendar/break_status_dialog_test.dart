import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/dialogs/break_status_dialog.dart';

void main() {
  Future<void> pumpDialog(
    WidgetTester tester, {
    bool hasLateBreak = false,
    bool tookFullBreak = false,
    int? overtimeDurationMinutes,
    bool hasLateFinish = false,
    int? lateFinishDurationMinutes,
    Future<void> Function()? onRemoveBreak,
    Future<void> Function()? onFullBreak,
    VoidCallback? onOvertime,
    Future<void> Function()? onRemoveLateFinish,
    VoidCallback? onLateFinish,
  }) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BreakStatusDialog(
            hasLateBreak: hasLateBreak,
            tookFullBreak: tookFullBreak,
            overtimeDurationMinutes: overtimeDurationMinutes,
            hasLateFinish: hasLateFinish,
            lateFinishDurationMinutes: lateFinishDurationMinutes,
            onRemoveBreak: onRemoveBreak ?? () async {},
            onFullBreak: onFullBreak ?? () async {},
            onOvertime: onOvertime ?? () {},
            onRemoveLateFinish: onRemoveLateFinish ?? () async {},
            onLateFinish: onLateFinish ?? () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('fits a 320px viewport with unset status options', (tester) async {
    await pumpDialog(tester);

    final dialogRect = tester.getRect(find.byType(AlertDialog));
    expect(dialogRect.left, greaterThanOrEqualTo(0));
    expect(dialogRect.right, lessThanOrEqualTo(320));
    expect(find.text('Full Break'), findsOneWidget);
    expect(find.text('Overtime'), findsOneWidget);
    expect(find.text('Late Finish'), findsOneWidget);
    expect(find.text('Remove'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows current statuses and invokes clear callbacks', (tester) async {
    var removeBreakCalls = 0;
    var removeLateFinishCalls = 0;

    await pumpDialog(
      tester,
      hasLateBreak: true,
      tookFullBreak: false,
      overtimeDurationMinutes: 40,
      hasLateFinish: true,
      lateFinishDurationMinutes: 15,
      onRemoveBreak: () async {
        removeBreakCalls++;
      },
      onRemoveLateFinish: () async {
        removeLateFinishCalls++;
      },
    );

    expect(find.text('Overtime (40 mins)'), findsOneWidget);
    expect(find.text('Late Finish: 15 mins'), findsOneWidget);
    expect(find.text('Full Break'), findsNothing);

    await tester.tap(find.text('Remove'));
    await tester.pump();
    expect(removeBreakCalls, 1);

    await tester.tap(find.text('Remove Late Finish'));
    await tester.pump();
    expect(removeLateFinishCalls, 1);
  });
}
