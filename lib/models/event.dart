import 'package:flutter/material.dart';

class Event {
  final String id;
  String title;
  DateTime startDate;
  TimeOfDay startTime;
  DateTime endDate;
  TimeOfDay endTime;
  Duration? workTime;  // For PZ shifts
  TimeOfDay? breakStartTime;  // For UNI shifts
  TimeOfDay? breakEndTime;    // For UNI shifts
  List<String>? assignedDuties;  // For storing multiple duties assigned to spare shifts
  String? firstHalfBus;  // For storing the first half bus number
  String? secondHalfBus;  // For storing the second half bus number
  bool isHoliday;  // Whether this event represents a holiday
  String? holidayType;  // The type of holiday ('winter' or 'summer')
  String? notes; // Add notes field
  // Add new fields for overtime tracking
  bool hasLateBreak;
  bool tookFullBreak; 
  int? overtimeDuration; // In minutes

  Event({
    required this.id,
    required this.title,
    required this.startDate,
    required this.startTime,
    required this.endDate,
    required this.endTime,
    this.workTime,
    this.breakStartTime,
    this.breakEndTime,
    this.assignedDuties,
    this.firstHalfBus,
    this.secondHalfBus,
    this.isHoliday = false,
    this.holidayType,
    this.notes,
    this.hasLateBreak = false,
    this.tookFullBreak = false,
    this.overtimeDuration,
  });

  // Add copyWith method
  Event copyWith({
    String? id,
    String? title,
    DateTime? startDate,
    TimeOfDay? startTime,
    DateTime? endDate,
    TimeOfDay? endTime,
    Duration? workTime,
    TimeOfDay? breakStartTime,
    TimeOfDay? breakEndTime,
    List<String>? assignedDuties,
    String? firstHalfBus,
    String? secondHalfBus,
    bool? isHoliday,
    String? holidayType,
    String? notes,
    bool? hasLateBreak,
    bool? tookFullBreak,
    int? overtimeDuration,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      startDate: startDate ?? this.startDate,
      startTime: startTime ?? this.startTime,
      endDate: endDate ?? this.endDate,
      endTime: endTime ?? this.endTime,
      workTime: workTime ?? this.workTime,
      breakStartTime: breakStartTime ?? this.breakStartTime,
      breakEndTime: breakEndTime ?? this.breakEndTime,
      assignedDuties: assignedDuties ?? this.assignedDuties,
      firstHalfBus: firstHalfBus ?? this.firstHalfBus,
      secondHalfBus: secondHalfBus ?? this.secondHalfBus,
      isHoliday: isHoliday ?? this.isHoliday,
      holidayType: holidayType ?? this.holidayType,
      notes: notes ?? this.notes,
      hasLateBreak: hasLateBreak ?? this.hasLateBreak,
      tookFullBreak: tookFullBreak ?? this.tookFullBreak,
      overtimeDuration: overtimeDuration ?? this.overtimeDuration,
    );
  }

  // Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'startDate': startDate.toIso8601String(),
      'startTime': {'hour': startTime.hour, 'minute': startTime.minute},
      'endDate': endDate.toIso8601String(),
      'endTime': {'hour': endTime.hour, 'minute': endTime.minute},
      'workTime': workTime?.inMinutes,  // Store work time in minutes
      'breakStartTime': breakStartTime != null 
        ? {'hour': breakStartTime!.hour, 'minute': breakStartTime!.minute}
        : null,
      'breakEndTime': breakEndTime != null
        ? {'hour': breakEndTime!.hour, 'minute': breakEndTime!.minute}
        : null,
      'assignedDuties': assignedDuties,
      'firstHalfBus': firstHalfBus,
      'secondHalfBus': secondHalfBus,
      'isHoliday': isHoliday,
      'holidayType': holidayType,
      'notes': notes,
      'hasLateBreak': hasLateBreak,
      'tookFullBreak': tookFullBreak,
      'overtimeDuration': overtimeDuration,
    };
  }

  // Create from map from storage
  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'],
      title: map['title'],
      startDate: DateTime.parse(map['startDate']),
      startTime: TimeOfDay(
        hour: map['startTime']['hour'],
        minute: map['startTime']['minute'],
      ),
      endDate: DateTime.parse(map['endDate']),
      endTime: TimeOfDay(
        hour: map['endTime']['hour'],
        minute: map['endTime']['minute'],
      ),
      workTime: map['workTime'] != null 
        ? Duration(minutes: map['workTime'])
        : null,
      breakStartTime: map['breakStartTime'] != null
        ? TimeOfDay(
            hour: map['breakStartTime']['hour'],
            minute: map['breakStartTime']['minute'],
          )
        : null,
      breakEndTime: map['breakEndTime'] != null
        ? TimeOfDay(
            hour: map['breakEndTime']['hour'],
            minute: map['breakEndTime']['minute'],
          )
        : null,
      assignedDuties: map['assignedDuties'] != null 
        ? List<String>.from(map['assignedDuties'])
        : null,
      firstHalfBus: map['firstHalfBus'],
      secondHalfBus: map['secondHalfBus'],
      isHoliday: map['isHoliday'] ?? false,
      holidayType: map['holidayType'],
      notes: map['notes'],
      hasLateBreak: map['hasLateBreak'] ?? false,
      tookFullBreak: map['tookFullBreak'] ?? false,
      overtimeDuration: map['overtimeDuration'],
    );
  }

  // Format times for display
  String get formattedStartTime => _formatTimeOfDay(startTime);
  String get formattedEndTime => _formatTimeOfDay(endTime);
  
  // Get a full DateTime with time components
  DateTime get fullStartDateTime => DateTime(
    startDate.year,
    startDate.month, 
    startDate.day,
    startTime.hour,
    startTime.minute,
  );
  
  DateTime get fullEndDateTime => DateTime(
    endDate.year,
    endDate.month, 
    endDate.day,
    endTime.hour,
    endTime.minute,
  );
  
  String _formatTimeOfDay(TimeOfDay timeOfDay) {
    final hour = timeOfDay.hour.toString().padLeft(2, '0');
    final minute = timeOfDay.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
  
  // Is this a work shift?
  bool get isWorkShift => title.startsWith('Shift:') || 
                         title.startsWith('SP') || 
                         title.startsWith('PZ') || 
                         title.startsWith('BusCheck') ||
                         RegExp(r'^\d+/').hasMatch(title);
  
  // Check if this duty is eligible for overtime tracking
  bool get isEligibleForOvertimeTracking {
    // First check if it's a work shift
    if (!isWorkShift) return false;
    
    // Check if it's a Zone 1, 3, or 4 duty
    final isZoneDuty = title.startsWith('PZ1') || 
                      title.startsWith('PZ3') || 
                      title.startsWith('PZ4') ||
                      // Handle case when PZ is not in the title
                      title.startsWith('1/') || 
                      title.startsWith('3/') || 
                      title.startsWith('4/');
    
    // Exclude workout shifts - look for 'workout' in the title
    final isWorkout = title.toLowerCase().contains('workout');
    
    return isZoneDuty && !isWorkout;
  }
  
  // Get shift code - properly handle shift codes
  String get shiftCode {
    String code = title;
    if (title.startsWith('Shift:')) {
      code = title.substring(6).trim();
    }
    if (!code.startsWith('PZ') && (code.startsWith('1') || code.startsWith('3') || code.startsWith('4'))) {
      code = 'PZ$code';
    }
    return code;
  }

  factory Event.fromList(List<String> data) {
    // Parse work time if it exists (for PZ shifts)
    Duration? workTime;
    if (data.length > 14 && data[14].isNotEmpty) {  // Changed from 8 to 14 to read from correct column
      final parts = data[14].split(':');
      if (parts.length == 2) {
        workTime = Duration(
          hours: int.parse(parts[0]),
          minutes: int.parse(parts[1]),
        );
      }
    }

    return Event(
      id: '',
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
      workTime: workTime,
    );
  }
}
