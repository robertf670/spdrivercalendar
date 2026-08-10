import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spdrivercalendar/features/calendar/controllers/calendar_controller.dart';
import 'package:spdrivercalendar/features/calendar/widgets/calendar_scaffold.dart';
import 'package:spdrivercalendar/models/live_update.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows short title on narrow screens and routes menu actions',
      (tester) async {
    final controller = CalendarController(
      initialFocusedDay: DateTime(2026, 8, 1),
    );
    controller.selectDay(DateTime(2026, 8, 4));
    String? selected;

    await tester.pumpWidget(
      ChangeNotifierProvider<CalendarController>.value(
        value: controller,
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(360, 800)),
            child: CalendarScaffold(
              scrollController: ScrollController(),
              calendar: const Text('calendar-body'),
              dayDetailBuilder: (_) => const Text('day-detail'),
              onSearch: () {},
              onWeekView: () {},
              onMenuSelected: (value) => selected = value,
              activeUpdatesStream: Stream<List<LiveUpdate>>.value([]),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Calendar'), findsOneWidget);
    expect(find.text('calendar-body'), findsOneWidget);
    expect(find.text('day-detail'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(selected, CalendarMenuAction.settings);
  });

  testWidgets('shows full title on wider screens', (tester) async {
    final controller = CalendarController(
      initialFocusedDay: DateTime(2026, 8, 1),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<CalendarController>.value(
        value: controller,
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(420, 800)),
            child: CalendarScaffold(
              scrollController: ScrollController(),
              calendar: const SizedBox.shrink(),
              dayDetailBuilder: (_) => const SizedBox.shrink(),
              onSearch: () {},
              onWeekView: () {},
              onMenuSelected: (_) {},
              activeUpdatesStream: Stream<List<LiveUpdate>>.value([]),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Spare Driver Calendar'), findsOneWidget);
  });

  testWidgets('Live Updates menu shows active count', (tester) async {
    final controller = CalendarController(
      initialFocusedDay: DateTime(2026, 8, 1),
    );
    final now = DateTime.now();
    final updates = [
      LiveUpdate(
        id: '1',
        title: 'Diversion A',
        description: 'desc',
        priority: 'warning',
        startTime: now.subtract(const Duration(hours: 1)),
        endTime: now.add(const Duration(hours: 2)),
        routesAffected: const ['39'],
      ),
      LiveUpdate(
        id: '2',
        title: 'Diversion B',
        description: 'desc',
        priority: 'info',
        startTime: now.subtract(const Duration(hours: 1)),
        endTime: now.add(const Duration(hours: 2)),
        routesAffected: const ['C1'],
      ),
    ];

    await tester.pumpWidget(
      ChangeNotifierProvider<CalendarController>.value(
        value: controller,
        child: MaterialApp(
          home: CalendarScaffold(
            scrollController: ScrollController(),
            calendar: const SizedBox.shrink(),
            dayDetailBuilder: (_) => const SizedBox.shrink(),
            onSearch: () {},
            onWeekView: () {},
            onMenuSelected: (_) {},
            activeUpdatesStream: Stream<List<LiveUpdate>>.value(updates),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    expect(find.text('Live Updates (2)'), findsOneWidget);
  });
}
