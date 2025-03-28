import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:spdrivercalendar/models/bank_holiday.dart';
import 'package:spdrivercalendar/models/shift_data.dart';
import 'package:spdrivercalendar/features/calendar/services/shift_service.dart';

class RosterService {
  // The 5-week roster pattern with Sunday as the first day of the week
  static final List<String> rosterWeeks = [
    'LLRLLLR', // Week 1: Late, Late, Rest, Late, Late, Late, Rest
    'REEEERE', // Week 2: Rest, Early, Early, Early, Early, Early, Rest
    'ELLREER', // Week 3: Early, Late, Late, Rest, Early, Early, Rest
    'RRLLLLL', // Week 4: Rest, Rest, Late, Late, Late, Late, Late
    'REEEREM', // Week 5: Rest, Early, Early, Early, Rest, Early, Middle/Relief
  ];
  
  // Get rest days for a specific week pattern
  static String getRestDaysForWeek(int weekIndex) {
    if (weekIndex < 0 || weekIndex >= rosterWeeks.length) {
      return 'Invalid';
    }
    
    final pattern = rosterWeeks[weekIndex];
    final days = <String>[];
    
    for (int i = 0; i < pattern.length; i++) {
      if (pattern[i] == 'R') {
        switch (i) {
          case 0: days.add('Sunday'); break;
          case 1: days.add('Monday'); break;
          case 2: days.add('Tuesday'); break;
          case 3: days.add('Wednesday'); break;
          case 4: days.add('Thursday'); break;
          case 5: days.add('Friday'); break;
          case 6: days.add('Saturday'); break;
        }
      }
    }
    
    return days.join(', ');
  }
  
  // Get shift pattern for a specific week and zone
  static List<String> getShiftPattern(int weekNumber, String zoneNumber) {
    // Make sure weekNumber is within bounds
    final safeWeekNumber = weekNumber % 5;
    
    // Get the roster week for this week number
    final weekPattern = rosterWeeks[safeWeekNumber];
    
    // Convert the pattern string into a list of individual shifts
    return weekPattern.split('');
  }
  
  // Get shift for a specific date
  static String getShiftForDate(DateTime date, DateTime startDate, int startWeek) {
    // Get the day of week (0 = Sunday, 6 = Saturday)
    final dayOfWeek = date.weekday % 7; // Sunday will be 0, Monday 1, etc.
    
    // Calculate how many days have passed since the start date
    final daysSinceStart = date.difference(startDate).inDays;
    
    // Calculate the week number in the 5-week pattern
    int weekNumber;
    
    // Handle dates in the future or present relative to start date
    if (daysSinceStart >= 0) {
      // Calculate weeks since start date
      final weeksSinceStart = daysSinceStart ~/ 7;
      weekNumber = (startWeek + weeksSinceStart) % 5;
    } 
    // Handle dates before the start date
    else {
      // First, determine if we're in the same week as the start date
      // by checking if the date's Sunday is the same as the start date's Sunday
      final dateSunday = date.subtract(Duration(days: dayOfWeek));
      final startDateSunday = startDate.subtract(Duration(days: startDate.weekday % 7));
      
      if (dateSunday == startDateSunday) {
        // We're in the same week as the start date, use the same week number
        weekNumber = startWeek;
      } else {
        // We're in a previous week
        // Calculate how many complete weeks we're going back
        final sundayDiff = startDateSunday.difference(dateSunday).inDays ~/ 7;
        weekNumber = (startWeek - sundayDiff + 5) % 5;
      }
    }
    
    // Get the shift pattern for this week
    final pattern = getShiftPattern(weekNumber, '1'); // Using Zone 1 as default
    
    // Get the shift for this day
    final shift = pattern[dayOfWeek];
    
    // Debug info
    // print('Date: ${date.toString()}, Day: ${getDayOfWeek(date)}, dayOfWeek: $dayOfWeek');
    // print('startDate: ${startDate.toString()}, startWeek: $startWeek');
    // print('daysSinceStart: $daysSinceStart');
    // if (daysSinceStart >= 0) {
    //   print('weeksSinceStart: ${daysSinceStart ~/ 7}');
    // } else {
    //   final dateSunday = date.subtract(Duration(days: dayOfWeek));
    //   final startDateSunday = startDate.subtract(Duration(days: startDate.weekday % 7));
    //   if (dateSunday == startDateSunday) {
    //     print('In same week as start date');
    //   } else {
    //     final sundayDiff = startDateSunday.difference(dateSunday).inDays ~/ 7;
    //     print('Weeks before start: $sundayDiff');
    //   }
    // }
    // print('weekNumber: $weekNumber, pattern: ${pattern.join('')}, shift: $shift');
    
    return shift;
  }
  
  // Helper method to determine the day of week string
  static String getDayOfWeek(DateTime date) {
    // Modified to handle Sunday properly
    final dayOfWeek = date.weekday % 7; // 0 = Sunday, 1-6 = Monday-Saturday
    
    switch (dayOfWeek) {
      case 0: return 'Sunday';
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      default: return 'Unknown';
    }
  }
  
  // Determine filename for shift pattern file
  static String getShiftFilename(String zoneNumber, String dayOfWeek, DateTime date) {
    // Check if it's a bank holiday
    final isBankHoliday = ShiftService.bankHolidays.any((holiday) => holiday.matchesDate(date));
    
    
    if (isBankHoliday) {
      // Use Sunday duties for bank holidays
      return 'SUN_DUTIES_PZ$zoneNumber.csv';
    } else if (dayOfWeek == 'Saturday') {
      return 'SAT_DUTIES_PZ$zoneNumber.csv';
    } else if (dayOfWeek == 'Sunday') {
      return 'SUN_DUTIES_PZ$zoneNumber.csv';
    } else {
      return 'M-F_DUTIES_PZ$zoneNumber.csv';
    }
  }
  
  // Get Sunday of current week
  static DateTime getSundayOfCurrentWeek() {
    final now = DateTime.now();
    
    // Using weekday % 7 gives us 0 for Sunday, so we can calculate correctly
    final daysFromSunday = now.weekday % 7;
    
    // Subtract the days from Sunday to get the Sunday of the current week
    return DateTime(now.year, now.month, now.day - daysFromSunday);
  }
  
  // Load bank holidays from JSON file
  static Future<List<BankHoliday>> loadBankHolidays() async {
    try {
      final jsonString = await rootBundle.loadString('assets/bank_holidays.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final List<dynamic> yearsData = jsonData['IrelandBankHolidays'];
      
      final List<BankHoliday> allHolidays = [];
      
      for (final yearData in yearsData) {
        final List<dynamic> holidays = yearData['holidays'];
        for (final holiday in holidays) {
          allHolidays.add(BankHoliday.fromJson(holiday));
        }
      }
      
      return allHolidays;
    } catch (e) {
      print('Error loading bank holidays: $e');
      return [];
    }
  }
  
  // Parse a shift row into ShiftData
  static ShiftData? parseShiftData(String csvLine) {
    if (csvLine.trim().isEmpty) return null;
    
    final parts = csvLine.split(',');
    if (parts.length < 16) return null;
    
    try {
      return ShiftData.fromList(parts);
    } catch (e) {
      print('Error parsing shift data: $e');
      return null;
    }
  }
}
