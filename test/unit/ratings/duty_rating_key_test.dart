import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/ratings/duty_rating_key.dart';
import 'package:spdrivercalendar/models/event.dart';

Event _event({
  required String title,
  DateTime? startDate,
  TimeOfDay startTime = const TimeOfDay(hour: 12, minute: 27),
  DateTime? endDate,
  TimeOfDay endTime = const TimeOfDay(hour: 21, minute: 55),
  List<String>? assignedDuties,
  bool isHoliday = false,
  String? sickDayType,
  bool bankHolidayRedundant = false,
  bool isWorkForOthers = false,
}) {
  final day = startDate ?? DateTime(2026, 9, 28);
  return Event(
    id: 'e1',
    title: title,
    startDate: day,
    startTime: startTime,
    endDate: endDate ?? day,
    endTime: endTime,
    assignedDuties: assignedDuties,
    isHoliday: isHoliday,
    sickDayType: sickDayType,
    bankHolidayRedundant: bankHolidayRedundant,
    isWorkForOthers: isWorkForOthers,
  );
}

void main() {
  group('DutyRatingKey.normalizeDutyCode', () {
    test('matches board lookup rules', () {
      expect(DutyRatingKey.normalizeDutyCode('1/39'), 'PZ1/39');
      expect(DutyRatingKey.normalizeDutyCode('PZ1/39'), 'PZ1/39');
      expect(DutyRatingKey.normalizeDutyCode('UNI:807/18'), '807/18');
      expect(DutyRatingKey.normalizeDutyCode('PZ1/39A (OT)'), 'PZ1/39');
      expect(DutyRatingKey.normalizeDutyCode('PZ1/10X'), 'PZ1/10X');
      expect(DutyRatingKey.normalizeDutyCode('PZ1/10XA'), 'PZ1/10X');
      expect(DutyRatingKey.normalizeDutyCode('DZ1/12A'), 'DZ1/12');
    });
  });

  group('DutyRatingKey.dayTypeForDate', () {
    test('uses weekday, Saturday service, and bank holidays', () {
      expect(
        DutyRatingKey.dayTypeForDate(
          DateTime(2026, 9, 28),
          isSaturdayService: false,
          isBankHoliday: false,
        ),
        'MON-FRI',
      );
      expect(
        DutyRatingKey.dayTypeForDate(
          DateTime(2026, 9, 26),
          isSaturdayService: false,
          isBankHoliday: false,
        ),
        'SAT',
      );
      expect(
        DutyRatingKey.dayTypeForDate(
          DateTime(2026, 9, 27),
          isSaturdayService: false,
          isBankHoliday: false,
        ),
        'SUN',
      );
      expect(
        DutyRatingKey.dayTypeForDate(
          DateTime(2026, 12, 29),
          isSaturdayService: true,
          isBankHoliday: true,
        ),
        'SAT',
      );
      expect(
        DutyRatingKey.dayTypeForDate(
          DateTime(2026, 3, 17),
          isSaturdayService: false,
          isBankHoliday: true,
        ),
        'SUN',
      );
    });
  });

  group('DutyRatingKey.eraFor', () {
    test('splits Zone 4 bill eras', () {
      expect(DutyRatingKey.eraFor('PZ4/24', DateTime(2025, 10, 18)), 'legacy');
      expect(DutyRatingKey.eraFor('PZ4/24', DateTime(2025, 10, 19)), '2324');
      expect(DutyRatingKey.eraFor('PZ4/24', DateTime(2026, 8, 22)), '2324');
      expect(
        DutyRatingKey.eraFor('PZ4/24', DateTime(2026, 8, 23)),
        '2324_20260823',
      );
      expect(DutyRatingKey.eraFor('PZ1/39', DateTime(2026, 8, 23)), 'current');
    });
  });

  group('DutyRatingKey.rateableCodesForEvent', () {
    test('uses assigned spare duty, not SP0800', () {
      expect(
        DutyRatingKey.rateableCodesForEvent(
          _event(title: 'SP0800', assignedDuties: const ['4/39']),
        ),
        ['PZ4/39'],
      );
      expect(
        DutyRatingKey.rateableCodesForEvent(_event(title: 'SP0800')),
        isEmpty,
      );
      expect(
        DutyRatingKey.rateableCodesForEvent(_event(title: '22B/01')),
        isEmpty,
      );
    });

    test('skips holiday, sick, redundant, and training titles', () {
      expect(
        DutyRatingKey.rateableCodesForEvent(
          _event(title: 'PZ1/39', isHoliday: true),
        ),
        isEmpty,
      );
      expect(
        DutyRatingKey.rateableCodesForEvent(
          _event(title: 'PZ1/39', sickDayType: 'normal'),
        ),
        isEmpty,
      );
      expect(
        DutyRatingKey.rateableCodesForEvent(
          _event(title: 'PZ1/39', bankHolidayRedundant: true),
        ),
        isEmpty,
      );
      expect(
        DutyRatingKey.rateableCodesForEvent(_event(title: 'Union')),
        isEmpty,
      );
    });

    test('keeps Work For Others duty codes', () {
      expect(
        DutyRatingKey.rateableCodesForEvent(
          _event(title: 'PZ1/39', isWorkForOthers: true),
        ),
        ['PZ1/39'],
      );
    });
  });

  group('DutyRatingKey.sign-off', () {
    test('hides Rate before sign-off and shows it after', () {
      final day = DateTime(2026, 9, 28);
      expect(
        DutyRatingKey.isAfterSignOff(
          startDate: day,
          startTime: const TimeOfDay(hour: 12, minute: 27),
          endDate: day,
          endTime: const TimeOfDay(hour: 21, minute: 55),
          now: DateTime(2026, 9, 28, 21, 55),
        ),
        isFalse,
      );
      expect(
        DutyRatingKey.isAfterSignOff(
          startDate: day,
          startTime: const TimeOfDay(hour: 12, minute: 27),
          endDate: day,
          endTime: const TimeOfDay(hour: 21, minute: 55),
          now: DateTime(2026, 9, 28, 21, 56),
        ),
        isTrue,
      );
    });

    test('overnight duties use the next calendar day', () {
      final day = DateTime(2026, 9, 28);
      expect(
        DutyRatingKey.signOffAt(
          startDate: day,
          startTime: const TimeOfDay(hour: 22, minute: 0),
          endDate: day,
          endTime: const TimeOfDay(hour: 6, minute: 0),
        ),
        DateTime(2026, 9, 29, 6, 0),
      );
    });
  });

  group('DutyRatingKey.canShowRateAction', () {
    test('settings off hides Rate even after sign-off', () {
      expect(
        DutyRatingKey.canShowRateAction(
          settingsEnabled: false,
          isRateable: true,
          afterSignOff: true,
        ),
        isFalse,
      );
      expect(
        DutyRatingKey.canShowRateAction(
          settingsEnabled: true,
          isRateable: true,
          afterSignOff: true,
        ),
        isTrue,
      );
    });
  });

  group('DutyRatingTarget ids', () {
    test('encodes slashes in Firestore document ids', () {
      const target = DutyRatingTarget(
        dutyCode: 'PZ1/39',
        dayType: 'MON-FRI',
        era: 'current',
        date: '2026-09-28',
      );
      expect(target.summaryId, 'PZ1/39|MON-FRI|current');
      expect(target.encodedSummaryId, 'PZ1_39|MON-FRI|current');
      expect(
        target.voteDocId('user-1'),
        'user-1_PZ1_39|MON-FRI|current_2026-09-28',
      );
    });
  });

  group('DutyRatingKey.targetsForEvent', () {
    test('Monday and Friday share the Mon-Fri summary id', () {
      final monday = DutyRatingKey.targetsForEvent(
        _event(title: '1/39', startDate: DateTime(2026, 9, 28)),
        isSaturdayService: false,
        isBankHoliday: false,
      ).single;
      final friday = DutyRatingKey.targetsForEvent(
        _event(title: '1/39', startDate: DateTime(2026, 10, 2)),
        isSaturdayService: false,
        isBankHoliday: false,
      ).single;
      expect(monday.summaryId, friday.summaryId);
      expect(monday.date, '2026-09-28');
      expect(friday.date, '2026-10-02');
    });
  });
}
