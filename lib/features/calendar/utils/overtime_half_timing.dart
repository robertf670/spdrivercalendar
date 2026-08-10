import 'package:flutter/material.dart';

/// Start/end times for one overtime half of a duty.
class OvertimeHalfTimes {
  const OvertimeHalfTimes({
    required this.startTime,
    required this.endTime,
  });

  final TimeOfDay startTime;
  final TimeOfDay endTime;
}

/// Adjusts full-duty times to first half (A) or second half (B).
///
/// Uses break times when available; otherwise falls back to the midpoint of the
/// full duty. EA Type Training keeps CSV times unchanged.
OvertimeHalfTimes adjustOvertimeHalfTimes({
  required TimeOfDay startTime,
  required TimeOfDay endTime,
  required String overtimeHalfType,
  TimeOfDay? breakStartTime,
  TimeOfDay? breakEndTime,
  bool isEATypeTraining = false,
}) {
  if (isEATypeTraining) {
    return OvertimeHalfTimes(startTime: startTime, endTime: endTime);
  }

  final shiftDurationMinutes =
      (endTime.hour * 60 + endTime.minute) - (startTime.hour * 60 + startTime.minute);

  if (overtimeHalfType == 'A') {
    if (breakStartTime != null) {
      return OvertimeHalfTimes(
        startTime: startTime,
        endTime: breakStartTime,
      );
    }
    final halfDurationMinutes = shiftDurationMinutes ~/ 2;
    return OvertimeHalfTimes(
      startTime: startTime,
      endTime: TimeOfDay(
        hour: (startTime.hour + (halfDurationMinutes ~/ 60)) % 24,
        minute: (startTime.minute + (halfDurationMinutes % 60)) % 60,
      ),
    );
  }

  // Second half (B)
  if (breakEndTime != null) {
    return OvertimeHalfTimes(
      startTime: breakEndTime,
      endTime: endTime,
    );
  }
  final halfDurationMinutes = shiftDurationMinutes ~/ 2;
  return OvertimeHalfTimes(
    startTime: TimeOfDay(
      hour: (startTime.hour + (halfDurationMinutes ~/ 60)) % 24,
      minute: (startTime.minute + (halfDurationMinutes % 60)) % 60,
    ),
    endTime: endTime,
  );
}
