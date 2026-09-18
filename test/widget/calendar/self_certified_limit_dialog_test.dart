import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/dialogs/self_certified_limit_dialog.dart';
import 'package:spdrivercalendar/services/self_certified_sick_days_service.dart';

void main() {
  Future<void> pumpHost(
    WidgetTester tester, {
    required Size surfaceSize,
    required ValueChanged<bool> onResult,
  }) async {
    await tester.binding.setSurfaceSize(surfaceSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () async {
                  final added = await SelfCertifiedLimitDialog.confirm(
                    context,
                    warningMessage:
                        'You have already used 2 self-certified days in May–October.',
                    halfYearName: 'May–October',
                    halfYearCount: 2,
                    yearlyCount: 2,
                  );
                  onResult(added);
                },
                child: const Text('open'),
              ),
            );
          },
        ),
      ),
    );
  }

  testWidgets('explains the sick bonus and allows adding anyway', (tester) async {
    var added = false;
    await pumpHost(
      tester,
      surfaceSize: const Size(320, 800),
      onResult: (value) => added = value,
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Self-Certified Limit Reached'), findsOneWidget);
    expect(
      find.text('You have already used 2 self-certified days in May–October.'),
      findsOneWidget,
    );
    expect(
      find.text(SelfCertifiedSickDaysService.bonusPeriodExplanation),
      findsOneWidget,
    );
    expect(find.text('Add anyway'), findsOneWidget);

    final dialogRect = tester.getRect(find.byType(AlertDialog));
    expect(dialogRect.left, greaterThanOrEqualTo(0));
    expect(dialogRect.right, lessThanOrEqualTo(320));

    await tester.tap(find.text('Add anyway'));
    await tester.pumpAndSettle();
    expect(added, isTrue);
  });

  testWidgets('cancel does not add', (tester) async {
    var added = true;
    await pumpHost(
      tester,
      surfaceSize: const Size(400, 800),
      onResult: (value) => added = value,
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(added, isFalse);
  });
}
