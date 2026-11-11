import 'package:spdrivercalendar/features/calendar/services/zone2_duties.dart';

/// Which duties CSV a spare assignment should read, and which shift codes
/// in that file count as the same duty.
class SpareDutyBill {
  SpareDutyBill._();

  static ({String zone, Set<String> codes}) resolve(String codeWithoutHalf) {
    if (Zone2Duties.isRoute13Code(codeWithoutHalf)) {
      return (
        zone: Zone2Duties.zoneNumber,
        codes: Zone2Duties.aliases(codeWithoutHalf).toSet(),
      );
    }

    var zone = '1';
    final codes = <String>{codeWithoutHalf};
    final pzMatch = RegExp(r'^PZ(\d+)/').firstMatch(codeWithoutHalf);
    if (pzMatch != null) {
      zone = pzMatch.group(1) ?? '1';
      codes.add(codeWithoutHalf.substring(pzMatch.end));
    } else {
      final zoneMatch = RegExp(r'^(\d+)').firstMatch(codeWithoutHalf);
      final digits = zoneMatch?.group(1);
      if (digits != null && digits.isNotEmpty) {
        final firstDigit = digits.substring(0, 1);
        zone = firstDigit == '1'
            ? '1'
            : firstDigit == '3'
                ? '3'
                : firstDigit == '4'
                    ? '4'
                    : '1';
      }
    }
    return (zone: zone, codes: codes);
  }
}
