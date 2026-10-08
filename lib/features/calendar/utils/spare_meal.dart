import 'package:flutter/material.dart';
import 'package:spdrivercalendar/models/event.dart';

/// Spare meal: always 1 hour. Finish is the sooner of the usual spare
/// sign-off (start + 8h 38m) and meal end + 5h 30m.
class SpareMeal {
  SpareMeal._();

  static const spread = Duration(hours: 8, minutes: 38);
  static const mealLength = Duration(hours: 1);
  static const afterMeal = Duration(hours: 5, minutes: 30);

  static bool isSpareTitle(String title) => title.startsWith('SP');

  static DateTime originalFinish(DateTime start) => start.add(spread);

  static String clockFromDateTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static String originalFinishClock(Event event) =>
      clockFromDateTime(originalFinish(event.fullStartDateTime));

  static bool hasMovedFinish(Event event) {
    if (event.breakStartTime == null || event.breakEndTime == null) {
      return false;
    }
    final original = originalFinish(event.fullStartDateTime);
    final actual = event.fullEndDateTime;
    return DateTime(actual.year, actual.month, actual.day, actual.hour, actual.minute) !=
        DateTime(
          original.year,
          original.month,
          original.day,
          original.hour,
          original.minute,
        );
  }

  static DateTime finishWithMeal({
    required DateTime start,
    required DateTime mealStart,
  }) {
    final fromMeal = mealStart.add(mealLength).add(afterMeal);
    final original = originalFinish(start);
    return fromMeal.isBefore(original) ? fromMeal : original;
  }

  static Map<String, dynamic> timesForStartClock(String selectedShiftNumber) {
    final timeParts = selectedShiftNumber.split(':');
    if (timeParts.length != 2) {
      return {
        'startTime': const TimeOfDay(hour: 4, minute: 0),
        'endTime': const TimeOfDay(hour: 12, minute: 38),
        'isNextDay': false,
      };
    }
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    final start = DateTime(2000, 1, 1, hour, minute);
    final end = originalFinish(start);
    return {
      'startTime': TimeOfDay(hour: hour, minute: minute),
      'endTime': TimeOfDay(hour: end.hour, minute: end.minute),
      'isNextDay': end.day != start.day,
    };
  }

  static void apply(Event event, TimeOfDay mealStart) {
    final start = event.fullStartDateTime;
    final mealStartAt = DateTime(
      event.startDate.year,
      event.startDate.month,
      event.startDate.day,
      mealStart.hour,
      mealStart.minute,
    );
    final mealEndAt = mealStartAt.add(mealLength);
    event.breakStartTime = mealStart;
    event.breakEndTime = TimeOfDay(
      hour: mealEndAt.hour,
      minute: mealEndAt.minute,
    );
    final finish = finishWithMeal(start: start, mealStart: mealStartAt);
    event.endDate = DateTime(finish.year, finish.month, finish.day);
    event.endTime = TimeOfDay(hour: finish.hour, minute: finish.minute);
  }

  static void clear(Event event) {
    event.breakStartTime = null;
    event.breakEndTime = null;
    final finish = originalFinish(event.fullStartDateTime);
    event.endDate = DateTime(finish.year, finish.month, finish.day);
    event.endTime = TimeOfDay(hour: finish.hour, minute: finish.minute);
  }
}
