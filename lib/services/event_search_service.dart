import 'package:flutter/material.dart';
import 'package:spdrivercalendar/models/event.dart';
import 'package:spdrivercalendar/features/calendar/services/event_service.dart';

class EventSearchService {
  // Search events by query string
  static Future<List<Event>> searchEvents({
    String? query,
    String? busNumber,
    String? dutyCode,
    DateTime? startDate,
    DateTime? endDate,
    String? shiftType,
    bool? overtimeOnly,
    bool? hasNotes,
    String? sickDayType,
    bool? holidaysOnly,
    bool? sickDaysOnly,
  }) async {
    List<Event> allEvents = await EventService.getAllEvents();
    
    // Apply filters
    List<Event> filtered = allEvents;
    
    // Search query (searches in title, duty codes, notes)
    if (query != null && query.trim().isNotEmpty) {
      final searchLower = query.toLowerCase().trim();
      filtered = filtered.where((event) {
        // Search in title
        if (event.title.toLowerCase().contains(searchLower)) {
          return true;
        }
        
        // Search in notes
        if (event.notes != null && event.notes!.toLowerCase().contains(searchLower)) {
          return true;
        }
        
        // Search in duty codes
        if (event.hasEnhancedDuties) {
          for (final duty in event.enhancedAssignedDuties!) {
            if (duty.dutyCode.toLowerCase().contains(searchLower)) {
              return true;
            }
            if (duty.location != null && duty.location!.toLowerCase().contains(searchLower)) {
              return true;
            }
          }
        } else if (event.assignedDuties != null) {
          for (final duty in event.assignedDuties!) {
            if (duty.toLowerCase().contains(searchLower)) {
              return true;
            }
          }
        }
        
        return false;
      }).toList();
    }
    
    // Bus number filter
    if (busNumber != null && busNumber.trim().isNotEmpty) {
      final busLower = busNumber.trim().toLowerCase();
      filtered = filtered.where((event) {
        // Check firstHalfBus and secondHalfBus
        if (event.firstHalfBus != null && event.firstHalfBus!.toLowerCase().contains(busLower)) {
          return true;
        }
        if (event.secondHalfBus != null && event.secondHalfBus!.toLowerCase().contains(busLower)) {
          return true;
        }
        
        // Check busAssignments map
        if (event.busAssignments != null) {
          for (final bus in event.busAssignments!.values) {
            if (bus.toLowerCase().contains(busLower)) {
              return true;
            }
          }
        }
        
        // Check enhanced duties
        if (event.hasEnhancedDuties) {
          for (final duty in event.enhancedAssignedDuties!) {
            if (duty.assignedBus != null && duty.assignedBus!.toLowerCase().contains(busLower)) {
              return true;
            }
          }
        }
        
        return false;
      }).toList();
    }
    
    // Duty code filter
    if (dutyCode != null && dutyCode.trim().isNotEmpty) {
      final dutyLower = dutyCode.trim().toLowerCase();
      filtered = filtered.where((event) {
        if (event.hasEnhancedDuties) {
          for (final duty in event.enhancedAssignedDuties!) {
            if (duty.dutyCode.toLowerCase().contains(dutyLower)) {
              return true;
            }
          }
        }
        if (event.assignedDuties != null) {
          for (final duty in event.assignedDuties!) {
            if (duty.toLowerCase().contains(dutyLower)) {
              return true;
            }
          }
        }
        return false;
      }).toList();
    }
    
    // Date range filter
    if (startDate != null) {
      filtered = filtered.where((event) {
        final eventDate = DateTime(event.startDate.year, event.startDate.month, event.startDate.day);
        final filterDate = DateTime(startDate.year, startDate.month, startDate.day);
        return eventDate.isAfter(filterDate) || eventDate.isAtSameMomentAs(filterDate);
      }).toList();
    }
    
    if (endDate != null) {
      filtered = filtered.where((event) {
        final eventDate = DateTime(event.startDate.year, event.startDate.month, event.startDate.day);
        final filterDate = DateTime(endDate.year, endDate.month, endDate.day);
        return eventDate.isBefore(filterDate) || eventDate.isAtSameMomentAs(filterDate);
      }).toList();
    }
    
    // Shift type filter
    if (shiftType != null && shiftType.isNotEmpty) {
      filtered = filtered.where((event) {
        final title = event.title.toUpperCase();
        if (shiftType == 'SP' && title.startsWith('SP')) return true;
        if (shiftType == 'PZ' && title.startsWith('PZ')) return true;
        if (shiftType == 'UNI' && RegExp(r'^\d{2,3}/').hasMatch(event.title)) return true;
        if (shiftType == 'Early' && _isEarlyShift(event.startTime)) return true;
        if (shiftType == 'Late' && _isLateShift(event.startTime)) return true;
        if (shiftType == 'Relief' && _isReliefShift(event.startTime)) return true;
        if (shiftType == 'Night' && _isNightShift(event.startTime)) return true;
        return false;
      }).toList();
    }
    
    // Overtime only filter
    if (overtimeOnly == true) {
      filtered = filtered.where((event) {
        return event.title.contains('(OT)') || event.overtimeDuration != null;
      }).toList();
    }
    
    // Has notes filter
    if (hasNotes == true) {
      filtered = filtered.where((event) {
        return event.notes != null && event.notes!.trim().isNotEmpty;
      }).toList();
    }
    
    // Sick day filter
    if (sickDayType != null && sickDayType.isNotEmpty) {
      filtered = filtered.where((event) {
        return event.sickDayType == sickDayType;
      }).toList();
    }
    
    // Holidays only filter
    if (holidaysOnly == true) {
      filtered = filtered.where((event) {
        return event.isHoliday;
      }).toList();
    }
    
    // Sick days only filter (any sick day type)
    if (sickDaysOnly == true) {
      filtered = filtered.where((event) {
        return event.sickDayType != null;
      }).toList();
    }
    
    return filtered;
  }
  
