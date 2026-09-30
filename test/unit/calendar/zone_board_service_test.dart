import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/services/zone_board_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(ZoneBoardService.clearCache);

  test('loads PZ1/01 Monday board from assets', () async {
    final board = await ZoneBoardService.getBoardForDuty(
      dutyTitle: 'PZ1/01',
      date: DateTime(2026, 8, 10), // Monday
    );

    expect(board, isNotNull);
    expect(board!.shift, 'PZ1/01');
    expect(board.sections, isNotEmpty);
    expect(board.sections.first.entries.first.action, 'Report');
    expect(board.sections.first.entries.first.time, '04:08');
  });

  test('loads Saturday board for PZ1/01', () async {
    final board = await ZoneBoardService.getBoardForDuty(
      dutyTitle: 'PZ1/01',
      date: DateTime(2026, 8, 8), // Saturday
    );

    expect(board, isNotNull);
    expect(board!.sections.first.entries.first.time, '04:20');
  });

  test('resolves OT title to base duty board', () async {
    final board = await ZoneBoardService.getBoardForDuty(
      dutyTitle: 'PZ1/01A (OT)',
      date: DateTime(2026, 8, 10),
    );

    expect(board, isNotNull);
    expect(board!.shift, 'PZ1/01');
  });

  test('loads 811/36 Jamestown board from assets', () async {
    final board = await ZoneBoardService.getBoardForDuty(
      dutyTitle: '811/36',
      date: DateTime(2026, 8, 10),
    );

    expect(board, isNotNull);
    expect(board!.shift, '811/36');
    expect(board.duty, '586');
    expect(board.sections, hasLength(1));

    final entries = board.sections.first.entries;
    expect(entries.first.action, 'Report');
    expect(entries.first.time, '04:42');
    expect(entries.first.location, 'Jamestown Road Garage');
    expect(entries[2].action, 'Route');
    expect(entries[2].route, '39A');
    expect(entries[2].location, 'Ongar');
    expect(entries[3].action, 'Call Controller');
    expect(entries.last.action, 'Finish');
    expect(entries.last.time, '10:20');
  });

  test('loads 811/39 split Jamestown board from assets', () async {
    final board = await ZoneBoardService.getBoardForDuty(
      dutyTitle: '811/39',
      date: DateTime(2026, 8, 10),
    );

    expect(board, isNotNull);
    expect(board!.shift, '811/39');
    expect(board.duty, '589');
    expect(board.sections, hasLength(2));
    expect(board.sections[0].type, 'firstHalf');
    expect(board.sections[1].type, 'secondHalf');
    expect(board.sections[0].entries.first.time, '06:52');
    expect(board.sections[1].entries.first.time, '15:38');
    expect(board.sections[1].entries.last.action, 'Finish');
    expect(board.sections[1].entries.last.time, '19:08');
  });

  test('loads remaining 30hr Jamestown boards', () async {
    final date = DateTime(2026, 8, 10);
    final codes = ['811/37', '811/38', '811/40'];

    for (final code in codes) {
      final board = await ZoneBoardService.getBoardForDuty(
        dutyTitle: code,
        date: date,
      );
      expect(board, isNotNull, reason: code);
      expect(board!.shift, code);
      expect(board.sections, isNotEmpty);
    }
  });

  test('returns null for Zone 2 weekdays until those boards exist', () async {
    final board = await ZoneBoardService.getBoardForDuty(
      dutyTitle: 'PZ2/01',
      date: DateTime(2026, 8, 10),
    );
    expect(board, isNull);
  });

  test('loads PZ2/01 Sunday board from assets', () async {
    final board = await ZoneBoardService.getBoardForDuty(
      dutyTitle: 'PZ2/01',
      date: DateTime(2026, 10, 4), // Sunday
    );

    expect(board, isNotNull);
    expect(board!.shift, 'PZ2/01');
    expect(board.duty, '201');
    final entries = board.sections.first.entries;
    expect(entries.first.action, 'Report');
    expect(entries.first.time, '06:07');
    expect(entries[1].action, 'Depart Garage');
    expect(entries[1].time, '06:15');
    expect(entries[2].action, 'Route');
    expect(entries[2].route, '13');
    expect(entries[2].location, 'Grange Castle');
    expect(entries[2].time, '07:00');
    expect(entries[3].location, 'Mountjoy Square');
    expect(entries[3].time, '08:30');
    expect(entries[4].location, 'Grange Castle');
    expect(entries[4].time, '10:00');
    expect(entries[5].action, 'Arrive');
    expect(entries[5].location, 'Mountjoy Square');
    expect(entries[5].time, '11:30');
    expect(entries[5].route, isNull);
    expect(entries.last.action, 'Finish');
    expect(entries.last.time, '11:46');
    expect(
      entries.map((e) => e.location),
      isNot(contains('Phibsboro Garage')),
    );
  });

  test('loads Sunday workout boards for PZ2/02, PZ2/05, and PZ2/07', () async {
    final sunday = DateTime(2026, 10, 4);

    final duty02 = await ZoneBoardService.getBoardForDuty(
      dutyTitle: 'PZ2/02',
      date: sunday,
    );
    expect(duty02, isNotNull);
    expect(duty02!.sections.first.entries[1].time, '06:45');
    expect(duty02.sections.first.entries[2].location, 'Grange Castle');
    expect(duty02.sections.first.entries[2].time, '07:30');
    expect(duty02.sections.first.entries[5].location, 'Mountjoy Square');
    expect(duty02.sections.first.entries[5].time, '12:00');

    final duty05 = await ZoneBoardService.getBoardForDuty(
      dutyTitle: 'PZ2/05',
      date: sunday,
    );
    expect(duty05!.sections.first.entries[2].time, '08:00');
    expect(duty05.sections.first.entries[5].time, '12:45');

    final duty07 = await ZoneBoardService.getBoardForDuty(
      dutyTitle: 'PZ2/07',
      date: sunday,
    );
    expect(duty07!.sections.first.entries[1].action, 'Route');
    expect(duty07.sections.first.entries[1].location, 'Mountjoy Square');
    expect(duty07.sections.first.entries[1].time, '10:00');
    expect(duty07.sections.first.entries[2].location, 'Grange Castle');
    expect(duty07.sections.first.entries[2].time, '11:30');
    expect(duty07.sections.first.entries[3].action, 'Arrive');
    expect(duty07.sections.first.entries[3].time, '13:15');
  });

  test('loads Sunday late workout boards for PZ2/25, PZ2/26, and PZ2/27',
      () async {
    final sunday = DateTime(2026, 10, 4);

    final duty25 = await ZoneBoardService.getBoardForDuty(
      dutyTitle: 'PZ2/25',
      date: sunday,
    );
    expect(duty25, isNotNull);
    expect(duty25!.sections, hasLength(1));
    final entries25 = duty25.sections.first.entries;
    expect(entries25[1].action, 'Depart Garage');
    expect(entries25[1].time, '19:25');
    expect(entries25[2].location, 'Grange Castle');
    expect(entries25[2].time, '20:15');
    expect(entries25[3].location, 'Mountjoy Square');
    expect(entries25[3].time, '21:45');
    expect(entries25[4].location, 'Grange Castle');
    expect(entries25[4].time, '23:00');
    expect(entries25[5].action, 'SPL');
    expect(entries25[5].location, 'Mountjoy Square');
    expect(entries25[5].time, '00:05');
    expect(entries25[5].route, isNull);
    expect(entries25.last.action, 'Finish');
    expect(entries25.last.time, '00:20');

    final duty26 = await ZoneBoardService.getBoardForDuty(
      dutyTitle: 'PZ2/26',
      date: sunday,
    );
    expect(duty26!.sections.first.entries[2].time, '20:30');
    expect(duty26.sections.first.entries[5].time, '00:15');
    expect(duty26.sections.first.entries.last.time, '00:25');

    final duty27 = await ZoneBoardService.getBoardForDuty(
      dutyTitle: 'PZ2/27',
      date: sunday,
    );
    expect(duty27!.sections.first.entries[1].time, '19:55');
    expect(duty27.sections.first.entries[2].time, '20:45');
    expect(duty27.sections.first.entries[5].time, '00:30');
    expect(duty27.sections.first.entries.last.time, '00:45');
  });

  test('loads PZ2/03 Sunday as a two-half board with Mountjoy meal', () async {
    final board = await ZoneBoardService.getBoardForDuty(
      dutyTitle: 'PZ2/03',
      date: DateTime(2026, 10, 4),
    );

    expect(board, isNotNull);
    expect(board!.sections, hasLength(2));
    expect(board.sections[0].type, 'firstHalf');
    expect(board.sections[1].type, 'secondHalf');

    final first = board.sections[0].entries;
    expect(first[1].action, 'Depart Garage');
    expect(first[1].time, '06:50');
    expect(first[2].location, 'Mountjoy Square');
    expect(first[2].time, '07:00');
    expect(first[3].location, 'Grange Castle');
    expect(first[3].time, '08:30');
    expect(first[4].action, 'Arrive');
    expect(first[4].location, 'Mountjoy Square');
    expect(first[4].time, '09:55');
    expect(first[4].route, isNull);

    final second = board.sections[1].entries;
    expect(second.first.action, 'Takes up at 11:00 Mountjoy Square');
    expect(second[1].location, 'Grange Castle');
    expect(second[1].time, '12:30');
    expect(second[2].action, 'Arrive');
    expect(second[2].location, 'Mountjoy Square');
    expect(second[2].time, '14:15');
    expect(second.last.action, 'Finish');
    expect(second.last.time, '14:31');
  });

  test('loads PZ2/04 Sunday as a two-half board with Mountjoy meal', () async {
    final board = await ZoneBoardService.getBoardForDuty(
      dutyTitle: 'PZ2/04',
      date: DateTime(2026, 10, 4),
    );

    expect(board, isNotNull);
    expect(board!.sections, hasLength(2));

    final first = board.sections[0].entries;
    expect(first[1].action, 'Depart Garage');
    expect(first[1].time, '07:15');
    expect(first[2].location, 'Mountjoy Square');
    expect(first[2].time, '07:30');
    expect(first[3].location, 'Grange Castle');
    expect(first[3].time, '09:00');
    expect(first[4].action, 'Arrive');
    expect(first[4].location, 'Mountjoy Square');
    expect(first[4].time, '10:25');
    expect(first[4].route, isNull);

    final second = board.sections[1].entries;
    expect(second.first.action, 'Takes up at 11:30 Mountjoy Square');
    expect(second[1].location, 'Grange Castle');
    expect(second[1].time, '13:00');
    expect(second[2].action, 'Arrive');
    expect(second[2].location, 'Mountjoy Square');
    expect(second[2].time, '14:45');
    expect(second.last.action, 'Finish');
    expect(second.last.time, '15:01');
  });

  test('loads PZ2/06 and PZ2/08 Sunday meal boards', () async {
    final duty06 = await ZoneBoardService.getBoardForDuty(
      dutyTitle: 'PZ2/06',
      date: DateTime(2026, 10, 4),
    );
    expect(duty06, isNotNull);
    expect(duty06!.sections, hasLength(2));
    expect(duty06.sections[0].entries[2].location, 'Mountjoy Square');
    expect(duty06.sections[0].entries[2].time, '08:00');
    expect(duty06.sections[0].entries[4].action, 'Arrive');
    expect(duty06.sections[0].entries[4].time, '10:55');
    expect(duty06.sections[1].entries.first.action,
        'Takes up at 12:00 Mountjoy Square');
    expect(duty06.sections[1].entries[1].time, '13:30');
    expect(duty06.sections[1].entries.last.time, '15:31');

    final duty08 = await ZoneBoardService.getBoardForDuty(
      dutyTitle: 'PZ2/08',
      date: DateTime(2026, 10, 4),
    );
    expect(duty08, isNotNull);
    expect(duty08!.sections, hasLength(2));
    expect(duty08.sections[0].entries[1].time, '12:00');
    expect(duty08.sections[0].entries[2].location, 'Mountjoy Square');
    expect(duty08.sections[0].entries[2].time, '12:15');
    expect(duty08.sections[0].entries[3].location, 'Grange Castle');
    expect(duty08.sections[0].entries[3].time, '13:45');
    expect(duty08.sections[0].entries[4].action, 'Arrive');
    expect(duty08.sections[0].entries[4].time, '15:30');
    expect(duty08.sections[1].entries.first.action,
        'Takes up at 17:15 Mountjoy Square');
    expect(duty08.sections[1].entries[1].time, '19:00');
    expect(duty08.sections[1].entries[2].time, '20:30');
    expect(duty08.sections[1].entries.last.time, '20:46');
  });

  test('uses legacy Zone 4 boards before 23 Aug 2026', () async {
    final before = await ZoneBoardService.getBoardForDuty(
      dutyTitle: 'PZ4/01',
      date: DateTime(2026, 8, 21), // Friday
    );

    expect(before, isNotNull);
    expect(before!.shift, 'PZ4/01');
    expect(before.sections.first.entries.last.time, '09:20');
  });

  test('uses new Zone 4 Monday-Friday boards from 23 Aug 2026', () async {
    final after = await ZoneBoardService.getBoardForDuty(
      dutyTitle: 'PZ4/01',
      date: DateTime(2026, 8, 24), // Monday
    );

    expect(after, isNotNull);
    expect(after!.shift, 'PZ4/01');
    expect(after.sections.first.entries.last.action, 'Finish');
    expect(after.sections.first.entries.last.time, '09:50');
  });

  test('uses new Zone 4 Saturday boards from 23 Aug 2026', () async {
    final saturday = await ZoneBoardService.getBoardForDuty(
      dutyTitle: 'PZ4/01',
      date: DateTime(2026, 8, 29), // Saturday
    );

    expect(saturday, isNotNull);
    expect(saturday!.sections.first.entries.first.time, '04:07');
    expect(saturday.sections.first.entries.last.action, 'Finish');
    expect(saturday.sections.first.entries.last.time, '09:05');
  });

  test('uses new Zone 4 Sunday boards from 23 Aug 2026', () async {
    final sunday = await ZoneBoardService.getBoardForDuty(
      dutyTitle: 'PZ4/01',
      date: DateTime(2026, 8, 30), // Sunday
    );

    expect(sunday, isNotNull);
    expect(sunday!.sections.first.entries.first.time, '04:17');
    expect(sunday.sections.first.entries.last.action, 'Finish');
    expect(sunday.sections.first.entries.last.time, '09:05');
  });

  test('loads new Zone 4 split board for PZ4/31 from 23 Aug 2026', () async {
    final board = await ZoneBoardService.getBoardForDuty(
      dutyTitle: 'PZ4/31',
      date: DateTime(2026, 8, 24),
    );

    expect(board, isNotNull);
    expect(board!.sections, hasLength(2));
    expect(board.sections[0].entries.first.action, 'Takes up 15:20');
    expect(board.sections[1].entries.first.action, 'Report');
    expect(board.sections[1].entries.first.time, '19:07');
    expect(board.sections[1].entries.last.action, 'Finish');
    expect(board.sections[1].entries.last.time, '23:10');
  });

  test('dayKey override loads Saturday board on a Monday date', () async {
    final board = await ZoneBoardService.getBoardForDuty(
      dutyTitle: 'PZ1/01',
      date: DateTime(2026, 8, 10), // Monday
      dayKey: 'SAT',
    );

    expect(board, isNotNull);
    expect(board!.sections.first.entries.first.time, '04:20');
  });

  test('lists Zone 1 Monday-Friday duty codes from assets', () async {
    final codes = await ZoneBoardService.listDutyCodes(
      zoneNumber: '1',
      dayKey: 'MON-FRI',
      date: DateTime(2026, 9, 11),
    );

    expect(codes, containsAll(['PZ1/01', 'PZ1/67']));
  });
}
