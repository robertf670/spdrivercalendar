import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/utils/zone_board_mapper.dart';

void main() {
  group('ZoneBoardMapper.normalizeDutyCode', () {
    test('keeps standard duty codes', () {
      expect(ZoneBoardMapper.normalizeDutyCode('PZ1/01'), 'PZ1/01');
      expect(ZoneBoardMapper.normalizeDutyCode('PZ3/1X'), 'PZ3/1X');
      expect(ZoneBoardMapper.normalizeDutyCode('PZ4/12'), 'PZ4/12');
      expect(ZoneBoardMapper.normalizeDutyCode('811/36'), '811/36');
    });

    test('strips OT suffixes', () {
      expect(ZoneBoardMapper.normalizeDutyCode('PZ1/01 (OT)'), 'PZ1/01');
      expect(ZoneBoardMapper.normalizeDutyCode('PZ1/01A (OT)'), 'PZ1/01');
      expect(ZoneBoardMapper.normalizeDutyCode('PZ1/10XB (OT)'), 'PZ1/10X');
      expect(ZoneBoardMapper.normalizeDutyCode('811/36A (OT)'), '811/36');
    });

    test('rejects unsupported titles', () {
      expect(ZoneBoardMapper.normalizeDutyCode('307/01'), isNull);
      expect(ZoneBoardMapper.normalizeDutyCode('PZ2/01'), isNull);
      expect(ZoneBoardMapper.normalizeDutyCode('SP0800'), isNull);
    });
  });

  group('ZoneBoardMapper.assetPathForDuty', () {
    test('maps zone and Jamestown codes to board assets', () {
      expect(
        ZoneBoardMapper.assetPathForDuty('PZ1/01'),
        'assets/Zone1_Boards.json',
      );
      expect(
        ZoneBoardMapper.assetPathForDuty('PZ3/01'),
        'assets/Zone3_Boards.json',
      );
      expect(
        ZoneBoardMapper.assetPathForDuty('PZ4/01'),
        'assets/Zone4_Boards.json',
      );
      expect(
        ZoneBoardMapper.assetPathForDuty('811/36'),
        'assets/Jamestown_Boards.json',
      );
    });
  });

  group('ZoneBoardMapper.dayKeyForDate', () {
    test('weekday is MON-FRI', () {
      expect(
        ZoneBoardMapper.dayKeyForDate(
          DateTime(2026, 8, 10), // Monday
          isSaturdayService: false,
          isBankHoliday: false,
        ),
        'MON-FRI',
      );
    });

    test('Saturday and Saturday-service use SAT', () {
      expect(
        ZoneBoardMapper.dayKeyForDate(
          DateTime(2026, 8, 8), // Saturday
          isSaturdayService: false,
          isBankHoliday: false,
        ),
        'SAT',
      );
      expect(
        ZoneBoardMapper.dayKeyForDate(
          DateTime(2026, 8, 10),
          isSaturdayService: true,
          isBankHoliday: false,
        ),
        'SAT',
      );
    });

    test('Sunday and bank holiday use SUN', () {
      expect(
        ZoneBoardMapper.dayKeyForDate(
          DateTime(2026, 8, 9), // Sunday
          isSaturdayService: false,
          isBankHoliday: false,
        ),
        'SUN',
      );
      expect(
        ZoneBoardMapper.dayKeyForDate(
          DateTime(2026, 8, 10),
          isSaturdayService: false,
          isBankHoliday: true,
        ),
        'SUN',
      );
    });

    test('Saturday service wins over bank holiday', () {
      expect(
        ZoneBoardMapper.dayKeyForDate(
          DateTime(2026, 8, 10),
          isSaturdayService: true,
          isBankHoliday: true,
        ),
        'SAT',
      );
    });
  });

  group('ZoneBoardMapper.fromDayData', () {
    test('maps PZ1/01-style board into UniversalBoard sections', () {
      final board = ZoneBoardMapper.fromDayData('PZ1/01', {
        'duty': '001',
        'signoff': '09:39',
        'board': [
          ['', 'Duty', '1', 'Reports at 04:08', '', ''],
          ['SPL', '', '', 'Departs Garage', '', '04:16'],
          ['C1', '', '', 'Sandymount', '', '04:46'],
          ['SPL', '', '', 'Adamstown Stn', '09:04', ''],
          ['', '', '', 'Phibsboro Garage', '09:39', ''],
          ['---', '', '', '', '', ''],
          ['', 'Finish', 'Duty', '', '', ''],
        ],
      });

      expect(board, isNotNull);
      expect(board!.shift, 'PZ1/01');
      expect(board.duty, '001');
      // Trailing Finish-only Part 2 is folded into the first half.
      expect(board.sections, hasLength(1));
      expect(board.sections[0].type, 'firstHalf');

      final first = board.sections[0].entries;
      expect(first[0].action, 'Report');
      expect(first[0].time, '04:08');
      expect(first[1].action, 'Depart Garage');
      expect(first[1].time, '04:16');
      expect(first[2].action, 'Route');
      expect(first[2].route, 'C1');
      expect(first[2].location, 'Sandymount');
      expect(first[2].time, '04:46');
      expect(first[3].action, 'Arrive');
      expect(first[3].time, '09:04');
      expect(first[3].location, 'Adamstown Stn');
      expect(first.last.action, 'Finish');
      expect(first.last.time, '09:39');
    });

    test('keeps real second-half content after divider', () {
      final board = ZoneBoardMapper.fromDayData('PZ1/99', {
        'duty': '099',
        'signoff': '18:00',
        'board': [
          ['', 'Duty', '99', 'Reports at 05:00', '', ''],
          ['C1', '', '', 'Sandymount', '', '05:30'],
          ['---', '', '', '', '', ''],
          ['', 'Duty', '99', 'Takes up at 14:00', '', ''],
          ['C2', '', '', 'Adamstown Stn', '', '14:30'],
          ['', 'Finish', 'Duty', '', '', ''],
        ],
      });

      expect(board, isNotNull);
      expect(board!.sections, hasLength(2));
      expect(board.sections[1].type, 'secondHalf');
      expect(board.sections[1].entries.first.action, 'Takes up at 14:00');
      expect(board.sections[1].entries.last.action, 'Finish');
    });

    test('shows SPL instead of Route SPL', () {
      final board = ZoneBoardMapper.fromDayData('PZ1/01', {
        'duty': '001',
        'board': [
          ['SPL', '', '', 'Sandymount', '', '04:46'],
          ['SPL', '', '', 'Adamstown Stn', '09:04', ''],
        ],
      });

      expect(board, isNotNull);
      final entries = board!.sections.single.entries;
      expect(entries[0].action, 'SPL');
      expect(entries[0].route, isNull);
      expect(entries[0].location, 'Sandymount');
      expect(entries[1].action, 'Arrive');
      expect(entries[1].route, isNull);
    });

    test('maps Zone3 report note with bare Reports time', () {
      final board = ZoneBoardMapper.fromDayData('PZ3/01', {
        'duty': '301',
        'board': [
          ['', '', '', 'Duty 301 Reports 04:52 Garage', '', ''],
          ['39', '', '', 'Belfield', '', '05:20'],
        ],
      });

      expect(board, isNotNull);
      expect(board!.sections.single.entries.first.action, 'Report');
      expect(board.sections.single.entries.first.time, '04:52');
      expect(board.sections.single.entries.first.location, 'Garage');
    });
  });
}
