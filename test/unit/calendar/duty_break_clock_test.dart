import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/utils/duty_break_clock.dart';

void main() {
  group('DutyBreakClock.fromTimes', () {
    test('PZ1/83 take-up stays 20:05 Aston Quay; walk is not extra break', () {
      expect(
        DutyBreakClock.fromTimes(
          startBreak: '18:38:00',
          breakReport: '19:45:00',
          finishBreak: '20:05:00',
          startLocation: 'GARAGE',
          finishLocation: '39A-ASTONQ',
          shiftCode: 'PZ1/83',
        ),
        '18:38 - 20:05 walk 20m',
      );
    });

    test('Route 13 street meal then garage take-up is walking time', () {
      expect(
        DutyBreakClock.fromTimes(
          startBreak: '11:00:00',
          breakReport: '11:40:00',
          finishBreak: '12:00:00',
          startLocation: 'MISQ',
          finishLocation: 'GARAGE',
          shiftCode: '13/01',
        ),
        '11:00 - 12:00 walk 20m',
      );
    });

    test('street-to-street location change is not walking time', () {
      expect(
        DutyBreakClock.fromTimes(
          startBreak: '18:38:00',
          breakReport: '19:45:00',
          finishBreak: '20:05:00',
          startLocation: '39A-ASTONQ',
          finishLocation: '39A-BWALK',
          shiftCode: 'PZ1/83',
        ),
        '18:38 - 20:05',
      );
    });

    test('Zone 4 garage change is not walking time', () {
      expect(
        DutyBreakClock.fromTimes(
          startBreak: '18:38:00',
          breakReport: '19:45:00',
          finishBreak: '20:05:00',
          startLocation: 'GARAGE',
          finishLocation: 'PSQE-PQ(9)',
          shiftCode: 'PZ4/16',
        ),
        '18:38 - 20:05',
      );
    });

    test('same-location report-to-take-up gap is not walking time', () {
      expect(
        DutyBreakClock.fromTimes(
          startBreak: '10:35:00',
          breakReport: '14:32:00',
          finishBreak: '14:35:00',
          startLocation: 'Garage',
          finishLocation: 'Garage',
        ),
        '10:35 - 14:35',
      );
    });

    test('matching breakreport and finishbreak stays a plain meal range', () {
      expect(
        DutyBreakClock.fromTimes(
          startBreak: '09:10:00',
          breakReport: '10:10:00',
          finishBreak: '10:10:00',
          startLocation: 'GARAGE',
          finishLocation: 'GARAGE',
        ),
        '09:10 - 10:10',
      );
    });

    test('workout tokens stay Workout', () {
      expect(
        DutyBreakClock.fromTimes(
          startBreak: 'nan',
          breakReport: 'nan',
          finishBreak: 'nan',
        ),
        'Workout',
      );
    });

    test('UNI equal start and finish is a workout', () {
      expect(
        DutyBreakClock.fromTimes(
          startBreak: '10:00:00',
          breakReport: '10:00:00',
          finishBreak: '10:00:00',
          startLocation: 'Garage',
          finishLocation: 'Garage',
          equalTimesAreWorkout: true,
        ),
        'Workout',
      );
    });
  });

  group('DutyBreakClock.fromCsvParts', () {
    test('reads startbreak, breakreport, finishbreak, and locations', () {
      final parts = [
        'PZ1/83',
        '007083',
        '16:10:00',
        '16:13:00',
        'GARAGE',
        '18:38:00',
        'GARAGE',
        '19:45:00',
        '20:05:00',
        '39A-ASTONQ',
      ];
      expect(DutyBreakClock.fromCsvParts(parts), '18:38 - 20:05 walk 20m');
    });
  });

  group('DutyBreakClock display helpers', () {
    test('duration paren is meal plus walk, not start-to-take-up', () {
      expect(
        DutyBreakClock.durationParen(
          '18:38 - 20:05 walk 20m',
          compact: false,
        ),
        '1h 7m, 20m walk',
      );
      expect(
        DutyBreakClock.durationParen(
          '18:38 - 20:05 walk 20m',
          compact: true,
        ),
        '1h7, 20m walk',
      );
    });

    test('card line keeps take-up time with Aston Quay', () {
      expect(
        DutyBreakClock.formatLine(
          breakTime: '18:38 - 20:05 walk 20m',
          startLocation: 'Garage',
          endLocation: 'Aston Q',
          compact: false,
        ),
        'Garage 18:38 - 20:05 Aston Q (1h 7m, 20m walk)',
      );
    });

    test('compact line fits abbreviated locations on a narrow phone', () {
      expect(
        DutyBreakClock.formatLine(
          breakTime: '18:38 - 20:05 walk 20m',
          startLocation: 'Gar',
          endLocation: 'AQ',
          compact: true,
        ),
        'Gar 18:38–20:05 AQ (1h7, 20m walk)',
      );
    });

    test('OT overlay second half starts at take-up, not meal end', () {
      expect(
        DutyBreakClock.overlayTimes('18:38 - 20:05 walk 20m'),
        ('18:38', '20:05'),
      );
    });
  });
}
