import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/services/duty_time_lookup_service.dart';
import 'package:spdrivercalendar/services/donnybrook_feature_service.dart';
import 'package:spdrivercalendar/services/jamestown_feature_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<DutyTimeLookupResult?> lookup(
    String zone,
    String shift,
    DateTime date, {
    bool overtime = false,
    DutyCsvLoader? csvLoader,
  }) {
    return DutyTimeLookupService.lookup(
      zone: zone,
      shiftNumber: shift,
      shiftDate: date,
      isOvertimeShift: overtime,
      csvLoader: csvLoader,
    );
  }

  void expectTime(TimeOfDay? actual, int hour, int minute) {
    expect(actual, TimeOfDay(hour: hour, minute: minute));
  }

  group('regular PZ duties', () {
    final weekday = DateTime(2026, 7, 20);

    test('loads report, sign-off, break, work, and route data', () async {
      final result = await lookup('Zone 1', 'PZ1/03', weekday);

      expect(result, isNotNull);
      expectTime(result!.startTime, 4, 22);
      expectTime(result.endTime, 12, 0);
      expectTime(result.breakStartTime, 9, 10);
      expectTime(result.breakEndTime, 10, 10);
      expect(result.workTime, const Duration(hours: 6, minutes: 38));
      expect(result.routes, ['39A']);
      expect(result.isNextDay, isFalse);
    });

    test('preserves workout duties without break data', () async {
      final result = await lookup('1', 'PZ1/01', weekday);

      expect(result, isNotNull);
      expectTime(result!.startTime, 4, 8);
      expectTime(result.endTime, 9, 39);
      expect(result.breakStartTime, isNull);
      expect(result.breakEndTime, isNull);
    });

    test('uses departure rather than report time for overtime', () async {
      final result = await lookup(
        'Zone 1',
        'PZ1/03',
        weekday,
        overtime: true,
      );

      expectTime(result!.startTime, 4, 30);
    });

    test('switches Zone 4 to route 23/24 duties at changeover', () async {
      final before = await lookup(
        'Zone 4',
        'PZ4/02',
        DateTime(2025, 10, 17),
      );
      final after = await lookup(
        'Zone 4',
        'PZ4/02',
        DateTime(2025, 10, 20),
      );

      expectTime(before!.startTime, 5, 32);
      expectTime(after!.startTime, 4, 32);
      expect(after.routes, ['24', '23']);
    });
  });

  group('UNI duties', () {
    test('prefers the seven-day file and uses finish time', () async {
      final result = await lookup(
        'Uni/Euro',
        '807/06',
        DateTime(2026, 7, 20),
      );

      expectTime(result!.startTime, 8, 27);
      expectTime(result.endTime, 13, 45);
      expect(result.breakStartTime, isNull);
      expect(result.routes, ['99']);
    });

    test('falls back to the weekday-only file on weekdays', () async {
      final result = await lookup(
        'Uni/Euro',
        '307/05',
        DateTime(2026, 7, 20),
      );

      expectTime(result!.startTime, 6, 22);
      expectTime(result.endTime, 19, 17);
      expectTime(result.breakStartTime, 9, 40);
      expectTime(result.breakEndTime, 15, 0);
    });

    test('does not consult the weekday file on Sundays', () async {
      final result = await lookup(
        'Uni/Euro',
        '307/05',
        DateTime(2026, 7, 19),
      );

      expect(result, isNull);
    });
  });

  group('special duty formats', () {
    test('matches bus-check day types', () async {
      final weekday = await lookup(
        'Bus Check',
        'BusCheck1',
        DateTime(2026, 7, 20),
      );
      final saturday = await lookup(
        'Bus Check',
        'BusCheck2',
        DateTime(2026, 7, 25),
      );

      expectTime(weekday!.startTime, 4, 0);
      expectTime(weekday.endTime, 9, 40);
      expectTime(saturday!.startTime, 6, 0);
      expectTime(saturday.endTime, 15, 0);
      expect(weekday.hasExtendedDetails, isFalse);
    });

    test('loads training rows', () async {
      final result = await lookup(
        'Training',
        'CPC',
        DateTime(2026, 7, 20),
      );

      expectTime(result!.startTime, 7, 45);
      expectTime(result.endTime, 15, 45);
      expect(result.hasExtendedDetails, isFalse);
    });

    test('preserves separate Jamestown zone files', () async {
      final date = DateTime(2026, 7, 20);
      final thirtyHour = await lookup(
        JamestownFeatureService.zoneLabel,
        '811/39',
        date,
      );
      final mainRoster = await lookup('Jamestown Road', '811/39', date);

      expectTime(thirtyHour!.startTime, 6, 52);
      expectTime(mainRoster!.startTime, 7, 2);
      expectTime(thirtyHour.endTime, 19, 8);
      expect(thirtyHour.routes, ['X30/38A']);
    });

    test('uses date-specific Donnybrook files and detects overnight', () async {
      final weekday = await lookup(
        DonnybrookFeatureService.zoneLabel,
        'DZ1/03',
        DateTime(2026, 7, 20),
      );
      final saturday = await lookup(
        DonnybrookFeatureService.zoneLabel,
        'DZ1/56',
        DateTime(2026, 7, 25),
      );
      final overnight = await lookup(
        DonnybrookFeatureService.zoneLabel,
        'DZ1/56',
        DateTime(2026, 7, 20),
      );

      expectTime(weekday!.endTime, 12, 20);
      expectTime(saturday!.startTime, 18, 47);
      expectTime(overnight!.endTime, 0, 52);
      expect(overnight.isNextDay, isTrue);
    });
  });

  test('returns null for an unknown duty code', () async {
    final result = await lookup(
      'Zone 1',
      'PZ1/999',
      DateTime(2026, 7, 20),
    );

    expect(result, isNull);
  });

  test('returns null for malformed rows and load failures', () async {
    final malformed = await lookup(
      'Zone 1',
      'PZ1/01',
      DateTime(2026, 7, 20),
      csvLoader: (_) async => 'header\nPZ1/01,too-short',
    );
    final loadFailure = await lookup(
      'Zone 1',
      'PZ1/01',
      DateTime(2026, 7, 20),
      csvLoader: (_) => Future.error(StateError('missing asset')),
    );

    expect(malformed, isNull);
    expect(loadFailure, isNull);
  });

  test('time parser rejects malformed values without throwing', () {
    expect(DutyTimeLookupService.parseTimeOfDay(null), isNull);
    expect(DutyTimeLookupService.parseTimeOfDay(''), isNull);
    expect(DutyTimeLookupService.parseTimeOfDay('not-a-time'), isNull);
    expect(DutyTimeLookupService.parseTimeOfDay('99:99'), isNull);
    expect(
      DutyTimeLookupService.parseTimeOfDay('04:08:00'),
      const TimeOfDay(hour: 4, minute: 8),
    );
  });
}
