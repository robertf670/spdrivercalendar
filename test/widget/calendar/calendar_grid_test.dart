import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/widgets/calendar_grid.dart';

void main() {
  testWidgets('fits at 320px and forwards header and day actions', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var previousCalls = 0;
    var nextCalls = 0;
    var yearCalls = 0;
    DateTime? selectedDate;
    var loadedDays = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CalendarGrid(
              tableKey: const ValueKey('test-calendar-grid'),
              focusedDay: DateTime(2026, 7, 1),
              selectedDay: null,
              onPreviousMonth: () => previousCalls++,
              onNextMonth: () => nextCalls++,
              onShowYear: () => yearCalls++,
              onDaySelected: (selected, focused) async {
                selectedDate = selected;
              },
              onPageChanged: (_) {},
              eventLoader: (day) {
                loadedDays++;
                return const [];
              },
              dayBuilder: (
                date, {
                required isToday,
                required isOutsideDay,
                isSelected = false,
              }) {
                return Center(child: Text('${date.day}'));
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text('  July 2026'), findsOneWidget);
    expect(loadedDays, greaterThan(0));
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.tap(find.text('  July 2026'));
    await tester.tap(find.text('15'));
    await tester.pump();

    expect(previousCalls, 1);
    expect(nextCalls, 1);
    expect(yearCalls, 1);
    expect(selectedDate, DateTime.utc(2026, 7, 15));
    expect(tester.takeException(), isNull);
  });

  testWidgets('marks the supplied selected day through the day builder', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalendarGrid(
            tableKey: const ValueKey('selected-calendar-grid'),
            focusedDay: DateTime(2026, 7, 1),
            selectedDay: DateTime(2026, 7, 15),
            onPreviousMonth: () {},
            onNextMonth: () {},
            onShowYear: () {},
            onDaySelected: (_, __) async {},
            onPageChanged: (_) {},
            eventLoader: (_) => const [],
            dayBuilder: (
              date, {
              required isToday,
              required isOutsideDay,
              isSelected = false,
            }) {
              return Container(
                key: isSelected ? const ValueKey('selected-day') : null,
                alignment: Alignment.center,
                child: Text('${date.day}'),
              );
            },
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('selected-day')), findsOneWidget);
  });
}
