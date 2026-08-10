import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/dialogs/sick_day_status_dialog.dart';

void main() {
  Future<void> pumpDialog(
    WidgetTester tester, {
    required Size surfaceSize,
    String? currentSickDayType,
    Future<void> Function()? onClear,
    Future<void> Function()? onSelectNormal,
    Future<void> Function()? onSelectSelfCertified,
    Future<void> Function()? onSelectForceMajeure,
  }) async {
    await tester.binding.setSurfaceSize(surfaceSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SickDayStatusDialog(
            currentSickDayType: currentSickDayType,
            onClear: onClear ?? () async {},
            onSelectNormal: onSelectNormal ?? () async {},
            onSelectSelfCertified: onSelectSelfCertified ?? () async {},
            onSelectForceMajeure: onSelectForceMajeure ?? () async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('fits a 320px viewport without a current status', (tester) async {
    await pumpDialog(
      tester,
      surfaceSize: const Size(320, 800),
    );

    final dialogRect = tester.getRect(find.byType(AlertDialog));
    expect(dialogRect.left, greaterThanOrEqualTo(0));
    expect(dialogRect.right, lessThanOrEqualTo(320));
    expect(dialogRect.top, greaterThanOrEqualTo(0));
    expect(dialogRect.bottom, lessThanOrEqualTo(800));

    expect(find.text('Select sick day type:'), findsOneWidget);
    expect(find.text('Clear'), findsNothing);
    expect(find.text('Current Status:'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows current status label and Clear action', (tester) async {
    await pumpDialog(
      tester,
      surfaceSize: const Size(400, 800),
      currentSickDayType: 'self-certified',
    );

    expect(find.text('Current Status:'), findsOneWidget);
    expect(find.text('Self-Certified Sick Day'), findsOneWidget);
    expect(find.text('Clear'), findsOneWidget);
  });

  testWidgets('invokes selection and clear callbacks', (tester) async {
    var clearCalls = 0;
    var normalCalls = 0;
    var selfCertifiedCalls = 0;
    var forceMajeureCalls = 0;

    await pumpDialog(
      tester,
      surfaceSize: const Size(400, 800),
      currentSickDayType: 'normal',
      onClear: () async {
        clearCalls++;
      },
      onSelectNormal: () async {
        normalCalls++;
      },
      onSelectSelfCertified: () async {
        selfCertifiedCalls++;
      },
      onSelectForceMajeure: () async {
        forceMajeureCalls++;
      },
    );

    await tester.tap(find.text('Normal Sick'));
    await tester.pump();
    expect(normalCalls, 1);

    await tester.tap(find.text('Self-Certified'));
    await tester.pump();
    expect(selfCertifiedCalls, 1);

    await tester.tap(find.widgetWithText(TextButton, 'Force Majeure'));
    await tester.pump();
    expect(forceMajeureCalls, 1);

    await tester.tap(find.text('Clear'));
    await tester.pump();
    expect(clearCalls, 1);
  });
}
