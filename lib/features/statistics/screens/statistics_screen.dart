import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spdrivercalendar/models/event.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:spdrivercalendar/features/calendar/services/roster_service.dart';
import 'package:spdrivercalendar/core/services/storage_service.dart';
import 'package:spdrivercalendar/core/constants/app_constants.dart';

// Import the new widgets
import '../widgets/frequency_chart.dart';
import '../widgets/shift_type_summary_card.dart';
import '../widgets/time_range_selector.dart';
import '../widgets/work_time_stats_card.dart';

enum ShiftType {
  Early,   // 04:00 - 09:59
  Relief,  // 10:00 - 13:59
  Late,    // 14:00 - 18:59
  Night,   // 19:00 - 03:59
  Bogey,   // Any duty with X suffix
  Spare,   // Spare duties
  UniEuro, // Duties starting with numbers/pattern
}

class StatisticsScreen extends StatefulWidget {
  final Map<DateTime, List<Event>> events;

  const StatisticsScreen({
    Key? key,
    required this.events,
  }) : super(key: key);

  @override
  StatisticsScreenState createState() => StatisticsScreenState();
}

class StatisticsScreenState extends State<StatisticsScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  
  String _timeRange = 'This Week';
  final List<String> _timeRanges = [
    'This Week', 
    'Last Week', 
    'This Month', 
    'Last Month', 
    'All Time'
  ];

  // Constants for work durations
  static const Duration spareDutyWorkDuration = Duration(hours: 7, minutes: 38);

  // Roster settings
  DateTime? _startDate;
  int _startWeek = 0;

  @override
  void initState() {
    super.initState();
    _loadRosterSettings();
  }

  Future<void> _loadRosterSettings() async {
    final startDateString = await StorageService.getString(AppConstants.startDateKey);
    final startWeek = await StorageService.getInt(AppConstants.startWeekKey) ?? 0;
    
    // Use mounted check before calling setState
    if (mounted) {
      setState(() {
        if (startDateString != null) {
          _startDate = DateTime.parse(startDateString);
        }
        _startWeek = startWeek;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shift Statistics'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Work Time Statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Break times and Rest Days not included in calculation',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),
            WorkTimeStatisticsCard(
              workTimeStatsFuture: _calculateWorkTimeStatistics(),
            ),
            const Divider(height: 32),
            
            const Text(
              'Shift Type Statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Rest Days not included in calculation',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),
            TimeRangeSelector(
              currentRange: _timeRange,
              availableRanges: _timeRanges,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _timeRange = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            ShiftTypeSummaryCard(stats: _calculateSummaryStatistics()),
            const Divider(height: 32),
            
            FrequencyChart(
              title: 'Most Frequent Shifts (Mon-Fri)',
              frequencyData: _getAllTimeFrequentShifts(),
              emptyDataMessage: 'No Mon-Fri shift data available',
            ),
            const Divider(height: 32),
            
            FrequencyChart(
              title: 'Most Frequent Buses (All Time)',
              frequencyData: _getMostFrequentBuses(),
              emptyDataMessage: 'No bus assignment data available',
            ),
          ],
        ),
      ),
    );
  }
  
  Map<String, int> _getAllTimeFrequentShifts() {
    Map<String, int> shiftCounts = {};
    Set<String> countedIds = {};
    
    widget.events.forEach((date, events) {
      for (final event in events) {
        // Only count shifts occurring Mon-Fri
        final dayOfWeek = event.startDate.weekday;
        if (dayOfWeek >= DateTime.monday && dayOfWeek <= DateTime.friday) {
          // Update to check for work shifts without "Shift:" prefix
          if (event.isWorkShift) {
            final shiftType = event.title;
            
            if (!countedIds.contains(event.id ?? '')) {
              countedIds.add(event.id ?? '');
              
              if (shiftCounts.containsKey(shiftType)) {
                shiftCounts[shiftType] = shiftCounts[shiftType]! + 1;
              } else {
                shiftCounts[shiftType] = 1;
              }
            }
          }
        }
      }
    });
    
    final sortedEntries = shiftCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return Map.fromEntries(sortedEntries);
  }

  Map<String, dynamic> _calculateSummaryStatistics() {
    final DateTime now = DateTime.now();
    DateTime startDate;
    DateTime endDate;
    
    // Determine date range based on selected time range
    switch (_timeRange) {
      case 'This Week':
        // Start from Sunday of current week
        final firstDayOfWeek = now.subtract(Duration(days: now.weekday % 7));
        startDate = DateTime(firstDayOfWeek.year, firstDayOfWeek.month, firstDayOfWeek.day);
        endDate = startDate.add(const Duration(days: 6));
        break;
      case 'Last Week':
        startDate = now.subtract(const Duration(days: 6));
        endDate = now;
        break;
      case 'This Month':
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 1);
        break;
      case 'Last Month':
        startDate = DateTime(now.year, now.month - 1, 1);
        endDate = DateTime(now.year, now.month, 1);
        break;
      case 'All Time':
      default:
        startDate = DateTime(2020, 1, 1); // Far past date
        endDate = DateTime(2030, 12, 31); // Far future date
        break;
    }
    
    // Initialize counters
    int totalShifts = 0;
    int earlyShifts = 0;
    int lateShifts = 0;
    int reliefShifts = 0;
    int nightShifts = 0;
    int spareShifts = 0;
    int bogeyShifts = 0;
    int bankHolidayShifts = 0;
    
    // Track processed event IDs to avoid counting duplicates
    final Set<String> processedIds = {};
    
    // Process events
    widget.events.forEach((date, events) {
      // Skip if this is a rest day based on roster
      final String shiftType = (_startDate != null) 
          ? RosterService.getShiftForDate(date, _startDate!, _startWeek)
          : ''; // Default to empty if roster not loaded
      final bool isRest = shiftType == 'R';
      
      if (isRest) return;

      for (final event in events) {
        // Only consider work shifts
        if (!event.isWorkShift) continue;
        
        // Skip if already processed
        if (processedIds.contains(event.id ?? '')) continue;
        
        // Check if event falls within the selected date range
        if (event.startDate.isAfter(startDate.subtract(const Duration(days: 1))) && 
            event.startDate.isBefore(endDate.add(const Duration(days: 1)))) {
          
          processedIds.add(event.id ?? '');
          totalShifts++;
          
          final shiftCode = event.title;
          
          // First check special shift types
          // Check if it's a Spare shift (starts with 'SP')
          if (shiftCode.startsWith('SP')) {
            spareShifts++;
            continue; // Skip further categorization
          }
          
          // Check if it's a Bogey shift (ends with 'X')
          if (shiftCode.endsWith('X')) {
            bogeyShifts++;
            continue; // Skip further categorization
          }
          
          // Now categorize by time of day if not already categorized
          final startHour = event.startTime.hour;
          
          // Early: 04:00 - 09:59
          if (startHour >= 4 && startHour < 10) {
            earlyShifts++;
          } 
          // Relief/Middle: 10:00 - 13:59
          else if (startHour >= 10 && startHour < 14) {
            reliefShifts++;
          } 
          // Late: 14:00 - 18:59
          else if (startHour >= 14 && startHour < 19) {
            lateShifts++;
          }
          // Night: 19:00 - 03:59
          else if (startHour >= 19 || startHour < 4) {
            nightShifts++;
          }
          
          // Bank holidays logic would go here
        }
      }
    });
    
    // Format date range for display
    final dateRangeStr = '${DateFormat('dd/MM/yy').format(startDate)} - ${DateFormat('dd/MM/yy').format(endDate)}';
    
    return {
      'totalShifts': totalShifts,
      'earlyShifts': earlyShifts,
      'lateShifts': lateShifts,
      'reliefShifts': reliefShifts,
      'nightShifts': nightShifts,
      'spareShifts': spareShifts,
      'bogeyShifts': bogeyShifts,
      'bankHolidayShifts': bankHolidayShifts,
      'dateRange': dateRangeStr,
    };
  }

  Future<Duration> _calculateWorkTime(Event event) async {
    if (!event.isWorkShift) return Duration.zero;

    // For spare duties (fixed 7h 38m)
    if (event.title.startsWith('SP')) {
      return const Duration(hours: 7, minutes: 38);
    }

    // For all other duties, try to get work time from CSV
    final dayOfWeek = await _getDayOfWeek(event.startDate);
    final workTime = await _loadWorkTimeFromCSV(event.title, dayOfWeek);
    
    if (workTime != null) {
      return workTime;
    }

    // Fallback to calculating from start/end times if CSV lookup fails
    final start = DateTime(
      event.startDate.year,
      event.startDate.month,
      event.startDate.day,
      event.startTime.hour,
      event.startTime.minute,
    );
    
    var end = DateTime(
      event.endDate.year,
      event.endDate.month,
      event.endDate.day,
      event.endTime.hour,
      event.endTime.minute,
    );

    if (end.isBefore(start)) {
      end = end.add(const Duration(days: 1));
    }

    return end.difference(start);
  }

  Future<Duration?> _loadWorkTimeFromCSV(String shiftCode, String dayOfWeek) async {
    try {
      String fileName;
      
      // Handle different duty types
      if (shiftCode.startsWith('PZ1')) {
        fileName = '${dayOfWeek}_DUTIES_PZ1.csv';
        print('Loading PZ1 shift $shiftCode from $fileName (dayOfWeek: $dayOfWeek)');
      } else if (shiftCode.startsWith('PZ4')) {
        fileName = '${dayOfWeek}_DUTIES_PZ4.csv';
      } else if (shiftCode.startsWith('807')) {
        fileName = 'UNI_7DAYs.csv';
      } else {
        return null;
      }

      print('Loading work time for $shiftCode from $fileName');
      final csvData = await rootBundle.loadString('assets/$fileName');
      final lines = csvData.split('\n');
      
      for (final line in lines) {
        final parts = line.split(',');
        if (parts[0] == shiftCode && parts.length > 14) {
          final workTimeStr = parts[14].trim();
          print('Found matching shift code in $fileName');
          print('Parsing break time from parts: ${parts.join(', ')}');
          final timeParts = workTimeStr.split(':');
          if (timeParts.length >= 2) {
            final duration = Duration(
              hours: int.parse(timeParts[0]),
              minutes: int.parse(timeParts[1])
            );
            print('Work time for $shiftCode: ${duration.inHours}:${(duration.inMinutes % 60).toString().padLeft(2, '0')}');
            return duration;
          }
        }
      }
    } catch (e) {
      print('Error loading work time from CSV: $e');
    }
    return null;
  }

  Future<String> _getDayOfWeek(DateTime date) async {
    // First check if it's a Bank Holiday
    if (await isBankHoliday(date)) {
      return 'SUN';  // Bank Holidays use Sunday duty times
    }
    
    // Then check regular weekdays
    switch (date.weekday) {
      case DateTime.monday:
        return 'M-F';
      case DateTime.tuesday:
        return 'M-F';
      case DateTime.wednesday:
        return 'M-F';
      case DateTime.thursday:
        return 'M-F';
      case DateTime.friday:
        return 'M-F';
      case DateTime.saturday:
        return 'SAT';
      case DateTime.sunday:
        return 'SUN';
      default:
        return 'M-F';
    }
  }

  Future<bool> isBankHoliday(DateTime date) async {
    try {
      final bankHolidaysData = await rootBundle.loadString('assets/bank_holidays.json');
      final bankHolidays = json.decode(bankHolidaysData);
      
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      // Find the year entry
      final yearEntry = (bankHolidays['IrelandBankHolidays'] as List)
          .firstWhere((entry) => entry['year'] == date.year, orElse: () => null);
      
      if (yearEntry == null) return false;
      
      // Check if the date is in the holidays list
      return (yearEntry['holidays'] as List)
          .any((holiday) => holiday['date'] == dateStr);
    } catch (e) {
      print('Error checking bank holiday: $e');
      return false;
    }
  }

  Future<Map<String, Duration>> _calculateWorkTimeStatistics() async {
    final now = DateTime.now();
    
    // This week (Sunday to Saturday)
    final thisWeekStart = now.subtract(Duration(days: now.weekday % 7));
    final thisWeekEnd = thisWeekStart.add(const Duration(days: 6)); // Changed from 7 to 6 to end on Saturday
    
    // Last week (previous Sunday to Saturday)
    final lastWeekEnd = thisWeekStart.subtract(const Duration(days: 1)); // End on previous Saturday
    final lastWeekStart = lastWeekEnd.subtract(const Duration(days: 6)); // Start on previous Sunday
    
    print('Last week range: ${lastWeekStart.toString()} to ${lastWeekEnd.toString()}');

    // This month
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final thisMonthEnd = (now.month < 12)
      ? DateTime(now.year, now.month + 1, 1)
      : DateTime(now.year + 1, 1, 1);
    
    // Last month
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    final lastMonthEnd = thisMonthStart;

    Duration thisWeekWork = Duration.zero;
    Duration lastWeekWork = Duration.zero;
    Duration thisMonthWork = Duration.zero;
    Duration lastMonthWork = Duration.zero;
    Duration totalWork = Duration.zero;

    Set<String> processedIds = {};

    for (final entry in widget.events.entries) {
      final date = entry.key;
      final events = entry.value;
      
      // Normalize the date to midnight for rest day comparison
      final normalizedDate = DateTime(date.year, date.month, date.day);
      
      // Skip if this is a rest day based on roster
      final String shiftType = (_startDate != null) 
          ? RosterService.getShiftForDate(date, _startDate!, _startWeek)
          : ''; // Default to empty if roster not loaded
      final bool isRest = shiftType == 'R';
      
      if (isRest) continue;

      for (final event in events) {
        if (!event.isWorkShift || processedIds.contains(event.id)) continue;
        processedIds.add(event.id ?? '');

        final workTime = await _calculateWorkTime(event);
        print('Shift: ${event.title} on ${normalizedDate.toString()} - Work time: ${workTime.inHours}:${(workTime.inMinutes % 60).toString().padLeft(2, '0')}');
        totalWork += workTime;

        // Check each period independently since a shift could be counted in multiple periods
        // (e.g., both this week and this month)
        if (normalizedDate.isAfter(thisWeekStart.subtract(const Duration(days: 1))) && 
            normalizedDate.isBefore(thisWeekEnd.add(const Duration(days: 1)))) {
          thisWeekWork += workTime;
        }
        
        // For last week, use exact date comparisons
        if (normalizedDate.isAtSameMomentAs(lastWeekStart) || 
            (normalizedDate.isAfter(lastWeekStart) && normalizedDate.isBefore(lastWeekEnd)) ||
            normalizedDate.isAtSameMomentAs(lastWeekEnd)) {
          lastWeekWork += workTime;
          print('Adding to last week: ${event.title} - ${workTime.inHours}:${(workTime.inMinutes % 60).toString().padLeft(2, '0')}');
        }
        
        if (normalizedDate.isAfter(thisMonthStart.subtract(const Duration(days: 1))) && 
            normalizedDate.isBefore(thisMonthEnd)) {
          thisMonthWork += workTime;
        }
        
        if (normalizedDate.isAfter(lastMonthStart.subtract(const Duration(days: 1))) && 
            normalizedDate.isBefore(lastMonthEnd)) {
          lastMonthWork += workTime;
        }
      }
    }

    print('Final last week total: ${lastWeekWork.inHours}:${(lastWeekWork.inMinutes % 60).toString().padLeft(2, '0')}');

    // Calculate average weekly work time based on actual weeks with shifts
    final totalWeeks = processedIds.length / 5; // Assuming 5 shifts per week on average
    final averageWeekly = totalWeeks > 0 
      ? Duration(minutes: (totalWork.inMinutes / totalWeeks).round())
      : Duration.zero;

    return {
      'thisWeek': thisWeekWork,
      'lastWeek': lastWeekWork,
      'thisMonth': thisMonthWork,
      'lastMonth': lastMonthWork,
      'averageWeekly': averageWeekly,
      'total': totalWork,
    };
  }

  Map<String, int> _getMostFrequentBuses() {
    Map<String, int> busCounts = {};
    
    widget.events.forEach((date, events) {
      for (final event in events) {
        // Count first half bus
        if (event.firstHalfBus != null) {
          if (busCounts.containsKey(event.firstHalfBus!)) {
            busCounts[event.firstHalfBus!] = busCounts[event.firstHalfBus!]! + 1;
          } else {
            busCounts[event.firstHalfBus!] = 1;
          }
        }
        
        // Count second half bus
        if (event.secondHalfBus != null) {
          if (busCounts.containsKey(event.secondHalfBus!)) {
            busCounts[event.secondHalfBus!] = busCounts[event.secondHalfBus!]! + 1;
          } else {
            busCounts[event.secondHalfBus!] = 1;
          }
        }
      }
    });
    
    // Sort by frequency (highest to lowest)
    final sortedEntries = busCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return Map.fromEntries(sortedEntries);
  }
}
