import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/dialogs/rest_day_setup_dialog.dart';

void main() {
  testWidgets('returns selected week on save without effective date',
      (tester) async {
    RestDaySetupResult? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await showDialog<RestDaySetupResult>(
                    context: context,
                    builder: (_) => const RestDaySetupDialog(
                      initialStartWeek: 0,
                    ),
                  );
                },
                child: const Text('open'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Choose rest days:'), findsOneWidget);
    expect(find.text('Apply from date'), findsNothing);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.startWeek, 0);
    expect(result!.effectiveDate, isNull);
  });

  testWidgets('shows apply-from-date when allowed', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RestDaySetupDialog(
          initialStartWeek: 2,
          allowEffectiveDate: true,
        ),
      ),
    );

    expect(find.text('Apply from date'), findsOneWidget);
    expect(
      find.text('Not set — apply immediately as normal'),
      findsOneWidget,
    );
  });
}
