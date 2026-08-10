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

    final dialogSize = tester.getSize(find.byType(Dialog));
    expect(dialogSize.width, lessThanOrEqualTo(320));
    expect(dialogSize.height, lessThanOrEqualTo(800));
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
}
