import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/dialogs/late_finish_selection_dialog.dart';

void main() {
  Future<void> pumpDialog(
    WidgetTester tester, {
    int? initialDurationMinutes,
    Future<void> Function(int durationMinutes)? onSave,
    VoidCallback? onInvalidDuration,
  }) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LateFinishSelectionDialog(
            initialDurationMinutes: initialDurationMinutes,
            onSave: onSave ?? (_) async {},
            onInvalidDuration: onInvalidDuration,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('fits a 320px viewport and defaults to 15 minutes', (tester) async {
    await pumpDialog(tester);

    final dialogRect = tester.getRect(find.byType(AlertDialog));
    expect(dialogRect.left, greaterThanOrEqualTo(0));
    expect(dialogRect.right, lessThanOrEqualTo(320));
    expect(find.text('15 mins'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('saves dropdown and custom minute values', (tester) async {
    final savedDurations = <int>[];

    await pumpDialog(
      tester,
      initialDurationMinutes: 20,
      onSave: (duration) async {
        savedDurations.add(duration);
      },
    );

    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(savedDurations, [20]);

    await tester.enterText(find.byType(TextField), '37');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(savedDurations, [20, 37]);
  });

  testWidgets('reports invalid custom minutes without saving', (tester) async {
    var invalidCalls = 0;
    var saveCalls = 0;

    await pumpDialog(
      tester,
      onInvalidDuration: () {
        invalidCalls++;
      },
      onSave: (_) async {
        saveCalls++;
      },
    );

    await tester.enterText(find.byType(TextField), 'abc');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(invalidCalls, 1);
    expect(saveCalls, 0);
  });
}
