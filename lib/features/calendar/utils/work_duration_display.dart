/// Formats CSV work duration (`06:40:00`) or UNI-style labels (`06h 40m`) as `6h 40m`.
String? formatWorkDurationForDisplay(String? raw) {
  if (raw == null) return null;
  final s = raw.trim();
  if (s.isEmpty || s.toLowerCase() == 'nan') return null;

  if (s.contains(':')) {
    final parts = s.split(':');
    if (parts.length < 2) return s;
    final hours = int.tryParse(parts[0].trim());
    final minutes = int.tryParse(parts[1].trim());
    if (hours == null || minutes == null) return s;
    return '${hours}h ${minutes}m';
  }

  final hm = RegExp(r'^(\d+)\s*h\s*(\d+)\s*m$', caseSensitive: false).firstMatch(s);
  if (hm != null) {
    return '${int.parse(hm.group(1)!)}h ${int.parse(hm.group(2)!)}m';
  }

  return s;
}
