import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/widgets/animated_selected_day_cell.dart';
import 'package:spdrivercalendar/features/calendar/widgets/calendar_day_cell.dart';

void main() {
  Widget buildSubject({
    String displayText = 'PZ1/03',
    String shift = 'E',
    bool isDayInLieu = false,
    bool isHoliday = false,
    bool hasEvents = false,
    bool isSaturdayService = false,
    bool hasNotes = false,
    bool hasBankHolidayRedundant = false,
    bool isToday = false,
    bool isBankHoliday = false,
    bool isOutsideDay = false,
    bool isSelected = false,
    bool animatedSelection = true,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 46,
            height: 64,
            child: CalendarDayCell(
              date: DateTime(2026, 7, 23),
              displayText: displayText,
              shift: shift,
              backgroundColor: Colors.green.withValues(alpha: 0.3),
              cellColor: Colors.green,
              selectedBorderColor: Colors.indigo,
              isDayInLieu: isDayInLieu,
              isHoliday: isHoliday,
              hasEvents: hasEvents,
              isSaturdayService: isSaturdayService,
              hasNotes: hasNotes,
              hasBankHolidayRedundant: hasBankHolidayRedundant,
              isToday: isToday,
              isBankHoliday: isBankHoliday,
              isOutsideDay: isOutsideDay,
              isSelected: isSelected,
              animatedSelection: animatedSelection,
            ),
          ),
        ),
      ),
    );
  }

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('renders duty content without overflow at 320px', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildSubject());

    expect(find.text('23'), findsOneWidget);
    expect(find.text('PZ1/03'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('outside-month cells retain reduced opacity', (tester) async {
    await tester.pumpWidget(buildSubject(isOutsideDay: true));

    final opacity = tester.widget<Opacity>(
      find.descendant(
        of: find.byType(CalendarDayCell),
        matching: find.byType(Opacity),
      ),
    );
    expect(opacity.opacity, 0.4);
  });

  testWidgets('today retains its blue border', (tester) async {
    await tester.pumpWidget(buildSubject(isToday: true));

    final decoratedContainers = tester
        .widgetList<Container>(
          find.descendant(
            of: find.byType(CalendarDayCell),
            matching: find.byType(Container),
          ),
        )
        .where((container) => container.decoration is BoxDecoration);
    final decoration = decoratedContainers
        .map((container) => container.decoration! as BoxDecoration)
        .firstWhere((decoration) => decoration.border != null);
    final border = decoration.border! as Border;

    expect(border.top.color, Colors.blue);
    expect(border.top.width, 2);
  });

  testWidgets('rest-day holidays show R rather than H', (tester) async {
    await tester.pumpWidget(
      buildSubject(
        displayText: 'R',
        shift: 'R',
        isHoliday: true,
      ),
    );

    expect(find.text('R'), findsOneWidget);
    expect(find.text('H'), findsNothing);
  });

  testWidgets('renders supplied status badges and event marker',
      (tester) async {
    await tester.pumpWidget(
      buildSubject(
        hasEvents: true,
        isSaturdayService: true,
        hasNotes: true,
        hasBankHolidayRedundant: true,
      ),
    );

    expect(
        find.byKey(const ValueKey('calendar_day_sat_badge')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('calendar_day_note_badge')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('calendar_day_redundant_badge')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('calendar_day_event_badge')),
      findsOneWidget,
    );
  });

  testWidgets('selected modes preserve animated and filled-circle variants', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject(isSelected: true));
    expect(find.byType(AnimatedSelectedDayCell), findsOneWidget);

    await tester.pumpWidget(
      buildSubject(
        isSelected: true,
        animatedSelection: false,
        hasEvents: true,
      ),
    );

    expect(find.byType(AnimatedSelectedDayCell), findsNothing);
    expect(
      find.byKey(const ValueKey('calendar_day_event_badge')),
      findsNothing,
    );
    final dutyText = tester.widget<Text>(find.text('PZ1/03'));
    expect(dutyText.style?.color, Colors.white);
  });
}
