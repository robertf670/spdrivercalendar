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

  test('returns null for unsupported zone', () async {
    final board = await ZoneBoardService.getBoardForDuty(
      dutyTitle: 'PZ2/01',
      date: DateTime(2026, 8, 10),
    );
    expect(board, isNull);
  });

  test('disables Zone 4 boards from 23 Aug 2026', () async {
    final before = await ZoneBoardService.getBoardForDuty(
      dutyTitle: 'PZ4/01',
      date: DateTime(2026, 8, 22),
    );
    final after = await ZoneBoardService.getBoardForDuty(
      dutyTitle: 'PZ4/01',
      date: DateTime(2026, 8, 23),
    );

    expect(before, isNotNull);
    expect(after, isNull);
  });
}
