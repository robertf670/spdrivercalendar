import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spdrivercalendar/models/event.dart';
import 'package:spdrivercalendar/features/calendar/services/roster_service.dart';
import 'package:spdrivercalendar/models/bank_holiday.dart';
import 'package:spdrivercalendar/models/shift_data.dart';
import 'package:spdrivercalendar/core/utils/location_utils.dart';

class ShiftService {
  // List of bank holidays
  static List<BankHoliday> _bankHolidays = [];
  
  // Initialize and load bank holidays
  static Future<void> initialize() async {
    try {
      _bankHolidays = await RosterService.loadBankHolidays();
      print('Loaded ${_bankHolidays.length} bank holidays');
      for (final holiday in _bankHolidays) {
        print('Bank holiday: ${holiday.name} on ${holiday.date}');
      }
    } catch (e) {
      print('Error initializing bank holidays: $e');
      _bankHolidays = [];
    }
  }
  
  // Getter for bank holidays
  static List<BankHoliday> get bankHolidays => _bankHolidays;
  
  // Set bank holidays (useful for tests or manual updates)
  static set bankHolidays(List<BankHoliday> holidays) {
    _bankHolidays = holidays;
  }

  // Get break time information for an event
  static Future<String?> getBreakTime(Event event) async {
    // Extract the shift code from the title
    final shiftCode = event.title.replaceAll('Shift: ', '').trim();
    
    // Handle Spare shifts which don't have break times
    if (shiftCode.startsWith('SP')) {
      return null;
    }
    
    final dayOfWeek = RosterService.getDayOfWeek(event.startDate);
    
    // Try to determine if this is a UNI/Euro shift
    bool isUniEuro = shiftCode.startsWith('UNI') || 
                     shiftCode.contains('EURO') || 
                     RegExp(r'^\d{2,3}/\d{2}').hasMatch(shiftCode);
    
    
    if (isUniEuro) {
      return await _getUniShiftBreakTime(shiftCode, dayOfWeek, event.startDate);
    } else {
      return await _getRegularShiftBreakTime(shiftCode, dayOfWeek, event.startDate);
    }
  }
  
  // Helper method to get break time for UNI/Euro shifts
  static Future<String> _getUniShiftBreakTime(String shiftCode, String dayOfWeek, DateTime date) async {
    try {
      
      // Check 7-day UNI shifts first - include all lines (no skipping first line)
      final file7Days = await rootBundle.loadString('assets/UNI_7DAYs.csv');
      final lines7Days = file7Days.split('\n');
      
      for (final line in lines7Days) {
        if (line.trim().isEmpty) continue;
        final parts = line.split(',');
        if (parts.length < 5) {
          continue;
        }
        final shift = parts[0];
        
        if (shift == shiftCode) {
          
          // For UNI files, break start is at index 2 and break finish at index 3
          final breakStart = parts[2].trim();
          final breakEnd = parts[3].trim();
          
          
          // Check if this is a workout shift or has "nan" values
          // For UNI shifts, if break times are the same, it's a workout
          if (breakStart.toLowerCase() == 'workout' || breakEnd.toLowerCase() == 'workout' ||
              breakStart.isEmpty || breakEnd.isEmpty ||
              breakStart.toLowerCase() == 'nan' || breakEnd.toLowerCase() == 'nan' ||
              breakStart == breakEnd) {  // Added check for equal times
            return 'Workout';
          }
          
          // Format the break times, removing seconds if present
          final formattedStart = breakStart.split(':').take(2).join(':');
          final formattedEnd = breakEnd.split(':').take(2).join(':');
          
          return '$formattedStart - $formattedEnd';
        }
      }
      
      
      // Then check M-F shifts if appropriate - include all lines (no skipping first line)
      final bankHoliday = getBankHoliday(date, _bankHolidays);
      final isBankHoliday = bankHoliday != null;
      
      if (isBankHoliday) {
      }
      
      if (dayOfWeek != 'Saturday' && dayOfWeek != 'Sunday' && !isBankHoliday) {
        final fileMF = await rootBundle.loadString('assets/UNI_M-F.csv');
        final linesMF = fileMF.split('\n');
        
        for (final line in linesMF) {
          if (line.trim().isEmpty) continue;
          final parts = line.split(',');
          if (parts.length < 5) {
            continue;
          }
          final shift = parts[0];
          
          if (shift == shiftCode) {
            // For UNI files, break start is at index 2 and break finish at index 3
            final breakStart = parts[2].trim();
            final breakEnd = parts[3].trim();
            
            
            // Check if this is a workout shift or has "nan" values
            // For UNI shifts, if break times are the same, it's a workout
            if (breakStart.toLowerCase() == 'workout' || breakEnd.toLowerCase() == 'workout' ||
                breakStart.isEmpty || breakEnd.isEmpty ||
                breakStart.toLowerCase() == 'nan' || breakEnd.toLowerCase() == 'nan' ||
                breakStart == breakEnd) {  // Added check for equal times
              return 'Workout';
            }
            
            // Format the break times, removing seconds if present
            final formattedStart = breakStart.split(':').take(2).join(':');
            final formattedEnd = breakEnd.split(':').take(2).join(':');
            
            return '$formattedStart - $formattedEnd';
          }
        }
      }
      
      return 'No break info';
    } catch (e) {
      return 'Error loading break info';
    }
  }
  
