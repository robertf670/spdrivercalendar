import 'package:spdrivercalendar/models/timing_point.dart';

/// Parses [assets/timingpoints.txt].
///
/// Lines are `route -> Destination, point, point`. The first value is the
/// destination; the rest are timing points. Optional `NOTE 13: ...` lines
/// attach a route-level note.
class TimingPointsParser {
  TimingPointsParser._();

  static final _notePattern = RegExp(r'^NOTE\s+(.+?):\s*(.+)$');

  static List<TimingPointRoute> parse(String data) {
    final routeMap = <String, List<List<String>>>{};
    final notes = <String, String>{};

    for (final raw in data.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty) continue;

      final noteMatch = _notePattern.firstMatch(line);
      if (noteMatch != null) {
        notes[noteMatch.group(1)!.trim()] = noteMatch.group(2)!.trim();
        continue;
      }

      if (!line.contains(' -> ')) continue;
      final parts = line.split(' -> ');
      if (parts.length != 2) continue;

      final routeNumber = parts[0].trim();
      final timingPoints =
          parts[1].split(',').map((point) => point.trim()).toList();
      routeMap.putIfAbsent(routeNumber, () => []).add(timingPoints);
    }

    final routes = [
      for (final entry in routeMap.entries)
        TimingPointRoute(
          routeNumber: entry.key,
          direction1Points:
              entry.value.isNotEmpty ? entry.value[0] : const <String>[],
          direction2Points:
              entry.value.length > 1 ? entry.value[1] : const <String>[],
          note: notes[entry.key],
        ),
    ];

    routes.sort((a, b) {
      const bottomRoutes = ['13', '23', '24'];
      final aAtBottom = bottomRoutes.contains(a.routeNumber);
      final bAtBottom = bottomRoutes.contains(b.routeNumber);
      if (aAtBottom && bAtBottom) {
        return a.routeNumber.compareTo(b.routeNumber);
      }
      if (aAtBottom) return 1;
      if (bAtBottom) return -1;
      return a.routeNumber.compareTo(b.routeNumber);
    });
    return routes;
  }

  static List<String> destinationsOf(TimingPointRoute route) {
    return [
      if (route.direction1Points.isNotEmpty) route.direction1Points.first,
      if (route.direction2Points.isNotEmpty) route.direction2Points.first,
    ];
  }

  static List<String> pointsForDestination(
    TimingPointRoute route,
    String destination,
  ) {
    if (route.direction1Points.isNotEmpty &&
        destination == route.direction1Points.first) {
      return route.direction1Points.length > 1
          ? route.direction1Points.sublist(1)
          : const [];
    }
    if (route.direction2Points.isNotEmpty &&
        destination == route.direction2Points.first) {
      return route.direction2Points.length > 1
          ? route.direction2Points.sublist(1)
          : const [];
    }
    return const [];
  }
}
