import 'package:spdrivercalendar/models/event.dart';

/// Pure spare-duty helpers used by the calendar edit flow.
class SpareShiftDuties {
  SpareShiftDuties._();

  /// True when a spare shift contains at least one full duty and should use
  /// firstHalfBus/secondHalfBus style editing rather than half-only spare UI.
  static bool hasFullDuties(Event event) {
    final isSpareLike =
        event.title.startsWith('SP') || event.title == '22B/01';
    if (!isSpareLike ||
        event.assignedDuties == null ||
        event.assignedDuties!.isEmpty) {
      return false;
    }

    for (final duty in event.assignedDuties!) {
      final dutyCode = duty.startsWith('UNI:') ? duty.substring(4) : duty;
      if (!dutyCode.endsWith('A') && !dutyCode.endsWith('B')) {
        return true;
      }
    }
    return false;
  }
}
