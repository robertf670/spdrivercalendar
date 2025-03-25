class BoardEntry {
  final String duty;
  final String? reports;
  final String? departs;
  final String location;
  final String route;
  final String? from;
  final String? to;
  final String? arrival;
  final String? departure;
  final String? notes;

  BoardEntry({
    required this.duty,
    this.reports,
    this.departs,
    required this.location,
    required this.route,
    this.from,
    this.to,
    this.arrival,
    this.departure,
    this.notes,
  });

  factory BoardEntry.fromCsvRow(List<dynamic> row) {
    return BoardEntry(
      duty: row[0].toString(),
      reports: row[1]?.toString(),
      departs: row[2]?.toString(),
      location: row[3].toString(),
      route: row[4].toString(),
      from: row[5]?.toString(),
      to: row[6]?.toString(),
      arrival: row[7]?.toString(),
      departure: row[8]?.toString(),
      notes: row[9]?.toString(),
    );
  }
} 