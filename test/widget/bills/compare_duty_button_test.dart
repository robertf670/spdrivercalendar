import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/bills/utils/duty_compare_launch.dart';

void main() {
  testWidgets('compare opens with the entered duty on your side', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CompareDutyButton(
            dutyCode: 'PZ4/18',
            date: DateTime(2026, 11, 2),
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Compare duty'));
    await tester.pumpAndSettle();

    expect(find.text('Compare duties'), findsOneWidget);
    expect(find.text('PZ4/18'), findsWidgets);
    expect(find.text('Next'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a spare shift has no compare icon', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CompareDutyButton(
            dutyCode: 'SP0800',
            date: DateTime(2026, 11, 2),
          ),
        ),
      ),
    );

    expect(find.byTooltip('Compare duty'), findsNothing);
  });
}
