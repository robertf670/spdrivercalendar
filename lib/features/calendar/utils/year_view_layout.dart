// Layout helpers for Year View: column count, tile size, scroll target, load order.

int yearViewCrossAxisCount(double width) {
  if (width > 900) return 4;
  if (width < 600) return 2;
  return 3;
}

double yearViewTileAspectRatio({
  required double width,
  required double textScale,
}) {
  final isSmall = width < 600;
  final isLarge = width > 900;
  final baseAspect = isSmall ? 0.92 : (isLarge ? 0.98 : 0.95);
  return (baseAspect / textScale.clamp(1.0, 3.0)).clamp(0.42, 1.05);
}

double yearViewGridPadding(double width) {
  if (width < 600) return 6;
  if (width > 900) return 12;
  return 8;
}

double yearViewGridSpacing(double width) {
  return yearViewGridPadding(width);
}

/// Month (1–12) to bring into view. Other years open on January.
int yearViewScrollTargetMonth({
  required int displayedYear,
  required DateTime now,
  int? focusedMonth,
}) {
  if (displayedYear != now.year) return 1;
  final month = focusedMonth ?? now.month;
  if (month < 1 || month > 12) return now.month;
  return month;
}

/// [prioritizeMonth] is cached first so the visible month fills in before January.
List<int> yearViewMonthLoadOrder(int prioritizeMonth) {
  final first = prioritizeMonth.clamp(1, 12);
  return [
    first,
    for (var month = 1; month <= 12; month++)
      if (month != first) month,
  ];
}

/// Scroll offset that puts [month]'s row at the top of the grid viewport.
double yearViewMonthScrollOffset({
  required int month,
  required int crossAxisCount,
  required double viewportWidth,
  required double padding,
  required double spacing,
  required double aspectRatio,
}) {
  final row = (month.clamp(1, 12) - 1) ~/ crossAxisCount;
  if (row == 0) return 0;
  final innerWidth = (viewportWidth - padding * 2).clamp(1.0, double.infinity);
  final tileWidth =
      (innerWidth - spacing * (crossAxisCount - 1)) / crossAxisCount;
  final tileHeight = tileWidth / aspectRatio;
  return padding + row * (tileHeight + spacing);
}
