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
    // Normalize both dates to midnight UTC for consistent comparison
    final normalizedDate = DateTime.utc(date.year, date.month, date.day);
    final normalizedStartDate = DateTime.utc(startDate.year, startDate.month, startDate.day);

    // Get the day of week (0 = Sunday, 6 = Saturday) - Use normalized date
    final dayOfWeek = normalizedDate.weekday % 7; // Sunday will be 0, Monday 1, etc.

    // Calculate how many days have passed since the start date - Use normalized dates
    final daysSinceStart = normalizedDate.difference(normalizedStartDate).inDays;

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
      // Calculate Sundays using normalized dates
      final dateSunday = normalizedDate.subtract(Duration(days: dayOfWeek));
      final startDateSunday = normalizedStartDate.subtract(Duration(days: normalizedStartDate.weekday % 7));

      if (dateSunday == startDateSunday) {
        // We're in the same week as the start date, use the same week number
        weekNumber = startWeek;
      } else {
        // We're in a previous week
        // Calculate how many complete weeks we're going back - Use normalized Sundays
        final sundayDiff = startDateSunday.difference(dateSunday).inDays ~/ 7;
        weekNumber = (startWeek - sundayDiff + 5) % 5;
      }
    }

    // Get the shift pattern for this week
    final pattern = getShiftPattern(weekNumber, '1'); // Using Zone 1 as default

    // Get the shift for this day
    final shift = pattern[dayOfWeek];



    // if (daysSinceStart >= 0) {

    // } else {
    //   final dateSunday = normalizedDate.subtract(Duration(days: dayOfWeek));
    //   final startDateSunday = normalizedStartDate.subtract(Duration(days: normalizedStartDate.weekday % 7));
    //   if (dateSunday == startDateSunday) {

    //   } else {
    //     final sundayDiff = startDateSunday.difference(dateSunday).inDays ~/ 7;

    //   }
    // }


    return shift;
  }
  
  // Helper method to check if a date should run Saturday service
  // These are special dates that run Saturday service, but NOT if they fall on a Sunday
  static bool isSaturdayService(DateTime date) {
    final month = date.month;
    final day = date.day;
    final weekday = date.weekday; // 1=Monday, 7=Sunday
    
    // December 24, 27, 29, 30, 31 run Saturday service, but NOT if they're on a Sunday
    if (month == 12 && (day == 24 || day == 27 || day == 29 || day == 30 || day == 31)) {
      // Don't show Saturday service if it's actually a Sunday
      if (weekday == DateTime.sunday) {
        return false;
      }
      return true;
    }
    
    return false;
  }
  
  // Helper method to determine the day of week string
  static String getDayOfWeek(DateTime date) {
    // Check if this date should run Saturday service
    if (isSaturdayService(date)) {
      return 'Saturday';
    }
    
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
    
    // Check if this date should run Saturday service (takes precedence over bank holiday)
    // Special dates like Dec 29-31 run Saturday service even if they're bank holidays
    final isSaturdayServiceDate = isSaturdayService(date);
    
    // Zone 4 Route 23/24 changeover date: October 19, 2025
    final route2324ChangeoverDate = DateTime(2025, 10, 19);
    final isZone4NewSchedule = zoneNumber == '4' && !date.isBefore(route2324ChangeoverDate);
    
    // For Zone 4 on or after October 19, 2025, use Route 23/24 files
    if (isZone4NewSchedule) {
      if (isSaturdayServiceDate || dayOfWeek == 'SAT') {
        return 'SAT_ROUTE2324.csv';
      } else if (isBankHoliday || dayOfWeek == 'SUN') {
        return 'SUN_ROUTE2324.csv';
      } else {
        return 'M-F_ROUTE2324.csv';
      }
    }
    
    // For all other zones and Zone 4 before October 19, 2025, use legacy files
    // Determine the correct PZ filename suffix based on the zone number
    String pzFileSuffix = 'PZ$zoneNumber';
    
    // Basic validation - check if zoneNumber is one of the known zones (1, 2, 3, 4)
    if (!['1', '2', '3', '4'].contains(zoneNumber)) {

        // Keep using the potentially incorrect suffix, assuming the file might exist unexpectedly
        // or allow the file load to fail naturally later.
    }
    
    // Saturday service dates take precedence over bank holidays
    if (isSaturdayServiceDate || dayOfWeek == 'SAT') {
      return 'SAT_DUTIES_$pzFileSuffix.csv';
    } else if (isBankHoliday || dayOfWeek == 'SUN') {
      // Use Sunday duties for bank holidays, with the direct PZ suffix
      return 'SUN_DUTIES_$pzFileSuffix.csv';
    } else {
      return 'M-F_DUTIES_$pzFileSuffix.csv';
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

      return null;
    }
  }

  // --- Zone 1 M-F 12-week roster (fixed duties) ---
  static List<String>? _zone1MFWeeklyDuties;
  static Map<String, int>? _zone1MFDutyToWeekIndex;

  /// Load Zone 1 M-F 12-week roster from assets. Returns true if loaded successfully.
  static Future<bool> loadZone1MFRoster() async {
    try {
      final jsonString = await rootBundle.loadString('assets/zone1_mf_12week_roster.json');
      final Map<String, dynamic> data = json.decode(jsonString);
      final List<dynamic> weeks = data['weeks'] as List<dynamic>;
      _zone1MFWeeklyDuties = weeks
          .map((w) => (w as Map<String, dynamic>)['dutyCode'] as String)
          .toList();
      final Map<String, dynamic> dutyToWeek = data['dutyToWeekIndex'] as Map<String, dynamic>;
      _zone1MFDutyToWeekIndex = dutyToWeek.map((k, v) => MapEntry(k, v as int));
      return true;
    } catch (e) {
      _zone1MFWeeklyDuties = null;
      _zone1MFDutyToWeekIndex = null;
      return false;
    }
  }

  /// Check if a duty code is in the Zone 1 M-F 12-week roster.
  static bool isZone1MFDutyInRoster(String dutyCode) {
    if (_zone1MFDutyToWeekIndex == null) return false;
    return _zone1MFDutyToWeekIndex!.containsKey(dutyCode);
  }

  /// Get the 0-based week index (0-11) for a duty code in the Zone 1 M-F roster. Returns null if not in roster.
  static int? getZone1MFWeekIndex(String dutyCode) {
    return _zone1MFDutyToWeekIndex?[dutyCode];
  }

  /// Get the duty code for a given week index (0-11) in the Zone 1 M-F roster.
  static String? getZone1MFDutyForWeekIndex(int weekIndex) {
    if (_zone1MFWeeklyDuties == null || weekIndex < 0 || weekIndex >= _zone1MFWeeklyDuties!.length) {
      return null;
    }
    return _zone1MFWeeklyDuties![weekIndex];
  }

  /// Get the Monday of the week containing the given date (week starts Sunday).
  static DateTime getMondayOfWeek(DateTime date) {
    final weekday = date.weekday; // 1=Mon, 7=Sun
    final daysToMonday = weekday == 7 ? 6 : weekday - 1; // Sun -> 6 days back
    return DateTime(date.year, date.month, date.day - daysToMonday);
  }

  /// Get the Sunday of the week containing the given date (week starts Sunday).
  static DateTime getSundayOfWeek(DateTime date) {
    final weekday = date.weekday; // 1=Mon, 7=Sun
    final daysToSunday = weekday == 7 ? 0 : weekday; // Sun=0, Mon=1, ..., Sat=6
    return DateTime(date.year, date.month, date.day - daysToSunday);
  }

  // --- Zone 1 Shift 86-week roster (variable rest days per week) ---
  static List<List<String>>? _zone1ShiftWeeks;
  static Map<String, int>? _zone1ShiftLookup; // key: "dayIndex_dutyCode" -> weekIndex (0-based)

  /// Load Zone 1 Shift 86-week roster from assets. Returns true if loaded successfully.
  static Future<bool> loadZone1ShiftRoster() async {
    try {
      final jsonString = await rootBundle.loadString('assets/zone1_shift_86week_roster.json');
      final Map<String, dynamic> data = json.decode(jsonString);
      final List<dynamic> weeks = data['weeks'] as List<dynamic>;
      _zone1ShiftWeeks = weeks
          .map((w) => (w as Map<String, dynamic>)['days'] as List<dynamic>)
          .map((d) => d.map((e) => e.toString()).toList())
          .toList();
      _zone1ShiftLookup = {};
      for (int wi = 0; wi < _zone1ShiftWeeks!.length; wi++) {
        final days = _zone1ShiftWeeks![wi];
        for (int di = 0; di < days.length; di++) {
          final duty = days[di];
          if (duty != 'R') {
            final key = '${di}_$duty';
            if (!_zone1ShiftLookup!.containsKey(key)) {
              _zone1ShiftLookup![key] = wi;
            }
          }
        }
      }
      return true;
    } catch (e) {
      _zone1ShiftWeeks = null;
      _zone1ShiftLookup = null;
      return false;
    }
  }

  /// Get 0-based roster week index for (dayIndex, dutyCode). Returns null if no match.
  /// dayIndex: 0=Sunday, 1=Monday, ..., 6=Saturday.
  static int? getZone1ShiftWeekIndex(int dayIndex, String dutyCode) {
    return _zone1ShiftLookup?['${dayIndex}_$dutyCode'];
  }

  /// Get duty for a day: "R" or "PZ1/XX". Returns null if invalid.
  static String? getZone1ShiftDayDuty(int weekIndex, int dayIndex) {
    if (_zone1ShiftWeeks == null ||
        weekIndex < 0 ||
        weekIndex >= _zone1ShiftWeeks!.length ||
        dayIndex < 0 ||
        dayIndex >= 7) {
      return null;
    }
    return _zone1ShiftWeeks![weekIndex][dayIndex];
  }

  /// Check if (dayIndex, dutyCode) exists in the Zone 1 Shift roster.
  static bool isZone1ShiftDutyInRosterForDay(int dayIndex, String dutyCode) {
    return getZone1ShiftWeekIndex(dayIndex, dutyCode) != null;
  }

  // --- Zone 3 Shift 10-week roster (L58/59, variable rest days per week) ---
  static List<List<String>>? _zone3ShiftWeeks;
  static Map<String, int>? _zone3ShiftLookup; // key: "dayIndex_dutyCode" -> weekIndex (0-based)

  /// Load Zone 3 Shift 10-week roster from assets. Returns true if loaded successfully.
  static Future<bool> loadZone3ShiftRoster() async {
    try {
      final jsonString = await rootBundle.loadString('assets/zone3_shift_10week_roster.json');
      final Map<String, dynamic> data = json.decode(jsonString);
      final List<dynamic> weeks = data['weeks'] as List<dynamic>;
      _zone3ShiftWeeks = weeks
          .map((w) => (w as Map<String, dynamic>)['days'] as List<dynamic>)
          .map((d) => d.map((e) => e.toString()).toList())
          .toList();
      _zone3ShiftLookup = {};
      for (int wi = 0; wi < _zone3ShiftWeeks!.length; wi++) {
        final days = _zone3ShiftWeeks![wi];
        for (int di = 0; di < days.length; di++) {
          final duty = days[di];
          if (duty != 'R') {
            final key = '${di}_$duty';
            if (!_zone3ShiftLookup!.containsKey(key)) {
              _zone3ShiftLookup![key] = wi;
            }
          }
        }
      }
      return true;
    } catch (e) {
      _zone3ShiftWeeks = null;
      _zone3ShiftLookup = null;
      return false;
    }
  }

  /// Get 0-based roster week index for (dayIndex, dutyCode). Returns null if no match.
  static int? getZone3ShiftWeekIndex(int dayIndex, String dutyCode) {
    return _zone3ShiftLookup?['${dayIndex}_$dutyCode'];
  }

  /// Get duty for a day: "R" or "PZ3/XX". Returns null if invalid.
  static String? getZone3ShiftDayDuty(int weekIndex, int dayIndex) {
    if (_zone3ShiftWeeks == null ||
        weekIndex < 0 ||
        weekIndex >= _zone3ShiftWeeks!.length ||
        dayIndex < 0 ||
        dayIndex >= 7) {
      return null;
    }
    return _zone3ShiftWeeks![weekIndex][dayIndex];
  }
}
