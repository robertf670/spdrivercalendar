import 'package:flutter/material.dart';
import 'break_time.dart';

class Event {
  final String? id;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String? description;
  final bool isWorkShift;
  final BreakTime? breakTime;
  final String? location;
  final Duration? workTime;  // For PZ shifts that have predefined work time

  const Event({
    this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.startTime,
    required this.endTime,
    this.description,
    this.isWorkShift = false,
    this.breakTime,
    this.location,
    this.workTime,
  });

  factory Event.fromList(List<String> data) {
    // Parse work time if it exists (for PZ shifts)
    Duration? workTime;
    if (data.length > 14 && data[14].isNotEmpty) {
      final parts = data[14].split(':');
      if (parts.length == 2) {
        workTime = Duration(
          hours: int.parse(parts[0]),
          minutes: int.parse(parts[1]),
        );
      }
    }

    return Event(
      title: data[0],
      startDate: DateTime.parse(data[1]),
      endDate: DateTime.parse(data[2]),
      startTime: TimeOfDay(
        hour: int.parse(data[3].split(':')[0]),
        minute: int.parse(data[3].split(':')[1]),
      ),
      endTime: TimeOfDay(
        hour: int.parse(data[4].split(':')[0]),
        minute: int.parse(data[4].split(':')[1]),
      ),
      description: data.length > 5 ? data[5] : null,
      isWorkShift: data.length > 6 ? data[6] == 'true' : false,
      location: data.length > 7 ? data[7] : null,
      workTime: workTime,
    );
  }

  Event copyWith({
    String? id,
    String? title,
    DateTime? startDate,
    DateTime? endDate,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    String? description,
    bool? isWorkShift,
    BreakTime? breakTime,
    String? location,
    Duration? workTime,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      description: description ?? this.description,
      isWorkShift: isWorkShift ?? this.isWorkShift,
      breakTime: breakTime ?? this.breakTime,
      location: location ?? this.location,
      workTime: workTime ?? this.workTime,
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('Event: $title');
    buffer.writeln('Start Date: ${startDate.toString()}');
    buffer.writeln('End Date: ${endDate.toString()}');
    buffer.writeln('Start Time: ${startTime.toString()}');
    buffer.writeln('End Time: ${endTime.toString()}');
    if (description != null) {
      buffer.writeln('Description: $description');
    }
    if (location != null) {
      buffer.writeln('Location: $location');
    }
    buffer.writeln('Is Work Shift: $isWorkShift');
    if (breakTime != null) {
      buffer.writeln('Break: ${breakTime.toString()}');
    }
    return buffer.toString();
  }
} 