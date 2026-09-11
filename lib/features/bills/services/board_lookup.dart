import 'package:spdrivercalendar/features/calendar/utils/zone_board_mapper.dart';
import 'package:spdrivercalendar/models/universal_board.dart';
import 'package:spdrivercalendar/services/universal_board_service.dart';
import 'package:spdrivercalendar/services/zone_board_service.dart';

/// Resolves running boards for the Bills & Boards browser.
class BoardLookup {
  BoardLookup._();

  static Future<Set<String>> dutyCodesFor({
    required String zone,
    required String dayType,
    required DateTime date,
  }) async {
    if (zone == 'Zone 2') return {};
    if (zone == 'Uni/Euro') {
      final boards = await UniversalBoardService.loadBoards();
      return boards.map((board) => board.shift).toSet();
    }

    final zoneNumber = zone.replaceAll('Zone ', '');
    if (!['1', '3', '4'].contains(zoneNumber)) return {};

    final codes = await ZoneBoardService.listDutyCodes(
      zoneNumber: zoneNumber,
      dayKey: ZoneBoardMapper.dayKeyForBrowseType(dayType),
      date: date,
    );
    return codes.toSet();
  }

  static Future<UniversalBoard?> load({
    required String shift,
    required String dayType,
    required DateTime date,
  }) async {
    if (shift.startsWith('PZ') || shift.startsWith('811/')) {
      return ZoneBoardService.getBoardForDuty(
        dutyTitle: shift,
        date: date,
        dayKey: ZoneBoardMapper.dayKeyForBrowseType(dayType),
      );
    }
    return UniversalBoardService.getBoardByShift(shift);
  }
}
