/// Full Jamestown Road M–F roster (311 euros + 811 universals).
/// Separate from the Dev Menu 30hr [Jamestown] toggle.
class JamestownRoad {
  JamestownRoad._();

  static const zoneLabel = 'Jamestown Road (40hr)';
  static const legacyZoneLabel = 'Jamestown Road';
  static const dutiesCsvAsset = 'assets/JAMESTOWN_DUTIES.csv';

  static bool isZone(String zone) =>
      zone == zoneLabel || zone == legacyZoneLabel;

  static bool isShiftCode(String code) {
    final trimmed = code.trim();
    return trimmed.startsWith('311/') || trimmed.startsWith('811/');
  }

  /// Universals first, then euros, keeping each family's original order.
  static List<String> orderForPicker(Iterable<String> codes) {
    final universals = <String>[];
    final euros = <String>[];
    final rest = <String>[];
    for (final code in codes) {
      if (code.startsWith('811/')) {
        universals.add(code);
      } else if (code.startsWith('311/')) {
        euros.add(code);
      } else {
        rest.add(code);
      }
    }
    return [...universals, ...euros, ...rest];
  }
}
