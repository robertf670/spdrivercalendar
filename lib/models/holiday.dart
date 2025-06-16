class Holiday {
  final String id;
  final DateTime startDate;
  final DateTime endDate;
  final String type; // 'winter', 'summer', or 'other'

  Holiday({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.type,
  });

  // Convert Holiday to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'type': type,
    };
  }

  // Create Holiday from JSON
  factory Holiday.fromJson(Map<String, dynamic> json) {
    return Holiday(
      id: json['id'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      type: json['type'],
    );
  }

  // Check if a date falls within this holiday period
  bool containsDate(DateTime date) {
    // Normalize dates to midnight to avoid time component issues
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final normalizedStart = DateTime(startDate.year, startDate.month, startDate.day);
    final normalizedEnd = DateTime(endDate.year, endDate.month, endDate.day);
    
    // Check if the date falls within the holiday range (inclusive)
    return !normalizedDate.isBefore(normalizedStart) && !normalizedDate.isAfter(normalizedEnd);
  }
} 
