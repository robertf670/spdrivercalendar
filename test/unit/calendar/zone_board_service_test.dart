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

  test('loads PZ2/01 Monday-Friday board from the weekday sheet', () async {
    final board = await ZoneBoardService.getBoardForDuty(
      dutyTitle: 'PZ2/01',
      date: DateTime(2026, 8, 10), // Monday
    );

    expect(board, isNotNull);
    expect(board!.shift, 'PZ2/01');
    expect(board.duty, '201');
    expect(board.sections, hasLength(2));
    final first = board.sections[0].entries;
    expect(first.first.action, 'Report');
    expect(first.first.time, '05:02');
    expect(first[1].action, 'Depart Garage');
    expect(first[1].time, '05:10');
    expect(first[2].location, 'Grange Castle');
    expect(first[2].time, '06:00');
    expect(first[3].action, 'Arrive');
    expect(first[3].location, 'Mountjoy Square');
    expect(first[3].time, '08:00');
    expect(first[3].route, isNull);
    expect(first[4].action, 'Break');
    expect(first[4].time, '08:05');
    expect(first[4].location, 'Mountjoy Square');
    expect(
      board.sections[1].entries.first.action,
      'Takes up at 09:00 Mountjoy Square',
    );
    expect(board.sections[1].entries[1].action, 'Route');
    expect(board.sections[1].entries[1].route, '13');
    expect(board.sections[1].entries[1].location, 'Mountjoy Square');
    expect(board.sections[1].entries[1].time, '09:00');
    expect(board.sections[1].entries[2].location, 'Grange Castle');
    expect(board.sections[1].entries[2].time, '10:42');
    expect(board.sections[1].entries.last.action, 'Finish');
    expect(board.sections[1].entries.last.time, '12:46');
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
    expect(first.last.action, 'Break');
    expect(first.last.time, '10:00');
    expect(first.last.location, 'Mountjoy Square');

    final second = board.sections[1].entries;
    expect(second.first.action, 'Takes up at 11:00 Mountjoy Square');
    expect(second[1].action, 'Route');
    expect(second[1].location, 'Mountjoy Square');
    expect(second[1].time, '11:00');
    expect(second[2].location, 'Grange Castle');
    expect(second[2].time, '12:30');
    expect(second[3].action, 'Arrive');
    expect(second[3].location, 'Mountjoy Square');
    expect(second[3].time, '14:15');
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
    expect(second[1].location, 'Mountjoy Square');
    expect(second[1].time, '11:30');
    expect(second[2].location, 'Grange Castle');
    expect(second[2].time, '13:00');
    expect(second[3].action, 'Arrive');
    expect(second[3].location, 'Mountjoy Square');
    expect(second[3].time, '14:45');
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
    expect(duty06.sections[1].entries[1].location, 'Mountjoy Square');
    expect(duty06.sections[1].entries[1].time, '12:00');
    expect(duty06.sections[1].entries[2].time, '13:30');
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
    expect(duty08.sections[1].entries[1].location, 'Mountjoy Square');
    expect(duty08.sections[1].entries[1].time, '17:15');
    expect(duty08.sections[1].entries[2].time, '19:00');
    expect(duty08.sections[1].entries[3].time, '20:30');
    expect(duty08.sections[1].entries.last.time, '20:46');
  });

  test('loads every Sunday Zone 2 duty board from the bus sheet', () async {
    final sunday = DateTime(2026, 10, 4);
    const codes = [
      'PZ2/01', 'PZ2/02', 'PZ2/03', 'PZ2/04', 'PZ2/05', 'PZ2/06', 'PZ2/07',
      'PZ2/08', 'PZ2/09', 'PZ2/10', 'PZ2/11', 'PZ2/12', 'PZ2/13', 'PZ2/14',
      'PZ2/15', 'PZ2/16', 'PZ2/17', 'PZ2/18', 'PZ2/19', 'PZ2/20', 'PZ2/21',
      'PZ2/22', 'PZ2/23', 'PZ2/24', 'PZ2/25', 'PZ2/26', 'PZ2/27',
      'PZ2/1X', 'PZ2/2X', 'PZ2/3X', 'PZ2/4X', 'PZ2/5X', 'PZ2/6X',
    ];

    for (final code in codes) {
      final board = await ZoneBoardService.getBoardForDuty(
        dutyTitle: code,
        date: sunday,
      );
      expect(board, isNotNull, reason: code);
      expect(board!.shift, code);
      expect(board.sections, isNotEmpty);
      expect(board.sections.last.entries.last.action, 'Finish');
    }

    final listed = await ZoneBoardService.listDutyCodes(
      zoneNumber: '2',
      dayKey: 'SUN',
      date: sunday,
    );
    expect(listed, unorderedEquals(codes));
  });

  test('loads later Sunday meal boards from bus movements', () async {
    final sunday = DateTime(2026, 10, 4);

    final duty11 = await ZoneBoardService.getBoardForDuty(
      dutyTitle: 'PZ2/11',
      date: sunday,
    );
    expect(duty11!.sections, hasLength(2));
    expect(duty11.sections[0].entries[3].action, 'Arrive');
    expect(duty11.sections[0].entries[3].time, '16:30');
    expect(duty11.sections[1].entries.first.action,
        'Takes up at 18:45 Mountjoy Square');
    expect(duty11.sections[1].entries[1].action, 'Route');
    expect(duty11.sections[1].entries[1].location, 'Mountjoy Square');
    expect(duty11.sections[1].entries[1].time, '18:45');
    expect(duty11.sections[1].entries[2].action, 'SPL');
    expect(duty11.sections[1].entries[2].location, 'Grange Castle');
    expect(duty11.sections[1].entries[2].time, '20:15');
    expect(duty11.sections[1].entries.last.time, '21:00');

    final duty19 = await ZoneBoardService.getBoardForDuty(
      dutyTitle: 'PZ2/19',
      date: sunday,
    );
    expect(duty19!.sections[1].entries[1].location, 'Mountjoy Square');
    expect(duty19.sections[1].entries[1].time, '20:15');
    expect(duty19.sections[1].entries[2].location, 'Grange Castle');
    expect(duty19.sections[1].entries[2].time, '21:30');
    expect(duty19.sections[1].entries[3].location, 'Mountjoy Square');
    expect(duty19.sections[1].entries[4].action, 'SPL');
    expect(duty19.sections[1].entries[4].location, 'Grange Castle');
    expect(duty19.sections[1].entries[4].time, '00:10');
    expect(duty19.sections[1].entries.last.time, '00:50');

    final duty23 = await ZoneBoardService.getBoardForDuty(
      dutyTitle: 'PZ2/23',
      date: sunday,
    );
    expect(duty23!.sections[1].entries[1].location, 'Mountjoy Square');
    expect(duty23.sections[1].entries[1].time, '20:30');
    expect(duty23.sections[1].entries[2].location, 'Grange Castle');
    expect(duty23.sections[1].entries[2].time, '21:45');
    expect(duty23.sections[1].entries[3].location, 'Mountjoy Square');
    expect(duty23.sections[1].entries[3].time, '23:15');
    expect(duty23.sections[1].entries[4].action, 'SPL');
    expect(duty23.sections[1].entries[4].location, 'Grange Castle');
    expect(duty23.sections[1].entries[4].time, '00:25');

    final duty17 = await ZoneBoardService.getBoardForDuty(
      dutyTitle: 'PZ2/17',
      date: sunday,
    );
    expect(duty17!.sections[0].entries[3].time, '18:28');
    expect(duty17.sections[1].entries[1].location, 'Mountjoy Square');
    expect(duty17.sections[1].entries[1].time, '19:30');
    expect(duty17.sections[1].entries[4].action, 'SPL');
    expect(duty17.sections[1].entries[4].location, 'Grange Castle');
    expect(duty17.sections[1].entries[4].time, '23:37');
    expect(duty17.sections[1].entries.last.time, '00:17');

    final duty1x = await ZoneBoardService.getBoardForDuty(
      dutyTitle: 'PZ2/1X',
      date: sunday,
    );
    expect(duty1x!.duty, '251');
    expect(duty1x.sections[0].entries[3].time, '13:40');
    expect(duty1x.sections[1].entries[1].action, 'Route');
    expect(duty1x.sections[1].entries[1].location, 'Mountjoy Square');
    expect(duty1x.sections[1].entries[1].time, '14:45');
    expect(duty1x.sections[1].entries[2].action, 'SPL');
    expect(duty1x.sections[1].entries[2].time, '16:20');
    expect(duty1x.sections[1].entries.last.time, '17:10');
  });

  test('loads PZ2/01 Saturday board from the Saturday sheet', () async {
    final board = await ZoneBoardService.getBoardForDuty(
      dutyTitle: 'PZ2/01',
      date: DateTime(2026, 10, 10), // Saturday
    );

    expect(board, isNotNull);
    expect(board!.shift, 'PZ2/01');
    expect(board.duty, '201');
    final entries = board.sections.first.entries;
    expect(entries.first.action, 'Report');
    expect(entries.first.time, '05:22');
    expect(entries[1].action, 'Depart Garage');
    expect(entries[1].time, '05:30');
    expect(entries[2].location, 'Grange Castle');
    expect(entries[2].time, '06:10');
    expect(entries[3].location, 'Mountjoy Square');
    expect(entries[3].time, '07:30');
    expect(entries[4].location, 'Grange Castle');
    expect(entries[4].time, '08:45');
    expect(entries[5].action, 'Arrive');
    expect(entries[5].location, 'Mountjoy Square');
    expect(entries[5].time, '10:15');
    expect(entries[5].route, isNull);
    expect(entries.last.action, 'Finish');
    expect(entries.last.time, '10:31');
  });

  test('loads PZ2/03 Saturday workout Mountjoy-first', () async {
    final board = await ZoneBoardService.getBoardForDuty(
      dutyTitle: 'PZ2/03',
      date: DateTime(2026, 10, 10),
    );

    expect(board, isNotNull);
    final entries = board!.sections.first.entries;
    expect(entries[1].action, 'Depart Garage');
    expect(entries[1].time, '06:00');
    expect(entries[2].location, 'Mountjoy Square');
    expect(entries[2].time, '06:10');
    expect(entries[3].location, 'Grange Castle');
    expect(entries[3].time, '07:30');
    expect(entries.last.time, '11:46');
  });

  test('loads PZ2/02 Saturday garage-meal board', () async {
    final board = await ZoneBoardService.getBoardForDuty(
      dutyTitle: 'PZ2/02',
      date: DateTime(2026, 10, 10),
    );

    expect(board, isNotNull);
    expect(board!.sections, hasLength(2));
    expect(board.sections[0].entries[3].action, 'SPL');
    expect(board.sections[0].entries[3].location, 'Mountjoy Square');
    expect(board.sections[0].entries[3].time, '07:55');
    expect(board.sections[0].entries.last.action, 'Break');
    expect(board.sections[0].entries.last.time, '08:10');
    expect(board.sections[0].entries.last.location, 'Garage');
    expect(
      board.sections[1].entries.first.action,
      'Takes up at 09:45 Garage',
    );
    expect(board.sections[1].entries[1].action, 'Depart Garage');
    expect(board.sections[1].entries[1].time, '09:45');
    expect(board.sections[1].entries[2].location, 'Mountjoy Square');
    expect(board.sections[1].entries[2].time, '10:00');
    expect(board.sections[1].entries.last.time, '13:16');
  });

  test('loads every Saturday Zone 2 duty board from the Saturday sheet',
      () async {
    final saturday = DateTime(2026, 10, 10);
    const codes = [
      'PZ2/01', 'PZ2/02', 'PZ2/03', 'PZ2/04', 'PZ2/05', 'PZ2/06', 'PZ2/07',
      'PZ2/08', 'PZ2/09', 'PZ2/10', 'PZ2/11', 'PZ2/12', 'PZ2/13', 'PZ2/14',
      'PZ2/15', 'PZ2/16', 'PZ2/17', 'PZ2/18', 'PZ2/19', 'PZ2/20', 'PZ2/21',
      'PZ2/22', 'PZ2/23', 'PZ2/24', 'PZ2/25', 'PZ2/26', 'PZ2/27', 'PZ2/28',
      'PZ2/29', 'PZ2/30',
      'PZ2/1X', 'PZ2/2X', 'PZ2/3X', 'PZ2/4X',
    ];

    for (final code in codes) {
      final board = await ZoneBoardService.getBoardForDuty(
        dutyTitle: code,
        date: saturday,
      );
      expect(board, isNotNull, reason: code);
      expect(board!.shift, code);
      expect(board.sections, isNotEmpty);
      expect(board.sections.last.entries.last.action, 'Finish');
    }

    final listed = await ZoneBoardService.listDutyCodes(
      zoneNumber: '2',
      dayKey: 'SAT',
      date: saturday,
    );
    expect(listed, unorderedEquals(codes));
  });

  test('loads later Saturday meal boards from the Saturday sheet', () async {
    final saturday = DateTime(2026, 10, 10);

    final duty11 = await ZoneBoardService.getBoardForDuty(
      dutyTitle: 'PZ2/11',
      date: saturday,
    );
    expect(duty11!.sections, hasLength(2));
    expect(duty11.sections[0].entries.first.time, '08:37');
    expect(duty11.sections[0].entries[4].action, 'Arrive');
    expect(duty11.sections[0].entries[4].time, '11:58');
    expect(duty11.sections[1].entries.first.action,
        'Takes up at 13:45 Mountjoy Square');
    expect(duty11.sections[1].entries[1].action, 'Route');
    expect(duty11.sections[1].entries[1].location, 'Mountjoy Square');
    expect(duty11.sections[1].entries[1].time, '13:45');
    expect(duty11.sections[1].entries[2].action, 'SPL');
    expect(duty11.sections[1].entries[2].location, 'Grange Castle');
    expect(duty11.sections[1].entries[2].time, '15:20');
    expect(duty11.sections[1].entries.last.time, '16:05');

    final duty19 = await ZoneBoardService.getBoardForDuty(
      dutyTitle: 'PZ2/19',
      date: saturday,
    );
    expect(duty19!.sections[1].entries[1].location, 'Mountjoy Square');
    expect(duty19.sections[1].entries[1].time, '19:15');
    expect(duty19.sections[1].entries[2].location, 'Grange Castle');
    expect(duty19.sections[1].entries[2].time, '20:45');
    expect(duty19.sections[1].entries[3].location, 'Mountjoy Square');
    expect(duty19.sections[1].entries[3].time, '22:00');
    expect(duty19.sections[1].entries[4].action, 'SPL');
    expect(duty19.sections[1].entries[4].location, 'Grange Castle');
    expect(duty19.sections[1].entries[4].time, '23:20');
    expect(duty19.sections[1].entries.last.time, '00:05');

    final duty27 = await ZoneBoardService.getBoardForDuty(
      dutyTitle: 'PZ2/27',
      date: saturday,
    );
    expect(duty27!.sections[1].entries.first.action,
        'Takes up at 20:45 Garage');
    expect(duty27.sections[1].entries[1].action, 'Depart Garage');
    expect(duty27.sections[1].entries[4].action, 'SPL');
    expect(duty27.sections[1].entries[4].location, 'Grange Castle');
    expect(duty27.sections[1].entries[4].time, '00:00');
    expect(duty27.sections[1].entries.last.time, '00:45');

    final duty2x = await ZoneBoardService.getBoardForDuty(
      dutyTitle: 'PZ2/2X',
      date: saturday,
    );
    expect(duty2x!.duty, '252');
    expect(duty2x.sections[1].entries[1].location, 'Mountjoy Square');
    expect(duty2x.sections[1].entries[1].time, '14:00');
    expect(duty2x.sections[1].entries[2].location, 'Grange Castle');
    expect(duty2x.sections[1].entries[2].time, '15:30');
    expect(duty2x.sections[1].entries[3].action, 'SPL');
    expect(duty2x.sections[1].entries[3].location, 'Mountjoy Square');
    expect(duty2x.sections[1].entries[3].time, '17:05');
    expect(duty2x.sections[1].entries.last.time, '17:20');
  });

  test('loads every Monday-Friday Zone 2 duty board from the weekday sheet',
      () async {
    final monday = DateTime(2026, 8, 10);
    const codes = [
      'PZ2/01', 'PZ2/02', 'PZ2/03', 'PZ2/04', 'PZ2/05', 'PZ2/06', 'PZ2/07',
      'PZ2/08', 'PZ2/09', 'PZ2/10', 'PZ2/11', 'PZ2/12', 'PZ2/13', 'PZ2/14',
      'PZ2/15', 'PZ2/16', 'PZ2/17', 'PZ2/18', 'PZ2/19', 'PZ2/20', 'PZ2/21',
      'PZ2/22', 'PZ2/23', 'PZ2/24', 'PZ2/25', 'PZ2/26', 'PZ2/27', 'PZ2/28',
      'PZ2/29', 'PZ2/30', 'PZ2/31', 'PZ2/32', 'PZ2/33', 'PZ2/34',
      'PZ2/1X', 'PZ2/2X', 'PZ2/3X', 'PZ2/4X', 'PZ2/5X', 'PZ2/6X', 'PZ2/7X',
      'PZ2/8X', 'PZ2/9X',
    ];

    for (final code in codes) {
      final board = await ZoneBoardService.getBoardForDuty(
        dutyTitle: code,
        date: monday,
      );
      expect(board, isNotNull, reason: code);
      expect(board!.shift, code);
      expect(board.sections, isNotEmpty);
      expect(board.sections.last.entries.last.action, 'Finish');
    }

    final listed = await ZoneBoardService.listDutyCodes(
      zoneNumber: '2',
      dayKey: 'MON-FRI',
      date: monday,
    );
    expect(listed, unorderedEquals(codes));
  });

  test('loads weekday garage-meal and late workout boards', () async {
    final monday = DateTime(2026, 8, 10);

    final duty05 = await ZoneBoardService.getBoardForDuty(
      dutyTitle: 'PZ2/05',
      date: monday,
    );
    expect(duty05!.sections[0].entries[4].action, 'Arrive');
    expect(duty05.sections[0].entries[4].time, '09:38');
    expect(duty05.sections[0].entries.last.action, 'Break');
    expect(duty05.sections[0].entries.last.time, '09:43');
    expect(duty05.sections[0].entries.last.location, 'Mountjoy Square');
    expect(duty05.sections[1].entries.first.action,
        'Takes up at 10:42 Mountjoy Square');
    expect(duty05.sections[1].entries[1].action, 'Route');
    expect(duty05.sections[1].entries[1].route, '13');
    expect(duty05.sections[1].entries[1].location, 'Mountjoy Square');
    expect(duty05.sections[1].entries[1].time, '10:42');
    expect(duty05.sections[1].entries[2].action, 'SPL');
    expect(duty05.sections[1].entries[2].location, 'Grange Castle');
    expect(duty05.sections[1].entries[2].time, '12:22');
    expect(duty05.sections[1].entries.last.time, '13:02');

    final duty28 = await ZoneBoardService.getBoardForDuty(
      dutyTitle: 'PZ2/28',
      date: monday,
    );
    expect(duty28!.sections[0].entries[3].action, 'SPL');
    expect(duty28.sections[0].entries[3].location, 'Mountjoy Square');
    expect(duty28.sections[0].entries[3].time, '19:35');
    expect(duty28.sections[1].entries.first.action, 'Takes up at 21:00 Garage');
    expect(duty28.sections[1].entries[1].action, 'Depart Garage');
    expect(duty28.sections[1].entries.last.time, '00:15');

    final duty1x = await ZoneBoardService.getBoardForDuty(
      dutyTitle: 'PZ2/1X',
      date: monday,
    );
    expect(duty1x!.duty, '251');
    expect(duty1x.sections[1].entries.first.action, 'Takes up at 12:57 Garage');
    expect(duty1x.sections[1].entries[1].action, 'Depart Garage');
    expect(duty1x.sections[1].entries[2].location, 'Grange Castle');
    expect(duty1x.sections[1].entries[2].time, '13:42');
    expect(duty1x.sections[1].entries.last.time, '15:46');

    final duty32 = await ZoneBoardService.getBoardForDuty(
      dutyTitle: 'PZ2/32',
      date: monday,
    );
    expect(duty32!.sections, hasLength(1));
    expect(duty32.sections.first.entries[1].location, 'Mountjoy Square');
    expect(duty32.sections.first.entries[1].time, '19:15');
    expect(duty32.sections.first.entries[5].action, 'SPL');
    expect(duty32.sections.first.entries[5].time, '00:20');
    expect(duty32.sections.first.entries.last.time, '00:30');
  });

  test('Zone 2 take-up at a terminus is followed by a leave from there',
      () async {
    final days = {
      'MON-FRI': DateTime(2026, 8, 10),
      'SAT': DateTime(2026, 10, 10),
      'SUN': DateTime(2026, 10, 4),
    };

    for (final entry in days.entries) {
      final dayKey = entry.key;
      final date = entry.value;
      final codes = await ZoneBoardService.listDutyCodes(
        zoneNumber: '2',
        dayKey: dayKey,
        date: date,
      );
      for (final code in codes) {
        final board = await ZoneBoardService.getBoardForDuty(
          dutyTitle: code,
          date: date,
          dayKey: dayKey,
        );
        expect(board, isNotNull, reason: '$code $dayKey');
        for (final section in board!.sections) {
          final rows = section.entries;
          for (var i = 0; i < rows.length; i++) {
            final action = rows[i].action;
            if (!action.startsWith('Takes up at ')) continue;
            expect(i + 1 < rows.length, isTrue, reason: '$code $dayKey $action');
            final next = rows[i + 1];
            if (action.contains('Garage')) {
              expect(next.action, 'Depart Garage',
                  reason: '$code $dayKey $action');
              continue;
            }
            final match = RegExp(
              r'Takes up at (\d{2}:\d{2}) (Mountjoy Square|Grange Castle)',
            ).firstMatch(action);
            expect(match, isNotNull, reason: '$code $dayKey $action');
            expect(next.action, 'Route', reason: '$code $dayKey $action');
            expect(next.route, '13', reason: '$code $dayKey $action');
            expect(next.location, match!.group(2),
                reason: '$code $dayKey $action');
            expect(next.time, match.group(1), reason: '$code $dayKey $action');
          }
        }
      }
    }
  });

  test('Zone 2 meal boards end the first half with Break', () async {
    final days = {
      'MON-FRI': DateTime(2026, 8, 10),
      'SAT': DateTime(2026, 10, 10),
      'SUN': DateTime(2026, 10, 4),
    };

    for (final entry in days.entries) {
      final dayKey = entry.key;
      final date = entry.value;
      final codes = await ZoneBoardService.listDutyCodes(
        zoneNumber: '2',
        dayKey: dayKey,
        date: date,
      );
      for (final code in codes) {
        final board = await ZoneBoardService.getBoardForDuty(
          dutyTitle: code,
          date: date,
          dayKey: dayKey,
        );
        if (board == null || board.sections.length < 2) continue;
        expect(
          board.sections.first.entries.last.action,
          'Break',
          reason: '$code $dayKey',
        );
        expect(board.sections.first.entries.last.time, isNotNull,
            reason: '$code $dayKey');
      }
    }
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
