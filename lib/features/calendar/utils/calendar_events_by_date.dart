import 'package:spdrivercalendar/models/event.dart';

/// Converts EventService string day-keys into [DateTime]-keyed event lists.
Map<DateTime, List<Event>> mapEventsByDate(
  Map<String, List<Event>> eventsWithStringKeys,
) {
  final mapped = <DateTime, List<Event>>{};
  for (final entry in eventsWithStringKeys.entries) {
    mapped[DateTime.parse(entry.key)] = entry.value;
  }
  return mapped;
}
