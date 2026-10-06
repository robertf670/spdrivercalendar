import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/dialogs/nights_rest_day_dialog.dart';

void main() {
  testWidgets('saves the rest-day week chosen for this week', (tester) async {
    int? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await showDialog<int>(
                    context: context,
                    builder: (_) => const NightsRestDayDialog(),
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

    expect(find.text('What are your rest days this week?'), findsOneWidget);
    expect(find.text('Sunday, Friday'), findsWidgets);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(result, 0);
  });
}