  // Helper method to get break time for regular shifts
  static Future<String> _getRegularShiftBreakTime(String shiftCode, String dayOfWeek, DateTime date) async {
    try {
      // Find zone number from the shift code (typical format might be "PZn/123")
      String zoneNumber = '1'; // Default to zone 1
      final match = RegExp(r'PZ(\d+)/').firstMatch(shiftCode);
      if (match != null) {
        zoneNumber = match.group(1) ?? '1';
      }
      
      
      // Check bank holiday status
      final bankHoliday = getBankHoliday(date, _bankHolidays);
      final isBankHoliday = bankHoliday != null;
      
      if (isBankHoliday) {
      }
    
      // Convert full day name to abbreviated format for file loading
      String dayOfWeekForFilename;
      if (dayOfWeek == 'Saturday') {
        dayOfWeekForFilename = 'SAT';
      } else if (dayOfWeek == 'Sunday') {
        dayOfWeekForFilename = 'SUN';
      } else {
        dayOfWeekForFilename = 'M-F';
      }
      
      final filename = RosterService.getShiftFilename(zoneNumber, dayOfWeekForFilename, date);
      
      try {
        final file = await rootBundle.loadString('assets/$filename');
        final lines = file.split('\n');
    
        for (final line in lines) {
          if (line.trim().isEmpty) continue;
          final parts = line.split(',');
          if (parts.length < 4) continue;
          final shift = parts[0];
          if (shift == shiftCode) {
            return _parseBreakTime(parts);
          }
        }
        
      } catch (e) {
        print('Error loading shift file: $e');
      }
      
      return 'No break info found';
    } catch (e) {
      print('Error getting break time: $e');
      return 'Error loading break info';
    }
  }
  
  // Helper to parse break time from shift data parts
  static String _parseBreakTime(List<String> parts) {
    if (parts.length < 6) return 'No break info';
    
    // For debugging
    
    // Get the break start/end times from the appropriate CSV columns
    // In the PZ CSV files, startbreak is column 6 (index 5) and finishbreak is column 9 (index 8)
    final breakStart = parts.length > 5 ? parts[5].trim().toLowerCase() : '';
    final breakEnd = parts.length > 8 ? parts[8].trim().toLowerCase() : '';
    
    
    // Check if this is a workout shift (many formats possible in data)
    if (breakStart == 'nan' || breakStart == 'workout' || breakStart.isEmpty || 
        breakEnd == 'nan' || breakEnd == 'workout' || breakEnd.isEmpty ||
        breakStart == 'n/a' || breakEnd == 'n/a') {
      return 'Workout';
    }
    
    try {
      // Properly parse time formats which may include seconds
      final startTimeParts = breakStart.split(':');
      final endTimeParts = breakEnd.split(':');
      
      // Additional check for invalid formats
      if (startTimeParts.length < 2 || endTimeParts.length < 2) {
        return 'Workout'; // If time format is invalid, assume workout
      }
      
      final startHour = int.tryParse(startTimeParts[0]);
      final startMinute = int.tryParse(startTimeParts[1]);
      
      final endHour = int.tryParse(endTimeParts[0]);
      final endMinute = int.tryParse(endTimeParts[1]);
      
      // If any part couldn't be parsed, it's probably a workout
      if (startHour == null || startMinute == null || endHour == null || endMinute == null) {
        return 'Workout';
      }

      if (startHour == endHour && startMinute == endMinute) {
        return 'No break';
      } else {
        final formattedStart = _formatTimeOfDay(TimeOfDay(hour: startHour, minute: startMinute));
        final formattedEnd = _formatTimeOfDay(TimeOfDay(hour: endHour, minute: endMinute));
        return '$formattedStart - $formattedEnd';
      }
    } catch (e) {
      print('Error parsing break times: $e');
      return 'Workout'; // Default to Workout for any errors
    }
  }
  
