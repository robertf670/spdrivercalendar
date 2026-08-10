import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/utils/holiday_year_grouping.dart';
import 'package:spdrivercalendar/models/holiday.dart';

Holiday _h(String id, DateTime start, {String type = 'other'}) {
  return Holiday(
    id: id,
    startDate: start,
    endDate: start,
    type: type,
  );
}

void main() {
  test('groups by year newest-first and sorts dates ascending', () {
    final grouped = groupHolidaysByYear([
      _h('a', DateTime(2026, 7, 5)),
      _h('b', DateTime(2025, 12, 20)),
      _h('c', DateTime(2026, 1, 4)),
      _h('d', DateTime(2027, 6, 6)),
    ]);

    expect(grouped.keys.toList(), [2027, 2026, 2025]);
    expect(grouped[2026]!.map((h) => h.id).toList(), ['c', 'a']);
    expect(grouped[2025]!.single.id, 'b');
    expect(grouped[2027]!.single.id, 'd');
  });
}
