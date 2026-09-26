enum BusReportCategory {
  seat,
  heater,
  wipers,
  ramp,
  radio,
  destination,
  doors,
  other;

  String get label {
    switch (this) {
      case BusReportCategory.seat:
        return 'Seat';
      case BusReportCategory.heater:
        return 'Heater';
      case BusReportCategory.wipers:
        return 'Wipers';
      case BusReportCategory.ramp:
        return 'Ramp';
      case BusReportCategory.radio:
        return 'Radio';
      case BusReportCategory.destination:
        return 'Destination';
      case BusReportCategory.doors:
        return 'Doors';
      case BusReportCategory.other:
        return 'Other';
    }
  }

  static BusReportCategory? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final value in BusReportCategory.values) {
      if (value.name == raw || value.label.toLowerCase() == raw.toLowerCase()) {
        return value;
      }
    }
    return null;
  }
}

enum BusReportSlot {
  first,
  second,
  full;

  String get id {
    switch (this) {
      case BusReportSlot.first:
        return '1';
      case BusReportSlot.second:
        return '2';
      case BusReportSlot.full:
        return 'full';
    }
  }

  String get label {
    switch (this) {
      case BusReportSlot.first:
        return '1st half';
      case BusReportSlot.second:
        return '2nd half';
      case BusReportSlot.full:
        return 'Duty';
    }
  }

  static BusReportSlot tryParse(String? raw) {
    switch (raw) {
      case '1':
      case 'first':
        return BusReportSlot.first;
      case '2':
      case 'second':
        return BusReportSlot.second;
      default:
        return BusReportSlot.full;
    }
  }

  static BusReportSlot forDutyCode(String raw) {
    final code = raw.trim().toUpperCase().replaceAll(RegExp(r'\s*\(OT\)\s*$'), '');
    if (code.endsWith('XA') || (code.endsWith('A') && !code.endsWith('X'))) {
      return BusReportSlot.first;
    }
    if (code.endsWith('XB') || code.endsWith('B')) {
      return BusReportSlot.second;
    }
    return BusReportSlot.full;
  }
}

class BusReportTarget {
  const BusReportTarget({
    required this.busNumber,
    required this.date,
    required this.slot,
  });

  final String busNumber;
  final String date;
  final BusReportSlot slot;

  String get summaryId => busNumber;

  String reportDocId(String userId) =>
      '${userId}_${busNumber}_${date}_${slot.id}';
}

class BusReportKey {
  BusReportKey._();

  static const recentReportDays = 7;
  static const minLength = 3;
  static const maxLength = 10;

  static String? normalizeBusNumber(String raw) {
    final cleaned = raw.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (!isValid(cleaned)) return null;
    return cleaned;
  }

  static bool isValid(String busNumber) {
    if (busNumber.length < minLength || busNumber.length > maxLength) {
      return false;
    }
    final hasLetter = RegExp(r'[A-Z]').hasMatch(busNumber);
    final hasDigit = RegExp(r'[0-9]').hasMatch(busNumber);
    return hasLetter && hasDigit;
  }

  static bool isRecent(DateTime? lastReportedAt, {DateTime? now}) {
    if (lastReportedAt == null) return false;
    final current = now ?? DateTime.now();
    return lastReportedAt.isAfter(
      current.subtract(const Duration(days: recentReportDays)),
    );
  }

  static bool canShowWriteAction({required bool settingsEnabled}) {
    return settingsEnabled;
  }

  static bool canSave({BusReportCategory? category, required String note}) {
    return category != null || note.trim().isNotEmpty;
  }

  static String formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static BusReportTarget? targetFor({
    required String rawBusNumber,
    required DateTime date,
    required BusReportSlot slot,
  }) {
    final busNumber = normalizeBusNumber(rawBusNumber);
    if (busNumber == null) return null;
    return BusReportTarget(
      busNumber: busNumber,
      date: formatDate(date),
      slot: slot,
    );
  }
}
