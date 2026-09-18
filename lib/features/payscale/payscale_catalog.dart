class PayScaleRow {
  const PayScaleRow({
    required this.typeKey,
    required this.label,
    required this.section,
    required this.rates,
  });

  final String typeKey;
  final String label;
  final String section;
  final Map<String, double> rates;

  String formattedRate(String yearLevel) {
    final value = rates[yearLevel];
    if (value == null) return '—';
    return '€${value.toStringAsFixed(2)}';
  }
}

class PayScaleGroup {
  const PayScaleGroup({required this.title, required this.rows});

  final String title;
  final List<PayScaleRow> rows;
}

class PayScaleCatalog {
  const PayScaleCatalog(this.rows);

  final List<PayScaleRow> rows;

  static const paymentLabels = <String, String>{
    'basicdaily': 'Basic Daily Rate',
    'shiftdaily': 'Shift Premium',
    'weeklyexlsunday': 'Excl. Sunday',
    'weeklyinclsunday': 'Incl. Sunday',
    'workingrestday(mon-sat)': 'Mon-Sat',
    'workingrestday(sun)': 'Sunday',
    'bankholiday': 'Bank Holiday',
    'overtimeweekday(hourly)': 'Weekday',
    'overtimesunday(hourly)': 'Sunday',
    'overtimebankholiday(hourly)': 'Bank Holiday',
    'privatehireweekday(hourly)': 'Weekday',
    'privatehiresunday(hourly)': 'Sunday',
    'privatehirebankholiday(hourly)': 'Bank Holiday',
    'spreadover(hourly)': 'Hourly',
  };

  static const paymentSections = <String, String>{
    'basicdaily': 'Daily',
    'shiftdaily': 'Daily',
    'weeklyexlsunday': 'Weekly',
    'weeklyinclsunday': 'Weekly',
    'workingrestday(mon-sat)': 'Rest Days',
    'workingrestday(sun)': 'Rest Days',
    'bankholiday': 'Rest Days',
    'overtimeweekday(hourly)': 'Overtime',
    'overtimesunday(hourly)': 'Overtime',
    'overtimebankholiday(hourly)': 'Overtime',
    'privatehireweekday(hourly)': 'Private Hire',
    'privatehiresunday(hourly)': 'Private Hire',
    'privatehirebankholiday(hourly)': 'Private Hire',
    'spreadover(hourly)': 'Spread',
  };

  factory PayScaleCatalog.parse(String csv) {
    final lines = csv.split('\n');
    List<String>? headers;
    final rows = <PayScaleRow>[];

    for (final raw in lines) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      final parts = line
          .split(',')
          .map((part) => part.trim())
          .where((part) => part.isNotEmpty)
          .toList();
      if (parts.isEmpty) continue;

      if (headers == null) {
        headers = parts.map((h) => h.toLowerCase()).toList();
        continue;
      }

      final typeKey = parts.first.toLowerCase();
      final rates = <String, double>{};
      for (var i = 1; i < headers.length && i < parts.length; i++) {
        final value = double.tryParse(parts[i]);
        if (value != null) {
          rates[headers[i]] = value;
        }
      }
      rows.add(
        PayScaleRow(
          typeKey: typeKey,
          label: paymentLabels[typeKey] ?? parts.first,
          section: paymentSections[typeKey] ?? 'Other',
          rates: rates,
        ),
      );
    }

    return PayScaleCatalog(rows);
  }

  List<PayScaleGroup> grouped() {
    final groups = <PayScaleGroup>[];
    for (final row in rows) {
      if (groups.isEmpty || groups.last.title != row.section) {
        groups.add(PayScaleGroup(title: row.section, rows: [row]));
      } else {
        groups.last.rows.add(row);
      }
    }
    return groups;
  }
}
