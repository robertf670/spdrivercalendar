class TimingPointRoute {
  final String routeNumber;
  final List<String> direction1Points;
  final List<String> direction2Points;

  TimingPointRoute({
    required this.routeNumber,
    required this.direction1Points,
    required this.direction2Points,
  });

  // Get all timing points as a formatted string for search
  String get searchableText {
    final allPoints = [...direction1Points, ...direction2Points];
    return '$routeNumber ${allPoints.join(' ')}';
  }
} 