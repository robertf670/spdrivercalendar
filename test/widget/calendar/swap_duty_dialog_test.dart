import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/dialogs/swap_duty_dialog.dart';

void main() {
  Future<void> open(
    WidgetTester tester, {
    required bool showWeekCheckbox,
    required void Function(SwapDutyChoice? choice) onClosed,
  }) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                final choice = await showDialog<SwapDutyChoice>(
                  context: context,
                  builder: (context) => SwapDutyDialog(
                    currentDuty: '13/22',
                    showWeekCheckbox: showWeekCheckbox,
                    loadDuties: () async => const ['13/22', '13/25', '13/01'],
                  ),
                );
                onClosed(choice);
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets('fits 320px and hides the week checkbox', (tester) async {
    await open(
      tester,
      showWeekCheckbox: false,
      onClosed: (_) {},
    );

    final dialogRect = tester.getRect(find.byType(AlertDialog));
    expect(dialogRect.left, greaterThanOrEqualTo(0));
    expect(dialogRect.right, lessThanOrEqualTo(320));
    expect(find.text('13/22'), findsNothing);
    expect(find.text('Change every matching weekday this week'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('week checkbox is optional and swap returns the choice', (
    tester,
  ) async {
    SwapDutyChoice? choice;
    await open(
      tester,
      showWeekCheckbox: true,
      onClosed: (selected) => choice = selected,
    );

    expect(find.text('Change every matching weekday this week'), findsOneWidget);
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Swap'));
    await tester.pumpAndSettle();

    expect(choice?.duty, '13/25');
    expect(choice?.applyToWeek, isTrue);
  });
}
