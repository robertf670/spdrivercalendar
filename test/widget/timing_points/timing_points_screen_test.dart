import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/timing_points/screens/timing_points_screen.dart';

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  int maxPumps = 40,
}) async {
  for (var i = 0; i < maxPumps; i++) {
    if (condition()) return;
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Route 13 Mountjoy shows Harristown points and note at 320px',
      (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: TimingPointsScreen()),
    );
    await _pumpUntil(
      tester,
      () => find.text('Route').evaluate().isNotEmpty,
    );

    await tester.tap(find.byType(DropdownButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('13').last);
    await tester.pumpAndSettle();

    expect(find.text('Mountjoy Square'), findsWidgets);
    expect(
      find.textContaining('timing points from Harristown previously'),
      findsOneWidget,
    );
    expect(find.text('Convent Road / Boot Road'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Parnell Square / Rotunda Hospital'),
      240,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Parnell Square / Rotunda Hospital'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
