import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/search/utils/search_default_date_range.dart';

void main() {
  test('October 2026 starts on the first Sunday, 4 Oct, through month end', () {
    final range = searchDefaultDateRange(DateTime(2026, 10, 18));
    expect(range.start, DateTime(2026, 10, 4));
    expect(range.end, DateTime(2026, 10, 31));
    expect(range.start.weekday, DateTime.sunday);
  });

  test('when the 1st is a Sunday, the range starts on the 1st', () {
    final range = searchDefaultDateRange(DateTime(2026, 2, 10));
    expect(range.start, DateTime(2026, 2, 1));
    expect(range.end, DateTime(2026, 2, 28));
  });
}