  static String _formatTimeOfDay(TimeOfDay timeOfDay) {
    final hour = timeOfDay.hour.toString().padLeft(2, '0');
    final minute = timeOfDay.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
  
  // Get zone number from zone text
  static String getZoneNumber(String zone) {
    if (zone.startsWith('Shift: ')) {
      final match = RegExp(r'PZ(\d+)/').firstMatch(zone);
      if (match != null) {
        return match.group(1) ?? '1';
      } else {
        return '1';
      }
    } else {
      final match = RegExp(r'Zone (\d+)').firstMatch(zone);
      if (match != null) {
        return match.group(1) ?? '1';
      } else {
        return '1';
      }
    }
  }

  // Convert a ShiftData to a formatted description for display or Google Calendar
  static String formatShiftDetails(ShiftData shiftData) {
    final List<String> details = [];

    // Add shift number and duty information
    details.add('Shift: ${shiftData.shift}');
    if (shiftData.duty.isNotEmpty) {
      details.add('Duty: ${shiftData.duty}');
    }

    // Add report time and location
    final reportLocation = mapLocationName(shiftData.location);
    details.add('Report: ${shiftData.report} at $reportLocation');

    // Add departure time if different from report time
    if (shiftData.depart != shiftData.report) {
      details.add('Depart: ${shiftData.depart}');
    }

    // Add break times if they exist
    if (shiftData.startBreak.isNotEmpty && shiftData.startBreak != "00:00") {
      final breakStartLocation = mapLocationName(shiftData.startBreakLocation);
      details.add('Break Start: ${shiftData.startBreak} at $breakStartLocation');
      
      if (shiftData.finishBreak.isNotEmpty && shiftData.finishBreak != "00:00") {
        final breakEndLocation = mapLocationName(shiftData.finishBreakLocation);
        details.add('Break End: ${shiftData.finishBreak} at $breakEndLocation');
      }
    }

    // Add finish time and location
    final finishLocation = mapLocationName(shiftData.finishLocation);
    details.add('Finish: ${shiftData.finish} at $finishLocation');

    // Add sign-off time if different from finish time
    if (shiftData.signOff != shiftData.finish) {
      details.add('Sign-off: ${shiftData.signOff}');
    }

    // Add additional details
    details.add('Spread: ${shiftData.spread}');
    details.add('Work: ${shiftData.work}');
    
    if (shiftData.relief.isNotEmpty && shiftData.relief != "0") {
      details.add('Relief: ${shiftData.relief}');
    }

    return details.join('\n');
  }

  // Determine if a date is a bank holiday
  static BankHoliday? getBankHoliday(DateTime date, List<BankHoliday> bankHolidays) {
    for (final holiday in bankHolidays) {
      if (holiday.matchesDate(date)) {
        return holiday;
      }
    }
    return null;
  }

  // Convert shift code to a human-readable title
  static String getShiftTypeTitle(String shiftCode) {
    if (shiftCode.startsWith('SP')) {
      return 'Spare Shift';
    } else if (shiftCode.endsWith('X')) {
      return 'Bogey Shift';
    } else if (RegExp(r'^\d{2,3}/').hasMatch(shiftCode)) {
      return 'Uni/Euro Shift';
    } else if (shiftCode.contains('PZ1')) {
      return 'Zone 1 Shift';
    } else if (shiftCode.contains('PZ3')) {
      return 'Zone 3 Shift';
    } else if (shiftCode.contains('PZ4')) {
      return 'Zone 4 Shift';
    } else {
      return 'Work Shift';
    }
  }

  // Determine shift category (Early, Late, Middle, etc.) based on start time
  static String getShiftCategory(TimeOfDay startTime) {
    final hour = startTime.hour;
    
    if (hour >= 4 && hour < 10) {
      return 'Early';
    } else if (hour >= 10 && hour < 14) {
      return 'Middle';
    } else if (hour >= 14 && hour < 19) {
      return 'Late';
    } else {
      return 'Night';
    }
  }
}