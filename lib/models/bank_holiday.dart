import 'package:intl/intl.dart';

class BankHoliday {
  final String name;
  final DateTime date;
  final bool observed;
  final String notes;

  BankHoliday({
    required this.name,
    required this.date,
    this.observed = false,
    this.notes = '',
  });

  // Create from JSON method for deserialization
  factory BankHoliday.fromJson(Map<String, dynamic> json) {
    return BankHoliday(
      name: json['name'] ?? 'Unknown Holiday',
      date: _parseDate(json['date']),
      observed: json['observed'] ?? false,
      notes: json['notes'] ?? '',
    );
  }

  // Helper method to parse date string
  static DateTime _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) {
      return DateTime.now(); // Default to current date
    }
    
    try {
      // Try parsing ISO format (YYYY-MM-DD)
      return DateTime.parse(dateStr);
    } catch (e) {
      try {
        // Try alternate format (DD/MM/YYYY)
        final DateFormat formatter = DateFormat('dd/MM/yyyy');
        return formatter.parse(dateStr);
      } catch (e) {
        // If all parsing fails, return current date
        return DateTime.now();
      }
    }
  }

  // Method to check if a date matches this bank holiday
  bool matchesDate(DateTime other) {
    return date.year == other.year &&
           date.month == other.month &&
           date.day == other.day;
  }

  // Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'date': date.toIso8601String(),
      'observed': observed,
      'notes': notes,
    };
  }

  @override
  String toString() {
    return 'BankHoliday($name, $date, observed: $observed)';
  }
}
