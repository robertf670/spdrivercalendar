import 'package:spdrivercalendar/features/calendar/utils/zone_board_mapper.dart';
import 'package:spdrivercalendar/models/event.dart';
import 'package:spdrivercalendar/models/universal_board.dart';
import 'package:spdrivercalendar/services/universal_board_service.dart';
import 'package:spdrivercalendar/services/zone_board_service.dart';

/// Resolves running boards for spare/22B assigned duties.
class AssignedDutyBoardLookup {
  AssignedDutyBoardLookup._();

  /// Cleans `UNI:807/06A`, `PZ1/03A`, `4/07` → board keys.
  static String lookupCode(String raw) {
    var code = raw.trim();
    if (code.toUpperCase().startsWith('UNI:')) {
      code = code.substring(4).trim();
    }
    code = code.replaceAll(RegExp(r'\s*\(OT\)\s*$'), '');

    if (RegExp(r'^[134]/').hasMatch(code)) {
      code = 'PZ$code';
    }

    final normalized = ZoneBoardMapper.normalizeDutyCode(code);
    if (normalized != null) {
      return normalized;
    }

    final uniHalf = RegExp(r'^(\d+/\d+)[AB]$').firstMatch(code);
    if (uniHalf != null) {
      return uniHalf.group(1)!;
    }

    return code;
  }

  static Future<UniversalBoard?> load({
    required String assignedDuty,
    required DateTime date,
  }) async {
    final code = lookupCode(assignedDuty);
    if (code.isEmpty) return null;

    final zoneBoard = await ZoneBoardService.getBoardForDuty(
      dutyTitle: code,
      date: date,
    );
    if (zoneBoard != null && zoneBoard.sections.isNotEmpty) {
      return zoneBoard;
    }

    final uniBoard = await UniversalBoardService.getBoardByShift(code);
    if (uniBoard != null && uniBoard.sections.isNotEmpty) {
      return uniBoard;
    }
    return null;
  }

  /// Title first (normal PZ/Uni events), then each assigned spare duty.
  static Future<UniversalBoard?> loadForEvent(Event event) async {
    final fromTitle = await ZoneBoardService.getBoardForDuty(
      dutyTitle: event.title,
      date: event.startDate,
    );
    if (fromTitle != null && fromTitle.sections.isNotEmpty) {
      return fromTitle;
    }

    final uniFromTitle = await UniversalBoardService.getBoardByShift(event.title);
    if (uniFromTitle != null && uniFromTitle.sections.isNotEmpty) {
      return uniFromTitle;
    }

    for (final duty in event.assignedDuties ?? const <String>[]) {
      final board = await load(assignedDuty: duty, date: event.startDate);
      if (board != null) {
        return board;
      }
    }
    return null;
  }
}
