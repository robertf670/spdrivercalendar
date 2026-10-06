import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/utils/spare_time_options.dart';

void main() {
  test('spare start times run from 04:00 through 19:00 plus Custom', () {
    final times = spareTimeOptions();

    expect(times.first, '04:00');
    expect(times, contains('16:15'));
    expect(times, contains('18:45'));
    expect(times, contains('19:00'));
    expect(times.last, spareCustomTimeOption);
    expect(times, isNot(contains('19:15')));
  });

  test('formats a custom spare clock time', () {
    expect(formatSpareClockTime(19, 7), '19:07');
    expect(isSpareCustomTimeOption(spareCustomTimeOption), isTrue);
    expect(isSpareCustomTimeOption('19:00'), isFalse);
  });
}
