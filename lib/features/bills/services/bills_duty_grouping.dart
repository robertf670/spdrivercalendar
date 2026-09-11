import 'package:spdrivercalendar/features/bills/models/bill_duty.dart';

class BillDutyGroup {
  const BillDutyGroup({
    required this.id,
    required this.label,
    required this.duties,
  });

  final String id;
  final String label;
  final List<BillDuty> duties;
}

/// Splits a bill into contiguous chunks so drivers can jump the list
/// the way they flip a paper bill (01–20, 21–40, X duties, nights).
class BillsDutyGrouping {
  BillsDutyGrouping._();

  static final _codePattern = RegExp(r'^(.*)/(\d+)([A-Za-z]*)$');

  /// Shared shift prefix (PZ1, PZ4, 307) when every duty uses the same one.
  static String? sharedPrefix(List<BillDuty> duties) {
    String? prefix;
    for (final duty in duties) {
      final match = _codePattern.firstMatch(duty.shift.trim());
      if (match == null) return null;
      final next = match.group(1)!;
      if (prefix == null) {
        prefix = next;
      } else if (prefix != next) {
        return null;
      }
    }
    return prefix;
  }

  static String sectionKey(String shift) {
    final match = _codePattern.firstMatch(shift.trim());
    if (match == null) return 'other:$shift';
    final suffix = match.group(3)!.toUpperCase();
    final number = int.tryParse(match.group(2)!) ?? 0;
    final start = number <= 0 ? 0 : ((number - 1) ~/ 20) * 20 + 1;
    if (suffix.isEmpty) return 'n-$start';
    return '${suffix.toLowerCase()}-$start';
  }

  static List<BillDutyGroup> group(List<BillDuty> duties) {
    if (duties.isEmpty) return const [];

    final groups = <BillDutyGroup>[];
    var bucket = <BillDuty>[];
    String? key;

    void flush() {
      if (bucket.isEmpty || key == null) return;
      final first = bucket.first.shortCode;
      final last = bucket.last.shortCode;
      groups.add(
        BillDutyGroup(
          id: '${groups.length}-$key',
          label: first == last ? first : '$first–$last',
          duties: List<BillDuty>.from(bucket),
        ),
      );
      bucket = [];
    }

    for (final duty in duties) {
      final nextKey = sectionKey(duty.shift);
      if (key != null && nextKey != key) {
        flush();
      }
      key = nextKey;
      bucket.add(duty);
    }
    flush();
    return groups;
  }
}
