import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/bills/screens/bills_screen.dart';
import 'package:spdrivercalendar/features/bills/widgets/bill_duty_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('jump chips, expand a duty, and open its board',
      (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: BillsScreen(
          now: DateTime(2026, 9, 11),
          initialZone: 'Zone 1',
          initialDayType: 'M-F',
        ),
      ),
    );

    await _pumpUntil(
      tester,
      () => find.text('01–20').evaluate().isNotEmpty,
    );

    expect(find.text('Bills & Boards'), findsOneWidget);
    expect(find.widgetWithText(ActionChip, '01–20'), findsOneWidget);
    expect(find.widgetWithText(ActionChip, '61–80'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.widgetWithText(ActionChip, '61–80'));
    await tester.tap(find.widgetWithText(ActionChip, '61–80'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('67'), findsOneWidget);

    await tester.tap(find.text('67'));
    await tester.pump();
    expect(find.text('PZ1/67'), findsOneWidget);
    expect(find.text('View board'), findsOneWidget);

    await tester.ensureVisible(find.text('View board'));
    await tester.tap(find.text('View board'));
    await _pumpUntil(
      tester,
      () => find.text('First Half').evaluate().isNotEmpty,
    );
    expect(find.text('See bill'), findsOneWidget);

    await tester.tap(find.text('See bill'));
    await tester.pump();
    expect(find.text('View board'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpUntil(WidgetTester tester, bool Function() condition) async {
  for (var i = 0; i < 40; i++) {
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
    if (condition()) return;
  }
}
