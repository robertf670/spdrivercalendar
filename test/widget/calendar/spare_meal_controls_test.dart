import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/widgets/spare_meal_controls.dart';

void main() {
  testWidgets('offers Set time when no meal is stored', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var setTapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SpareMealControls(
            mealStart: null,
            mealEnd: null,
            onSet: () => setTapped = true,
            onClear: () {},
          ),
        ),
      ),
    );

    expect(find.text('Take break'), findsOneWidget);
    expect(find.text('Set time'), findsOneWidget);
    expect(find.text('Remove'), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Set time'));
    expect(setTapped, isTrue);
  });

  testWidgets('shows the 1-hour meal and Remove when set', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var cleared = false;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 800),
            textScaler: TextScaler.linear(1.3),
          ),
          child: Scaffold(
            body: SpareMealControls(
              mealStart: const TimeOfDay(hour: 14, minute: 0),
              mealEnd: const TimeOfDay(hour: 15, minute: 0),
              onSet: () {},
              onClear: () => cleared = true,
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);

    expect(find.text('Break 14:00–15:00'), findsOneWidget);
    expect(find.text('Change'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
    await tester.tap(find.text('Remove'));
    expect(cleared, isTrue);
  });
}
