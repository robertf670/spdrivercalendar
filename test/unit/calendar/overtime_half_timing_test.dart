import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/utils/overtime_half_timing.dart';

void main() {
  const start = TimeOfDay(hour: 8, minute: 0);
  const end = TimeOfDay(hour: 16, minute: 0);
  const breakStart = TimeOfDay(hour: 12, minute: 0);
  const breakEnd = TimeOfDay(hour: 12, minute: 40);

  test('first half uses break start when available', () {
    final times = adjustOvertimeHalfTimes(
      startTime: start,
      endTime: end,
      overtimeHalfType: 'A',
      breakStartTime: breakStart,
      breakEndTime: breakEnd,
    );
    expect(times.startTime, start);
    expect(times.endTime, breakStart);
  });

  test('second half uses break end when available', () {
    final times = adjustOvertimeHalfTimes(
      startTime: start,
      endTime: end,
      overtimeHalfType: 'B',
      breakStartTime: breakStart,
      breakEndTime: breakEnd,
    );
    expect(times.startTime, breakEnd);
    expect(times.endTime, end);
  });

  test('falls back to midpoint when break times missing', () {
    final first = adjustOvertimeHalfTimes(
      startTime: start,
      endTime: end,
      overtimeHalfType: 'A',
    );
    expect(first.startTime, start);
    expect(first.endTime, const TimeOfDay(hour: 12, minute: 0));

    final second = adjustOvertimeHalfTimes(
      startTime: start,
      endTime: end,
      overtimeHalfType: 'B',
    );
    expect(second.startTime, const TimeOfDay(hour: 12, minute: 0));
    expect(second.endTime, end);
  });

  test('EA Type Training keeps full duty times', () {
    final times = adjustOvertimeHalfTimes(
      startTime: start,
      endTime: end,
      overtimeHalfType: 'A',
      breakStartTime: breakStart,
      breakEndTime: breakEnd,
      isEATypeTraining: true,
    );
    expect(times.startTime, start);
    expect(times.endTime, end);
  });
}
