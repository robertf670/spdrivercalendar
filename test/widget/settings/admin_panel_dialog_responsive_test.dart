import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/settings/screens/admin_panel_screen.dart';

void main() {
  Future<void> setNarrowViewport(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 800);
    addTearDown(tester.view.reset);
  }

  testWidgets('UpdateDialog fits a 320px-wide viewport', (tester) async {
    await setNarrowViewport(tester);

    await tester.pumpWidget(
      MaterialApp(
        home: UpdateDialog(onSave: (_) async {}),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Scaffold), findsWidgets);
    expect(find.text('Add New Update'), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PollDialog fits a 320px-wide viewport', (tester) async {
    await setNarrowViewport(tester);

    await tester.pumpWidget(
      MaterialApp(
        home: PollDialog(onSave: (_) {}),
      ),
    );
    await tester.pumpAndSettle();

    final dialogSize = tester.getSize(find.byType(Dialog));
    expect(dialogSize.width, lessThanOrEqualTo(320));
    expect(dialogSize.height, lessThanOrEqualTo(800));
    expect(tester.takeException(), isNull);
  });

  testWidgets('UpdateDialog stays usable with keyboard open', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: UpdateDialog(onSave: (_) async {}),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Title'), findsOneWidget);
    expect(find.text('Description'), findsOneWidget);
    expect(find.text('Create'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('live_update_title')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('live_update_title')),
      'Route 39 diversion',
    );
    await tester.pump();

    expect(find.text('Route 39 diversion'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
