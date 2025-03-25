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

  ShiftData({
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

  factory ShiftData.fromList(List<String> data) {
    // Calculate relief as spread minus work
    String calculatedRelief = "";
    
    if (data.length >= 15) {
      try {
        final spreadTime = _parseTimeToMinutes(data[13]);
        final workTime = _parseTimeToMinutes(data[14]);
        
        if (spreadTime != null && workTime != null) {
          final reliefMinutes = spreadTime - workTime;
          final reliefHours = reliefMinutes ~/ 60;
          final reliefMins = reliefMinutes % 60;
          calculatedRelief = '${reliefHours.toString().padLeft(2, '0')}:${reliefMins.toString().padLeft(2, '0')}:00';
        }
      } catch (e) {
        print('Error calculating relief: $e');
      }
    }
    
    return ShiftData(
      shift: data[0],
      duty: data[1],
      report: data[2],
      depart: data[3],
      location: data[4],
      startBreak: data[5],
      startBreakLocation: data[6],
      breakReport: data[7],
      finishBreak: data[8],
      finishBreakLocation: data[9],
      finish: data[10],
      finishLocation: data[11],
      signOff: data[12],
      spread: data[13],
      work: data[14],
      relief: calculatedRelief,
    );
  }
  
  // Helper method to parse time string (HH:MM:SS) to total minutes
  static int? _parseTimeToMinutes(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length < 2) return null;
    
    try {
      final hours = int.parse(parts[0]);
      final minutes = int.parse(parts[1]);
      return hours * 60 + minutes;
    } catch (e) {
      return null;
    }
  }
}
