class BankHoliday {
  final String name;
  final DateTime date;

  const BankHoliday({
    required this.name,
    required this.date,
  });

  bool matchesDate(DateTime other) {
    return date.year == other.year &&
           date.month == other.month &&
           date.day == other.day;
  }

  @override
  String toString() {
    return '$name on ${date.toString().split(' ')[0]}';
  }
} 