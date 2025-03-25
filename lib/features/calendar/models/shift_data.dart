class ShiftData {
  final String shift;
  final String duty;
  final String report;
  final String depart;
  final String location;
  final String startBreak;
  final String startBreakLocation;
  final String breakReport;
  final String finishBreak;
  final String finishBreakLocation;
  final String finish;
  final String finishLocation;
  final String signOff;
  final String spread;
  final String work;
  final String relief;

  const ShiftData({
    required this.shift,
    required this.duty,
    required this.report,
    required this.depart,
    required this.location,
    required this.startBreak,
    required this.startBreakLocation,
    required this.breakReport,
    required this.finishBreak,
    required this.finishBreakLocation,
    required this.finish,
    required this.finishLocation,
    required this.signOff,
    required this.spread,
    required this.work,
    required this.relief,
  });

  factory ShiftData.fromList(List<String> parts) {
    if (parts.length < 16) {
      throw ArgumentError('ShiftData requires at least 16 parts');
    }

    return ShiftData(
      shift: parts[0].trim(),
      duty: parts[1].trim(),
      report: parts[2].trim(),
      depart: parts[3].trim(),
      location: parts[4].trim(),
      startBreak: parts[5].trim(),
      startBreakLocation: parts[6].trim(),
      breakReport: parts[7].trim(),
      finishBreak: parts[8].trim(),
      finishBreakLocation: parts[9].trim(),
      finish: parts[10].trim(),
      finishLocation: parts[11].trim(),
      signOff: parts[12].trim(),
      spread: parts[13].trim(),
      work: parts[14].trim(),
      relief: parts[15].trim(),
    );
  }

  @override
  String toString() {
    return 'Shift: $shift\n'
           'Duty: $duty\n'
           'Report: $report at $location\n'
           'Depart: $depart\n'
           'Break: $startBreak - $finishBreak at $startBreakLocation\n'
           'Finish: $finish at $finishLocation\n'
           'Sign-off: $signOff\n'
           'Spread: $spread\n'
           'Work: $work\n'
           'Relief: $relief';
  }
} 