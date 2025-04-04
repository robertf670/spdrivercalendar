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
  })
      : super(key: key);

  @override
  StatisticsScreenState createState() => StatisticsScreenState();
}

class StatisticsScreenState extends State<StatisticsScreen> 
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
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

  // State for bus frequency display
  int _numberOfBusesToShow = 3;
  final List<int> _busNumberOptions = [3, 5, 10];

  // State for shift frequency display
  int _numberOfShiftsToShow = 3;
  final List<int> _shiftNumberOptions = [3, 5, 10]; // Can reuse or define separately

  // Cache for parsed CSV data: Key = filename, Value = Map<ShiftCode, Duration>
  final Map<String, Map<String, Duration>> _csvWorkTimeCache = {};

  // Constants for work durations
  static const Duration spareDutyWorkDuration = Duration(hours: 7, minutes: 38);

  // Roster settings
  DateTime? _startDate;
  int _startWeek = 0;

  // State variable to hold the future for work time stats
  Future<Map<String, Duration>>? _workTimeStatsFuture;

  // Tab Controller - Make nullable
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    // Ensure TabController length is 3
    _tabController = TabController(length: 3, vsync: this);
    _initializeStatistics();
  }

  @override
  void didUpdateWidget(covariant StatisticsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.events != oldWidget.events) {
      _workTimeStatsFuture = _calculateWorkTimeStatistics();
    }
  }

  @override
  void dispose() {
    // Dispose TabController
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _initializeStatistics() async {
    await _loadRosterSettings();
    if (mounted) {
       setState(() {
         _workTimeStatsFuture = _calculateWorkTimeStatistics();
       });
    }
  }

  Future<void> _loadRosterSettings() async {
    final startDateString = await StorageService.getString(AppConstants.startDateKey);
    final startWeek = await StorageService.getInt(AppConstants.startWeekKey) ?? 0;
    
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
    
    // Check if TabController is initialized
    if (_tabController == null) {
      // Return a loading indicator or empty container until initialized
      return Scaffold(
        appBar: AppBar(title: Text('Shift Statistics')), // Keep AppBar for consistency
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Proceed with the build now that controller is guaranteed to be non-null
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shift Statistics'),
        // Add TabBar to the bottom of the AppBar
        bottom: TabBar(
          controller: _tabController!, // Use null assertion
          indicatorColor: Colors.white, // Highlight selected tab indicator
          labelColor: Colors.white, // Color for selected tab label
          unselectedLabelColor: Colors.white70, // Slightly dimmer for unselected
          // Update tabs
          tabs: const [
            Tab(text: 'Work Time'),
            Tab(text: 'Summary'),
            Tab(text: 'Frequency'), // Combined tab
          ],
        ),
      ),
      // Use TabBarView for the body
      body: TabBarView(
        controller: _tabController!, // Use null assertion
        // Update children
        children: [
          _buildWorkTimeTab(),
          _buildSummaryTab(),
          _buildFrequencyTab(), // Use the new combined tab builder
        ],
      ),
    );
  }

  // --- Helper methods to build tab content --- 

  Widget _buildWorkTimeTab() {
    // Wrap content in SingleChildScrollView and Padding
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0), // Padding around the card
      child: Card( // Wrap content in a Card
        elevation: 2.0, // Add slight elevation
        child: Padding( // Add internal padding for card content
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
              _workTimeStatsFuture == null
                ? const Center(child: CircularProgressIndicator())
                : WorkTimeStatisticsCard(
                    workTimeStatsFuture: _workTimeStatsFuture!,
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Card( // Wrap content in a Card
        elevation: 2.0,
        child: Padding( // Add internal padding
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFrequencyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Card( 
        elevation: 2.0,
        child: Padding( 
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Shifts Section ---
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Most Frequent Shifts (Mon-Fri)',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    DropdownButton<int>(
                      value: _numberOfShiftsToShow,
                      items: _shiftNumberOptions.map((int value) {
                        return DropdownMenuItem<int>(
                          value: value,
                          child: Text('Top $value'),
                        );
                      }).toList(),
                      onChanged: (int? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _numberOfShiftsToShow = newValue;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              FrequencyChart(
                title: '', 
                frequencyData: Map.fromEntries(
                   _getAllTimeFrequentShifts().entries.take(_numberOfShiftsToShow)
                ),
                emptyDataMessage: 'No Mon-Fri shift data available',
              ),

              // Divider between sections
              const Divider(height: 32, thickness: 1, indent: 16, endIndent: 16),

              // --- Buses Section ---
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0, top: 16.0), // Add top padding for separation
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Most Frequent Buses (All Time)',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    DropdownButton<int>(
                      value: _numberOfBusesToShow,
                      items: _busNumberOptions.map((int value) {
                        return DropdownMenuItem<int>(
                          value: value,
                          child: Text('Top $value'),
                        );
                      }).toList(),
                      onChanged: (int? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _numberOfBusesToShow = newValue;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              FrequencyChart(
                title: '',
                frequencyData: Map.fromEntries(
                  _getMostFrequentBuses().entries.take(_numberOfBusesToShow)
                ),
                emptyDataMessage: 'No bus assignment data available',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Keep all calculation logic below --- 

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
    String fileName = ''; // Declare fileName outside the try block
    try {
      // String fileName; // Remove declaration from inside

      // Handle different duty types
      if (shiftCode.startsWith('PZ1')) {
        fileName = '${dayOfWeek}_DUTIES_PZ1.csv';
      } else if (shiftCode.startsWith('PZ4')) {
        fileName = '${dayOfWeek}_DUTIES_PZ4.csv';
      } else if (shiftCode.startsWith('807')) {
        fileName = 'UNI_7DAYs.csv';
      } else {
        return null; // Not a known CSV-based duty type
      }

      // 1. Check cache first
      if (_csvWorkTimeCache.containsKey(fileName)) {
        final cachedFile = _csvWorkTimeCache[fileName]!;
        if (cachedFile.containsKey(shiftCode)) {
          // print('Cache hit for $shiftCode in $fileName'); // Optional: debug logging
          return cachedFile[shiftCode];
        } else {
          // File is cached, but shift code isn't in it (might be invalid shift code for that file)
          // print('Shift code $shiftCode not found in cached $fileName'); // Optional: debug logging
          return null;
        }
      }

      // 2. If not in cache, load and parse the file
      // print('Cache miss for $fileName. Loading and parsing...'); // Optional: debug logging
      final csvData = await rootBundle.loadString('assets/$fileName');
      final lines = csvData.split('\n');
      final Map<String, Duration> parsedDurations = {};

      for (final line in lines) {
        // Skip empty lines or headers if necessary (adjust condition if header exists)
        if (line.trim().isEmpty) continue;

        final parts = line.split(',');
        // Ensure sufficient parts and the first part is the shift code we might need
        if (parts.isNotEmpty && parts.length > 14) {
           final currentShiftCode = parts[0].trim();
           final workTimeStr = parts[14].trim();
           // print('Parsing line: $line'); // Optional: Debug line parsing
           // print('ShiftCode: $currentShiftCode, WorkTimeStr: $workTimeStr');

           final timeParts = workTimeStr.split(':');
           if (timeParts.length >= 2) {
            try {
              final duration = Duration(
                hours: int.parse(timeParts[0]),
                minutes: int.parse(timeParts[1])
              );
              parsedDurations[currentShiftCode] = duration;
              // print('Parsed duration for $currentShiftCode: $duration');
             } catch (e) {
               print('Error parsing duration for shift $currentShiftCode in $fileName: $e, Line: $line');
             }
           } else {
             // print('Skipping line due to incorrect time format: $line');
           }
        } else {
           // print('Skipping line due to insufficient parts: $line');
        }
      }

      // 3. Store the parsed data in the cache
      _csvWorkTimeCache[fileName] = parsedDurations;
      // print('Cached data for $fileName. Size: ${parsedDurations.length}'); // Optional: debug logging

      // 4. Return the requested duration from the now-cached data
      if (parsedDurations.containsKey(shiftCode)) {
         return parsedDurations[shiftCode];
      } else {
         // Shift code not found even after parsing the file
         // print('Shift code $shiftCode not found in newly parsed $fileName'); // Optional: debug logging
         return null;
      }

    } catch (e) {
      // fileName is now accessible here
      print('Error loading or parsing work time from CSV ($fileName): $e');
      // Handle file not found or other errors gracefully
      return null; // Return null if any error occurs during loading/parsing
    }
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
    final thisWeekStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday % 7)); // Ensure start is at midnight
    final thisWeekEnd = DateTime(thisWeekStart.year, thisWeekStart.month, thisWeekStart.day).add(const Duration(days: 6)); // Ensure end is at start of day

    // Last week (previous Sunday to Saturday)
    final lastWeekEnd = DateTime(thisWeekStart.year, thisWeekStart.month, thisWeekStart.day).subtract(const Duration(days: 1)); // End on previous Saturday (start of day)
    final lastWeekStart = DateTime(lastWeekEnd.year, lastWeekEnd.month, lastWeekEnd.day).subtract(const Duration(days: 6)); // Start on previous Sunday (start of day)

    // --- Re-add Month Definitions --- 
    // This month
    final thisMonthStart = DateTime(now.year, now.month, 1);
    // End is the start of the *next* month
    final thisMonthEnd = (now.month < 12)
        ? DateTime(now.year, now.month + 1, 1)
        : DateTime(now.year + 1, 1, 1);

    // Last month
    // Start is the start of the previous month
    final lastMonthStart = (now.month > 1)
        ? DateTime(now.year, now.month - 1, 1)
        : DateTime(now.year - 1, 12, 1);
    // End is the start of *this* month
    final lastMonthEnd = thisMonthStart;
    // --- End Re-add --- 

    Duration thisWeekWork = Duration.zero;
    Duration lastWeekWork = Duration.zero;
    Duration thisMonthWork = Duration.zero;
    Duration lastMonthWork = Duration.zero;
    Duration totalWork = Duration.zero;

    Set<String> processedIds = {};

    for (final entry in widget.events.entries) {
      final date = entry.key; // This date is likely already normalized from EventService
      final events = entry.value;

      // Use the date from the event entry key, assuming it's midnight UTC or similar
      final normalizedDate = DateTime.utc(date.year, date.month, date.day);

      // Skip if this is a rest day based on roster
      final String shiftType = (_startDate != null)
          ? RosterService.getShiftForDate(normalizedDate, _startDate!, _startWeek)
          : ''; // Default to empty if roster not loaded
      final bool isRest = shiftType == 'R';

      if (isRest) {
         continue;
      }

      for (final event in events) {
        // Use event.startDate for checks, normalized to UTC midnight
        final eventNormalizedStartDate = DateTime.utc(event.startDate.year, event.startDate.month, event.startDate.day);
        
        if (!event.isWorkShift || processedIds.contains(event.id)) {
            continue;
        }
        processedIds.add(event.id ?? '');

        final workTime = await _calculateWorkTime(event);

        totalWork += workTime;

        // Check This Week (Inclusive Check: >= start AND <= end)
        // Use event's normalized start date for comparisons
        if (!eventNormalizedStartDate.isBefore(thisWeekStart) && !eventNormalizedStartDate.isAfter(thisWeekEnd)) {
          thisWeekWork += workTime;
        }

        // Check Last Week (Inclusive Check: >= start AND <= end)
        if (!eventNormalizedStartDate.isBefore(lastWeekStart) && !eventNormalizedStartDate.isAfter(lastWeekEnd)) {
          lastWeekWork += workTime;
        }

        // Check This Month (Inclusive Start, Exclusive End: >= start AND < end)
        if (!eventNormalizedStartDate.isBefore(thisMonthStart) && eventNormalizedStartDate.isBefore(thisMonthEnd)) {
          thisMonthWork += workTime;
        }

        // Check Last Month (Inclusive Start, Exclusive End: >= start AND < end)
        if (!eventNormalizedStartDate.isBefore(lastMonthStart) && eventNormalizedStartDate.isBefore(lastMonthEnd)) {
          lastMonthWork += workTime;
        }
      }
    }

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
