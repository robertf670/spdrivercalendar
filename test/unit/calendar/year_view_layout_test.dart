import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/utils/year_view_layout.dart';

void main() {
  test('phone layout uses two columns', () {
    expect(yearViewCrossAxisCount(320), 2);
    expect(yearViewCrossAxisCount(599), 2);
    expect(yearViewCrossAxisCount(600), 3);
    expect(yearViewCrossAxisCount(901), 4);
  });

  test('current year scrolls to focused month, other years to January', () {
    final now = DateTime(2026, 9, 18);
    expect(
      yearViewScrollTargetMonth(
        displayedYear: 2026,
        now: now,
        focusedMonth: 9,
      ),
      9,
    );
    expect(
      yearViewScrollTargetMonth(displayedYear: 2026, now: now),
      9,
    );
    expect(
      yearViewScrollTargetMonth(displayedYear: 2025, now: now, focusedMonth: 9),
      1,
    );
  });

  test('load order puts the visible month first', () {
    expect(yearViewMonthLoadOrder(9).first, 9);
    expect(yearViewMonthLoadOrder(9), hasLength(12));
    expect(yearViewMonthLoadOrder(9).toSet(), {
      for (var month = 1; month <= 12; month++) month,
    });
  });

  test('September is below the first screen on a 320px phone', () {
    const width = 320.0;
    final padding = yearViewGridPadding(width);
    final spacing = yearViewGridSpacing(width);
    final aspect = yearViewTileAspectRatio(width: width, textScale: 1);
    final offset = yearViewMonthScrollOffset(
      month: 9,
      crossAxisCount: yearViewCrossAxisCount(width),
      viewportWidth: width,
      padding: padding,
      spacing: spacing,
      aspectRatio: aspect,
    );
    expect(offset, greaterThan(400));
    expect(
      yearViewMonthScrollOffset(
        month: 1,
        crossAxisCount: 2,
        viewportWidth: width,
        padding: padding,
        spacing: spacing,
        aspectRatio: aspect,
      ),
      0,
    );
  });
}
