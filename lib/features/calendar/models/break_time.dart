class BreakTime {
  final String startTime;
  final String endTime;
  final String? startLocation;
  final String? endLocation;

  const BreakTime({
    required this.startTime,
    required this.endTime,
    this.startLocation,
    this.endLocation,
  });

  Duration get duration {
    final startParts = startTime.split(':');
    final endParts = endTime.split(':');
    
    final start = DateTime(2000, 1, 1, 
      int.parse(startParts[0]), 
      int.parse(startParts[1])
    );
    
    var end = DateTime(2000, 1, 1,
      int.parse(endParts[0]),
      int.parse(endParts[1])
    );
    
    // Handle breaks that cross midnight
    if (end.isBefore(start)) {
      end = end.add(const Duration(days: 1));
    }
    
    return end.difference(start);
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('$startTime - $endTime');
    if (startLocation != null) {
      buffer.write(' at $startLocation');
    }
    return buffer.toString();
  }
} 