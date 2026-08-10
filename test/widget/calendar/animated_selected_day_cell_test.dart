import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/widgets/animated_selected_day_cell.dart';

void main() {
  Widget buildSubject({
    required bool isToday,
    required bool isBankHoliday,
    Color borderColor = Colors.green,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: AnimatedSelectedDayCell(
          backgroundColor: Colors.amber,
          isToday: isToday,
          isBankHoliday: isBankHoliday,
          borderColor: borderColor,
          child: const Text('15'),
        ),
      ),
    );
  }

  BoxDecoration selectedDayDecoration(WidgetTester tester) {
    final container = tester.widget<Container>(
      find.descendant(
        of: find.byType(AnimatedSelectedDayCell),
        matching: find.byType(Container),
      ),
    );
    return container.decoration! as BoxDecoration;
  }

  testWidgets('today retains its fixed blue border and content',
      (tester) async {
    await tester.pumpWidget(
      buildSubject(isToday: true, isBankHoliday: false),
    );

    final border = selectedDayDecoration(tester).border! as Border;
    expect(border.top.color, Colors.blue);
    expect(border.top.width, 2);
    expect(find.text('15'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });

  testWidgets('bank holiday retains its animated red border', (tester) async {
    await tester.pumpWidget(
      buildSubject(isToday: false, isBankHoliday: true),
    );

    final border = selectedDayDecoration(tester).border! as Border;
    expect(border.top.color, Colors.red);
    expect(border.top.width, inInclusiveRange(2.0, 3.5));

    await tester.pump(const Duration(milliseconds: 300));
    final animatedBorder = selectedDayDecoration(tester).border! as Border;
    expect(animatedBorder.top.color, Colors.red);
    expect(animatedBorder.top.width, inInclusiveRange(2.0, 3.5));
  });
}
