import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/core/utils/developer_correction.dart';
import 'package:spdrivercalendar/core/widgets/correction_note.dart';

void main() {
  test('developerCorrectionUri opens WhatsApp to Rob', () {
    final uri = developerCorrectionUri(pageLabel: 'the contacts page');
    expect(uri.scheme, 'https');
    expect(uri.host, 'wa.me');
    expect(uri.path, '/353892580774');
    expect(
      uri.queryParameters['text'],
      'Hi Rob, I spotted something incorrect on the contacts page.',
    );
  });

  test('developerCorrectionUri falls back to email without a number', () {
    final uri = developerCorrectionUri(whatsappNumber: '');
    expect(uri.scheme, 'mailto');
    expect(uri.path, developerFeedbackEmail);
    expect(uri.query, contains('App%20correction'));
  });

  testWidgets('correction note has no coloured background', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CorrectionNote(pageLabel: 'the contacts page'),
        ),
      ),
    );

    expect(find.textContaining('send me a message'), findsOneWidget);
    expect(
      find.textContaining('If you notice anything here to be incorrect'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.chat_bubble_outline), findsNothing);
    expect(
      find.descendant(
        of: find.byType(CorrectionNote),
        matching: find.byType(Material),
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
}
