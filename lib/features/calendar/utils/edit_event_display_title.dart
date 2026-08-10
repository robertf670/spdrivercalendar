/// Formats an event title for the Edit Event dialog header.
String formatEditEventDisplayTitle(String title) {
  if (title.startsWith('BusCheck')) {
    final match = RegExp(r'^BusCheck(\d+)$').firstMatch(title);
    final numberPart = match?.group(1);
    if (numberPart != null) {
      return 'Bus Check $numberPart';
    }
  }
  if (title.isEmpty) {
    return 'Untitled Event';
  }
  return title;
}
