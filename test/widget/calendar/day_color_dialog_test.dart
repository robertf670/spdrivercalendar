import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/dialogs/day_color_dialog.dart';
import 'package:spdrivercalendar/features/calendar/utils/day_color_swatches.dart';

void main() {
  testWidgets('fits a 320px viewport and applies a swatch', (tester) async {
    DayColorResult? result;
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await DayColorDialog.show(
                    context,
                    date: DateTime(2026, 9, 18),
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

    expect(find.text('Day colour'), findsOneWidget);
    expect(find.text('Fri 18 Sep 2026'), findsOneWidget);
    expect(find.text('Custom'), findsOneWidget);
    expect(find.text('Reset'), findsNothing);

    final sheetRect = tester.getRect(find.text('Day colour'));
    expect(sheetRect.left, greaterThanOrEqualTo(0));
    expect(sheetRect.right, lessThanOrEqualTo(320));

    final swatch = dayColorSwatches().first;
    await tester.tap(
      find.byKey(ValueKey('day-color-swatch-${swatch.toARGB32()}')),
    );
    await tester.pumpAndSettle();

    expect(result?.reset, isFalse);
    expect(result?.color, swatch);
  });

  testWidgets('reset is available when an override exists', (tester) async {
    DayColorResult? result;
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await DayColorDialog.show(
                    context,
                    date: DateTime(2026, 9, 18),
                    currentOverride: Colors.pink,
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
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();

    expect(result?.reset, isTrue);
  });
}
