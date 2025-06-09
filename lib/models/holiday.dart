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
    return date.isAfter(startDate.subtract(const Duration(days: 1))) && 
           date.isBefore(endDate.add(const Duration(days: 1)));
  }
} 
