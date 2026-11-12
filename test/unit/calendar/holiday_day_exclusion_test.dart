import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/services/holiday_day_exclusion_service.dart';
import 'package:spdrivercalendar/features/calendar/utils/events_for_day.dart';
import 'package:spdrivercalendar/features/calendar/utils/holiday_day_exclusion.dart';
import 'package:spdrivercalendar/features/calendar/utils/holiday_day_prompt.dart';
import 'package:spdrivercalendar/models/holiday.dart';

void main() {
  final winterWeek = Holiday(
    id: 'w1',
    startDate: DateTime(2026, 11, 8),
    endDate: DateTime(2026, 11, 14),
    type: 'winter',
  );

  test('taking the first day off a winter week keeps the rest', () {
    final pieces = holidayExcludingDay(
      winterWeek,
      DateTime(2026, 11, 8),
      idStamp: '1',
    );

    expect(pieces, hasLength(1));
    expect(pieces.single.startDate, DateTime(2026, 11, 9));
    expect(pieces.single.endDate, DateTime(2026, 11, 14));
    expect(pieces.single.type, 'winter');
    expect(pieces.single.containsDate(DateTime(2026, 11, 8)), isFalse);
    expect(pieces.single.containsDate(DateTime(2026, 11, 9)), isTrue);
  });

  test('taking a middle day splits the week', () {
    final pieces = holidayExcludingDay(
      winterWeek,
      DateTime(2026, 11, 11),
      idStamp: '2',
    );

    expect(pieces, hasLength(2));
    expect(pieces[0].endDate, DateTime(2026, 11, 10));
    expect(pieces[1].startDate, DateTime(2026, 11, 12));
    expect(pieces[0].id, isNot(pieces[1].id));
  });

  test('a one-day holiday is removed', () {
    final day = Holiday(
      id: 'd1',
      startDate: DateTime(2026, 11, 8),
      endDate: DateTime(2026, 11, 8),
      type: 'other',
    );

    expect(
      holidayExcludingDay(day, DateTime(2026, 11, 8), idStamp: '3'),
      isEmpty,
    );
  });

  test('calendar events drop the removed day and keep the rest of the week', () {
    final pieces = holidayExcludingDay(
      winterWeek,
      DateTime(2026, 11, 8),
      idStamp: '4',
    );

    expect(
      eventsForDay(
        day: DateTime(2026, 11, 8),
        persistedEvents: const [],
        holidays: pieces,
      ),
      isEmpty,
    );
    expect(
      eventsForDay(
        day: DateTime(2026, 11, 9),
        persistedEvents: const [],
        holidays: pieces,
      ).single.title,
      'Winter Holiday',
    );
  });

  test('prompt keeps a week day as a day in lieu', () {
    final copy = holidayDayPromptCopy(
      date: DateTime(2026, 11, 8),
      holidays: [winterWeek],
      creditsDayInLieu: true,
    );

    expect(copy.title, 'Remove this day?');
    expect(copy.confirmLabel, 'Remove this day');
    expect(copy.body, contains('Sunday 8 Nov'));
    expect(copy.body, contains('8 Nov'));
    expect(copy.body, contains('14 Nov'));
    expect(copy.body, contains('rest of that week stays booked'));
    expect(copy.body, contains('day in lieu'));
  });

  test('prompt cancels a one-day holiday', () {
    final copy = holidayDayPromptCopy(
      date: DateTime(2026, 11, 8),
      holidays: [
        Holiday(
          id: 'd1',
          startDate: DateTime(2026, 11, 8),
          endDate: DateTime(2026, 11, 8),
          type: 'other',
        ),
      ],
      creditsDayInLieu: false,
    );

    expect(copy.title, 'Cancel holiday?');
    expect(copy.confirmLabel, 'Cancel holiday');
    expect(copy.body, contains('Cancel it?'));
    expect(copy.body, isNot(contains('day in lieu')));
  });

  test('excludeDay splits the booking and credits one day in lieu', () async {
    final stored = <Holiday>[winterWeek];
    var lieu = 0;
    final service = HolidayDayExclusionService(
      loadHolidays: () async => List<Holiday>.from(stored),
      removeHoliday: (id) async {
        stored.removeWhere((holiday) => holiday.id == id);
      },
      addHoliday: (holiday) async {
        stored.add(holiday);
      },
      consumesAnnualLeave: (_) async => true,
      incrementDaysInLieu: ([amount = 1]) async => lieu += amount,
      now: () => DateTime(2026, 11, 12),
    );

    final removed = await service.excludeDay(DateTime(2026, 11, 8));

    expect(removed, isTrue);
    expect(lieu, 1);
    expect(stored, hasLength(1));
    expect(stored.single.containsDate(DateTime(2026, 11, 8)), isFalse);
    expect(stored.single.containsDate(DateTime(2026, 11, 14)), isTrue);
  });

  test('excludeDay does nothing when the date is not a holiday', () async {
    var removedCalls = 0;
    final service = HolidayDayExclusionService(
      loadHolidays: () async => [winterWeek],
      removeHoliday: (_) async {
        removedCalls++;
      },
      consumesAnnualLeave: (_) async => true,
      incrementDaysInLieu: ([amount = 1]) async => 0,
    );

    final removed = await service.excludeDay(DateTime(2026, 11, 1));

    expect(removed, isFalse);
    expect(removedCalls, 0);
  });
}
