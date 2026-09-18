import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/feedback/screens/feedback_screen.dart';

void main() {
  testWidgets('submit feedback offers WhatsApp, not email', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(home: FeedbackScreen()),
    );

    expect(find.text('Send via WhatsApp'), findsOneWidget);
    expect(find.textContaining('WhatsApp to message the app creator'), findsOneWidget);
    expect(find.textContaining('Email'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
