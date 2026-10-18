/// Route 13 (formerly Zone 2) labels, duty codes, and file-zone mapping.
class Zone2Duties {
  Zone2Duties._();

  static const zoneLabel = 'Route 13';
  static const legacyZoneLabel = 'Zone 2';
  static const zoneNumber = '2';
  static const dutyPrefix = '13/';
  static const legacyDutyPrefix = 'PZ2/';

  /// First calendar day drivers can add Route 13 shifts.
  static final DateTime addShiftsFrom = DateTime(2026, 10, 10);

  static const availableFromMessage = 'Available from 10 Oct 2026';

  static bool canAddShiftsOn(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final from = DateTime(
      addShiftsFrom.year,
      addShiftsFrom.month,
      addShiftsFrom.day,
    );
    return !day.isBefore(from);
  }

  static bool isZone(String label) =>
      label == zoneLabel || label == legacyZoneLabel;

  /// Maps picker / marked-in / Bills labels onto CSV zone numbers.
  ///
  /// `Route 13` and saved `Zone 2` both become `2`. Other `Zone n` labels
  /// keep their number. Values already like `2` or `Uni/Euro` pass through.
  static String fileZoneNumber(String zone) {
    if (isZone(zone)) return zoneNumber;
    if (zone.startsWith('Zone ')) return zone.substring(5);
    return zone;
  }

  static String normalizeZoneLabel(String zone) {
    if (isZone(zone)) return zoneLabel;
    return zone;
  }

  static String _bare(String raw) {
    var code = raw.trim();
    if (code.toUpperCase().startsWith('UNI:')) {
      code = code.substring(4).trim();
    }
    code = code.replaceAll(RegExp(r'\s*\(OT\)\s*$'), '');
    return code;
  }

  static bool isRoute13Code(String raw) {
    final code = _bare(raw);
    final upper = code.toUpperCase();
    if (upper.startsWith('13/') || upper.startsWith('PZ2/')) {
      return true;
    }
    return RegExp(r'^2/\S+$').hasMatch(code);
  }

  /// Rewrites stored `PZ2/` text to `13/` and keeps halves / `(OT)`.
  static String rewriteStoredText(String raw) {
    return raw.replaceAll(RegExp(r'PZ2/', caseSensitive: false), dutyPrefix);
  }

  /// Stored / displayed form: `13/01`, `13/1X`, `13/01A`.
  static String canonical(String raw) {
    final code = _bare(raw);
    if (code.toUpperCase().startsWith('PZ2/')) {
      return '$dutyPrefix${code.substring(legacyDutyPrefix.length)}';
    }
    if (RegExp(r'^2/\S+$').hasMatch(code)) {
      return '$dutyPrefix${code.substring(2)}';
    }
    return code;
  }

  /// Canonical code plus the old `PZ2/` form for lookups.
  static List<String> aliases(String raw) {
    final canon = canonical(raw);
    if (!isRoute13Code(canon) && !canon.startsWith(dutyPrefix)) {
      return [raw.trim()];
    }
    final rest = canon.startsWith(dutyPrefix)
        ? canon.substring(dutyPrefix.length)
        : canon;
    return [
      '$dutyPrefix$rest',
      '$legacyDutyPrefix$rest',
    ];
  }

  static bool codesMatch(String a, String b) {
    if (a == b) return true;
    if (isRoute13Code(a) || isRoute13Code(b)) {
      return canonical(a) == canonical(b);
    }
    return false;
  }

  /// Uni/Euro like `307/01` / `807/90`. Route 13 `13/01` is not Uni.
  static bool isUniEuroCode(String raw) {
    final code = _bare(raw);
    if (isRoute13Code(code)) return false;
    return RegExp(r'^\d{2,3}/').hasMatch(code);
  }

  /// Zone number used to pick `*_DUTIES_PZ*.csv` from a duty code.
  static String csvZoneNumberForDuty(String shiftCode) {
    if (isRoute13Code(shiftCode)) return zoneNumber;
    final match = RegExp(r'PZ(\d+)/').firstMatch(_bare(shiftCode));
    return match?.group(1) ?? '1';
  }
}
