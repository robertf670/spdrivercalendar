import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/dialogs/remove_rest_day_swap_dialog.dart';
import 'package:spdrivercalendar/features/calendar/dialogs/rest_day_swap_picker_dialog.dart';
import 'package:spdrivercalendar/services/rest_day_swap_service.dart';

void main() {
  testWidgets('remove dialog confirms removal', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () async {
                result = await showDialog<bool>(
                  context: context,
                  builder: (_) => RemoveRestDaySwapDialog(
                    swap: RestDaySwap(
                      workDate: DateTime(2026, 8, 3),
                      restDate: DateTime(2026, 8, 4),
                      shiftType: 'E',
                    ),
                  ),
                );
              },
              child: const Text('Open'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Remove rest day swap'), findsOneWidget);

    await tester.tap(find.text('Remove swap'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });

  testWidgets('picker dialog returns the tapped candidate date', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    DateTime? picked;
    final candidateDate = DateTime(2026, 8, 2);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () async {
                picked = await showDialog<DateTime>(
                  context: context,
                  builder: (_) => RestDaySwapPickerDialog(
                    isWorkDay: true,
                    candidates: [
                      RestDaySwapCandidateOption(
                        date: candidateDate,
                        label: 'Rest',
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Open'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Swap with rest day'), findsOneWidget);

    await tester.tap(find.textContaining('Rest'));
    await tester.pumpAndSettle();
    expect(picked, candidateDate);
  });
}