  // Helper methods to determine shift type
  static bool _isEarlyShift(TimeOfDay time) {
    final hour = time.hour;
    return hour >= 4 && hour < 10;
  }
  
  static bool _isReliefShift(TimeOfDay time) {
    final hour = time.hour;
    return hour >= 10 && hour < 14;
  }
  
  static bool _isLateShift(TimeOfDay time) {
    final hour = time.hour;
    return hour >= 14 && hour < 19;
  }
  
  static bool _isNightShift(TimeOfDay time) {
    final hour = time.hour;
    return hour >= 19 || hour < 4;
  }
  
  // Get all unique bus numbers from events
  static Future<Set<String>> getAllBusNumbers() async {
    final events = await EventService.getAllEvents();
    final Set<String> busNumbers = {};
    
    for (final event in events) {
      if (event.firstHalfBus != null && event.firstHalfBus!.trim().isNotEmpty) {
        busNumbers.add(event.firstHalfBus!);
      }
      if (event.secondHalfBus != null && event.secondHalfBus!.trim().isNotEmpty) {
        busNumbers.add(event.secondHalfBus!);
      }
      if (event.busAssignments != null) {
        for (final bus in event.busAssignments!.values) {
          if (bus.trim().isNotEmpty) {
            busNumbers.add(bus);
          }
        }
      }
      if (event.hasEnhancedDuties) {
        for (final duty in event.enhancedAssignedDuties!) {
          if (duty.assignedBus != null && duty.assignedBus!.trim().isNotEmpty) {
            busNumbers.add(duty.assignedBus!);
          }
        }
      }
    }
    
    return busNumbers;
  }
  
  // Get all unique duty codes from events
  static Future<Set<String>> getAllDutyCodes() async {
    final events = await EventService.getAllEvents();
    final Set<String> dutyCodes = {};
    
    for (final event in events) {
      if (event.hasEnhancedDuties) {
        for (final duty in event.enhancedAssignedDuties!) {
          dutyCodes.add(duty.dutyCode);
        }
      }
      if (event.assignedDuties != null) {
        for (final duty in event.assignedDuties!) {
          dutyCodes.add(duty);
        }
      }
    }
    
    return dutyCodes;
  }
}

