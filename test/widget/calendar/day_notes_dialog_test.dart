import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/dialogs/day_notes_dialog.dart';

void main() {
  testWidgets('fits 320px and saves notes', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    String? saved;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DayNotesDialog(
            date: DateTime(2026, 8, 4),
            initialNotes: 'Hello',
            onSave: (notes) async {
              saved = notes;
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final dialogRect = tester.getRect(find.byType(AlertDialog));
    expect(dialogRect.left, greaterThanOrEqualTo(0));
    expect(dialogRect.right, lessThanOrEqualTo(320));
    expect(find.textContaining('Notes for'), findsOneWidget);
    expect(find.text('Hello'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Updated note');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(saved, 'Updated note');
    expect(tester.takeException(), isNull);
  });
}
