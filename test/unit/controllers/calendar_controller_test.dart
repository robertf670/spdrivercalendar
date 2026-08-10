import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/controllers/calendar_controller.dart';

void main() {
  late CalendarController controller;
  late DateTime initialDay;

  setUp(() {
    initialDay = DateTime(2026, 7, 23);
    controller = CalendarController(
      initialFocusedDay: initialDay,
      initialSelectedDay: initialDay,
    );
  });

  tearDown(() {
    controller.dispose();
  });

  test('starts with the supplied selection and focused month', () {
    expect(controller.selectedDay, initialDay);
    expect(controller.focusedDay, initialDay);
    expect(controller.isVisibleMonthLoading, isFalse);
  });

  test('selectDay updates selection and focus with one notification', () {
    var notifications = 0;
    controller.addListener(() => notifications++);
    final selected = DateTime(2026, 8, 4);

    controller.selectDay(selected, focusedDay: selected);

    expect(controller.selectedDay, selected);
    expect(controller.focusedDay, selected);
    expect(notifications, 1);
  });

  test('selection can be cleared without changing the focused month', () {
    controller.selectDay(null);

    expect(controller.selectedDay, isNull);
    expect(controller.focusedDay, initialDay);
  });

  test('identical state updates do not notify listeners', () {
    var notifications = 0;
    controller.addListener(() => notifications++);

    controller.selectDay(initialDay, focusedDay: initialDay);
    controller.setFocusedDay(initialDay);
    controller.setVisibleMonthLoading(false);

    expect(notifications, 0);
  });

  test('visible-month loading transitions are observable', () {
    final focused = DateTime(2026, 8, 1);
    final states = <(DateTime, bool)>[];
    controller.addListener(() {
      states.add((
        controller.focusedDay,
        controller.isVisibleMonthLoading,
      ));
    });

    controller.beginVisibleMonthLoad(focused);
    controller.setVisibleMonthLoading(false);

    expect(states, [(focused, true), (focused, false)]);
  });
}
