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
