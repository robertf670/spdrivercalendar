import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/services/holiday_booking_service.dart';
import 'package:spdrivercalendar/models/holiday.dart';

void main() {
  test('addWinterHoliday creates 7-day winter range', () async {
    Holiday? saved;
    final service = HolidayBookingService(
      addHoliday: (holiday) async {
        saved = holiday;
      },
      now: () => DateTime(2026, 8, 4, 12),
    );

    await service.addWinterHoliday(DateTime(2026, 12, 6));

    expect(saved, isNotNull);
    expect(saved!.type, 'winter');
    expect(saved!.startDate, DateTime(2026, 12, 6));
    expect(saved!.endDate, DateTime(2026, 12, 12));
    expect(saved!.id, DateTime(2026, 8, 4, 12).millisecondsSinceEpoch.toString());
  });

  test('addSummerHoliday uses 6 or 13 day spans', () async {
    final saved = <Holiday>[];
    final service = HolidayBookingService(
      addHoliday: (holiday) async {
        saved.add(holiday);
      },
      now: () => DateTime(2026, 1, 1),
    );

    await service.addSummerHoliday(
      startSunday: DateTime(2026, 7, 5),
      durationWeeks: 1,
    );
    await service.addSummerHoliday(
      startSunday: DateTime(2026, 7, 5),
      durationWeeks: 2,
    );

    expect(saved[0].endDate, DateTime(2026, 7, 11));
    expect(saved[1].endDate, DateTime(2026, 7, 18));
    expect(saved[0].type, 'summer');
  });

  test('addSingleDayHolidays counts successes and notifies DIL', () async {
    final ids = <String>[];
    var dilHooks = 0;
    final service = HolidayBookingService(
      addHoliday: (holiday) async {
        if (holiday.startDate.day == 5) {
          throw Exception('fail one');
        }
        ids.add(holiday.id);
      },
      onDayInLieuAdded: () async {
        dilHooks++;
      },
    );

    final count = await service.addSingleDayHolidays(
      sortedDates: [
        DateTime(2026, 8, 4),
        DateTime(2026, 8, 5),
        DateTime(2026, 8, 6),
      ],
      type: 'day_in_lieu',
      idPrefix: 'day_in_lieu',
      notifyDayInLieu: true,
    );

    expect(count, 2);
    expect(dilHooks, 2);
    expect(ids, everyElement(startsWith('day_in_lieu_')));
  });
}
