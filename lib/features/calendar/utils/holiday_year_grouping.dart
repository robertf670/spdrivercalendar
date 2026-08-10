import 'package:spdrivercalendar/models/holiday.dart';

/// Groups holidays by start year, newest years first, dates ascending within year.
Map<int, List<Holiday>> groupHolidaysByYear(Iterable<Holiday> holidays) {
  final holidaysByYear = <int, List<Holiday>>{};
  for (final holiday in holidays) {
    final year = holiday.startDate.year;
    holidaysByYear.putIfAbsent(year, () => []).add(holiday);
  }

  final sortedYears = holidaysByYear.keys.toList()..sort((a, b) => b.compareTo(a));
  final ordered = <int, List<Holiday>>{};
  for (final year in sortedYears) {
    final yearHolidays = List<Holiday>.from(holidaysByYear[year]!)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    ordered[year] = yearHolidays;
  }
  return ordered;
}
