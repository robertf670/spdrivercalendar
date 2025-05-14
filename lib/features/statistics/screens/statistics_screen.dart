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
import '../widgets/break_statistics_card.dart';

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
  String _breakTimeRange = 'This Week';
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

  // State for start hour frequency display
  int _numberOfStartHoursToShow = 3;
  final List<int> _startHourNumberOptions = [3, 5, 10];

  // Cache for parsed CSV data: Key = filename, Value = Map<ShiftCode, Duration>
  final Map<String, Map<String, Duration>> _csvWorkTimeCache = {};

  // Constants for work durations
  static const Duration spareDutyWorkDuration = Duration(hours: 7, minutes: 38);

  // Roster settings
  DateTime? _startDate;
  int _startWeek = 0;

  // State variable to hold the future for work time stats
  Future<Map<String, Duration>>? _workTimeStatsFuture;

  // State variables for Sunday Pair Statistics
  DateTime? _currentBlockLsunDate, _currentBlockEsunDate;
  DateTime? _previousBlockLsunDate, _previousBlockEsunDate;
  // Replace duration/title lists with combined lists and totals
  List<Map<String, dynamic>> _currentBlockSundayShifts = [];
  List<Map<String, dynamic>> _previousBlockSundayShifts = [];
  Duration _currentBlockTotalSunHours = Duration.zero;
  Duration _previousBlockTotalSunHours = Duration.zero;
  bool _currentBlockLimitExceeded = false;
  bool _previousBlockLimitExceeded = false;
  bool _sundayStatsLoading = true; // Loading indicator flag
  
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
    // Clear the cache on initialization to prevent stale data issues
    _csvWorkTimeCache.clear(); 
    
    await _loadRosterSettings();
    if (mounted) {
       setState(() {
         _workTimeStatsFuture = _calculateWorkTimeStatistics();
         // Trigger Sunday pair calculation (no need to await here, UI will update)
         _calculateSundayPairStatistics(); 
       });
    }
  }

  @override
  Widget build(BuildContext context) {
    // REMOVE BASIC PRINT TEST
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
            Tab(text: 'Shift Summary'),
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
    // Format helper for duration
    String formatDuration(Duration d) {
      if (d == Duration.zero) return "0h 0m";
      final hours = d.inHours;
      final minutes = d.inMinutes.remainder(60);
      return "${hours}h ${minutes}m";
    }

    // Max duration: 14.5 hours = 870 minutes
    const maxSundayMinutes = 870;

    // Date formatter
    final DateFormat listTitleDateFormatter = DateFormat('MMM d'); // For ListTile title
    final DateFormat detailDateFormatter = DateFormat('dd/MM/yy'); // For detail lines

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0), // Padding around the card
      child: Column( // Use Column to allow multiple Cards/Widgets
        children: [
          Card( // Card for standard work time stats
            elevation: 2.0, 
            child: Padding( 
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
          const SizedBox(height: 16), // Spacing between cards
          // Card for Sunday Pair Statistics
          Card(
            elevation: 2.0,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rostered Sunday Pair Hours',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sum of hours worked on specific rostered Late & Early Sundays (Max 14h 30m)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Entitled to overtime if time is more than 14h 30m. If the second Sunday has not happened yet, and the time is more than 14h 30m, you have the right to finish in the garage',
                     style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const Divider(height: 24),
                  if (_sundayStatsLoading)
                    const Center(child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: CircularProgressIndicator(),
                    ))
                  else ...[
                    // Current Block Display
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Current Sundays' + 
                        ((_currentBlockLsunDate != null && _currentBlockEsunDate != null)
                         ? ' (${listTitleDateFormatter.format(_currentBlockLsunDate!)} + ${listTitleDateFormatter.format(_currentBlockEsunDate!)})'
                         : ''),
                        style: const TextStyle(fontWeight: FontWeight.bold)
                      ),
                      trailing: Text(
                        formatDuration(_currentBlockTotalSunHours), // Use total duration
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _currentBlockLimitExceeded ? Theme.of(context).colorScheme.error : null,
                        ),
                      ),
                      leading: _currentBlockLimitExceeded 
                        ? Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.error) 
                        : Icon(Icons.check_circle_outline, color: Colors.green),
                      // Move shift details into the subtitle
                      subtitle: _currentBlockSundayShifts.isNotEmpty
                          ? Padding(
                              padding: const EdgeInsets.only(top: 4.0), // Add padding above details
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: _buildShiftDetailRows(_currentBlockSundayShifts, detailDateFormatter, formatDuration),
                              ),
                            )
                          : null, // No subtitle if no shifts
                    ),
                    
                    // Previous Block Display
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Previous Sundays' + 
                        ((_previousBlockLsunDate != null && _previousBlockEsunDate != null)
                         ? ' (${listTitleDateFormatter.format(_previousBlockLsunDate!)} + ${listTitleDateFormatter.format(_previousBlockEsunDate!)})'
                         : ''),
                        style: const TextStyle(fontWeight: FontWeight.bold)
                      ),
                      trailing: Text(
                        formatDuration(_previousBlockTotalSunHours), // Use total duration
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _previousBlockLimitExceeded ? Theme.of(context).colorScheme.error : null,
                        ),
                      ),
                      leading: _previousBlockLimitExceeded 
                        ? Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.error) 
                        : Icon(Icons.check_circle_outline, color: Colors.green),
                      // Move shift details into the subtitle
                      subtitle: _previousBlockSundayShifts.isNotEmpty
                          ? Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: _buildShiftDetailRows(_previousBlockSundayShifts, detailDateFormatter, formatDuration),
                              ),
                            )
                          : null, // No subtitle if no shifts
                    ),
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Shift Type Summary Card
          ShiftTypeSummaryCard(
            stats: _calculateSummaryStatistics(),
            currentRange: _timeRange,
            availableRanges: _timeRanges,
            onChanged: (newRange) {
              if (newRange != null) {
                setState(() {
                  _timeRange = newRange;
                });
              }
            },
          ),
          
          // Break Statistics Card
          BreakStatisticsCard(
            breakStats: _calculateBreakStatistics(),
            currentRange: _breakTimeRange,
            availableRanges: _timeRanges,
            onChanged: (newRange) {
              if (newRange != null) {
                setState(() {
                  _breakTimeRange = newRange;
                });
                print('Break stats time range changed to: $newRange'); // Debug
              }
            },
          ),
          
          // Work Time Stats Card
          // ... existing code ...
        ],
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
                      // Add styling for dark mode
                      style: const TextStyle(color: Colors.white), // Style for selected item text
                      iconEnabledColor: Colors.white70, // Arrow color
                      dropdownColor: Colors.grey[800], // Menu background color
                      items: _shiftNumberOptions.map((int value) {
                        return DropdownMenuItem<int>(
                          value: value,
                          // Ensure item text is readable
                          child: Text('Top $value', style: const TextStyle(color: Colors.white)),
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
                      // Add styling for dark mode
                      style: const TextStyle(color: Colors.white), // Style for selected item text
                      iconEnabledColor: Colors.white70, // Arrow color
                      dropdownColor: Colors.grey[800], // Menu background color
                      items: _busNumberOptions.map((int value) {
                        return DropdownMenuItem<int>(
                          value: value,
                          // Ensure item text is readable
                          child: Text('Top $value', style: const TextStyle(color: Colors.white)),
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
                frequencyData: Map.fromEntries(
                  _getMostFrequentBuses().entries.take(_numberOfBusesToShow)
                ),
                emptyDataMessage: 'No bus assignment data available',
              ),

              // --- Add Start Hour Frequency Chart --- 
              const Divider(height: 32, thickness: 1, indent: 16, endIndent: 16),
              
              // Add Row with Title and Dropdown
              Padding(
                padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                        'Most Frequent Start Hours',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    DropdownButton<int>(
                      value: _numberOfStartHoursToShow,
                      // Add styling for dark mode
                      style: const TextStyle(color: Colors.white), // Style for selected item text
                      iconEnabledColor: Colors.white70, // Arrow color
                      dropdownColor: Colors.grey[800], // Menu background color
                      items: _startHourNumberOptions.map((int value) {
                        return DropdownMenuItem<int>(
                          value: value,
                          // Ensure item text is readable
                          child: Text('Top $value', style: const TextStyle(color: Colors.white)),
                        );
                      }).toList(),
                      onChanged: (int? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _numberOfStartHoursToShow = newValue;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              // Move explanatory note here, below title/dropdown row
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0), // Add padding below note
                child: Text(
                  'Groups logged work shifts by their starting hour (e.g., 06:00-06:59).', // Updated explanation
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              FrequencyChart(
                frequencyData: Map.fromEntries(
                  _getMostFrequentStartHours().entries.take(_numberOfStartHoursToShow)
                ),
                emptyDataMessage: 'No shift start time data available',
              ),
              // --- End Start Hour Section ---

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
    int restDaysWorked = 0;
    
    // Track processed event IDs to avoid counting duplicates
    final Set<String> processedIds = {};
    
    // --- Refactored Processing Logic --- 
    widget.events.forEach((date, events) { // Iterate through all dates in the events map
      for (final event in events) { // Iterate through events on that date
        // Only consider work shifts
        if (!event.isWorkShift) continue;
        
        // Skip if already processed (handles cases where event might span midnight? Unlikely with current model but safe)
        if (processedIds.contains(event.id ?? '')) continue;
        
        // Check if event falls within the selected date range
        // Use event.startDate for the check
        if (!event.startDate.isBefore(startDate) && 
            event.startDate.isBefore(endDate.add(const Duration(days: 1)))) {
          
          processedIds.add(event.id ?? ''); // Mark as processed

          // Determine if this date was a rostered Rest Day
          final String rosterShiftType = (_startDate != null) 
              ? RosterService.getShiftForDate(event.startDate, _startDate!, _startWeek)
              : ''; // Default to empty if roster not loaded
          final bool isRest = rosterShiftType == 'R';

          if (isRest) {
            // If it was a rest day, just increment the specific counter
            restDaysWorked++;
          } else {
            // --- If NOT a rest day, proceed with original categorization --- 
            totalShifts++; // Increment total only for non-rest day shifts
            
            final shiftCode = event.title;
            
            // First check special shift types
            if (shiftCode.startsWith('SP')) {
              spareShifts++;
            } else if (shiftCode.endsWith('X')) {
              bogeyShifts++;
            } else {
              // Now categorize by time of day if not Spare or Bogey
              final startHour = event.startTime.hour;
              if (startHour >= 4 && startHour < 10) {
                earlyShifts++;
              } else if (startHour >= 10 && startHour < 14) {
                reliefShifts++;
              } else if (startHour >= 14 && startHour < 19) {
                lateShifts++;
              } else if (startHour >= 19 || startHour < 4) {
                nightShifts++;
              }
            }
            // Bank holidays logic would ideally be integrated here too if needed
            // Currently bankHolidayShifts is not being calculated.
          }
        }
      }
    });
    // --- End Refactored Logic --- 
    
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
      'restDaysWorked': restDaysWorked,
      'dateRange': dateRangeStr,
    };
  }

  Future<Duration> _calculateWorkTime(Event event) async {
    // REMOVE start-of-function log
    // print('[STAT DEBUG] Calculating work time for: ${event.title} on ${event.startDate.toIso8601String()}'); 

    if (!event.isWorkShift) {
       // REMOVE log
       // print('[STAT DEBUG] Not a work shift, returning zero.'); 
      return Duration.zero;
    }

    // For spare duties (fixed 7h 38m)
    if (event.title.startsWith('SP')) {
       // REMOVE log
       // print('[STAT DEBUG] Spare shift detected, returning fixed duration.'); 
      return const Duration(hours: 7, minutes: 38);
    }

    // For all other duties, rely on _loadWorkTimeFromCSV
    final dayOfWeek = await _getDayOfWeek(event.startDate);
    // REMOVE log
    // print('[STAT DEBUG] Determined dayOfWeek: $dayOfWeek for ${event.startDate.toIso8601String()}'); 
    final workTime = await _loadWorkTimeFromCSV(event, dayOfWeek);
    
    // If CSV lookup succeeds, return the duration
    if (workTime != null) {
       // REMOVE log
       // print('[STAT DEBUG] Found work time from CSV: ${workTime.inHours}h ${workTime.inMinutes.remainder(60)}m'); 
      return workTime;
    }
    
    // If CSV lookup fails (shift not found, file error, parsing error, etc.)
    // return Duration.zero instead of falling back to potentially inaccurate calculation.
    // Keep original warning for actual failures
    print('Warning: Could not determine work time for shift ${event.title} on ${event.startDate.toIso8601String()} (Day: $dayOfWeek) from CSV. Returning zero duration.');
    return Duration.zero;
  }

  Future<Duration?> _loadWorkTimeFromCSV(Event event, String dayOfWeek) async {
    String fileName = '';
    String shiftCode = ''; // Define shiftCode outside try block

    try {
      // Extract shift code and zone number from the event title
      shiftCode = event.title.replaceAll('Shift: ', '').trim(); // Assign here
      String zoneNumber = '1'; // Default
      bool isUniShift = false;
      bool isBusCheck = false;

      // Determine file type and zone
      if (shiftCode.startsWith('BusCheck')) {
        fileName = 'buscheck.csv';
        isBusCheck = true;
        // print('[STAT DEBUG Flow] Shift \'$shiftCode\' identified as BusCheck.');
      
      // Check for UNI using firstMatch with simplified regex
      } else if (RegExp(r'^\d+/').firstMatch(shiftCode) != null) { // Use \d+ (one or more digits)
        // print('[STAT DEBUG Flow] Shift \'$shiftCode\' identified as UNI.'); 
        isUniShift = true;
        
        // --- New UNI Logic with Fallback --- 
        String primaryFileName;
        String fallbackFileName;
        
        if (dayOfWeek == 'SUN' || dayOfWeek == 'SAT') {
           primaryFileName = 'UNI_7DAYs.csv';
           fallbackFileName = 'UNI_M-F.csv'; // Fallback unlikely needed but included
        } else {
           primaryFileName = 'UNI_M-F.csv';
           fallbackFileName = 'UNI_7DAYs.csv';
        }
        // print('[STAT DEBUG Flow] Determined UNI filenames: Primary=\'$primaryFileName\', Fallback=\'$fallbackFileName\'');
        
        // Try primary file first
        Duration? uniDuration = await _tryLoadUniShiftFromFile(shiftCode, primaryFileName);
        
        // If not found in primary, try fallback
        if (uniDuration == null) {
           // print('[STAT DEBUG Flow] Shift \'$shiftCode\' not found in primary UNI file ($primaryFileName). Trying fallback ($fallbackFileName).');
           uniDuration = await _tryLoadUniShiftFromFile(shiftCode, fallbackFileName);
        }
        
        // If found in either file, return the duration
        if (uniDuration != null) {
           // print('[STAT DEBUG Flow] Successfully found/parsed UNI shift \'$shiftCode\'. Duration: $uniDuration');
           return uniDuration;
        }
        
        // If not found in either, fall through to return null (handled after catch block)
        // print('[STAT DEBUG Flow] Shift \'$shiftCode\' not found in EITHER UNI file.');
        fileName = ''; // Set filename to empty to prevent PZ block execution & ensure null return
        // --- End New UNI Logic ---

      // Handle PZ shifts (if not BusCheck or UNI)
      } else {
        // print('[STAT DEBUG Flow] Shift \'$shiftCode\' falling through to PZ block.');
        // print('[STAT DEBUG PZ Block] Entered for shiftCode: \'$shiftCode\'. Default zoneNumber: \'$zoneNumber\'');
        final match = RegExp(r'PZ(\d+)/').firstMatch(shiftCode);
        if (match != null) {
          // print('[STAT DEBUG PZ Block] RegExp matched! Groups: ${match.groups([0, 1])}');
          zoneNumber = match.group(1) ?? '1';
          // print('[STAT DEBUG PZ Block] Updated zoneNumber to: \'$zoneNumber\'');
        } else {
          // print('[STAT DEBUG PZ Block] RegExp did NOT match for shiftCode: \'$shiftCode\'. Keeping zoneNumber: \'$zoneNumber\'');
        }
        fileName = RosterService.getShiftFilename(zoneNumber, dayOfWeek, event.startDate);
        // print('[STAT DEBUG PZ Block] Determined filename: \'$fileName\'');
      }

      // Ensure a filename was determined (or explicitly cleared by UNI logic)
      if (fileName.isEmpty && !isUniShift) { // Modified condition
        // REMOVE log
        // print("Could not determine filename for shift: $shiftCode on $dayOfWeek");
        return null;
      }

      // If isUniShift is true, the logic above should have returned the duration or set fileName=''
      // If we reach here and isUniShift is true, it means it wasn't found in either file.
      if (isUniShift) {
        return null; 
      }

      // 1. Check cache first
      if (_csvWorkTimeCache.containsKey(fileName)) {
        final cachedFile = _csvWorkTimeCache[fileName]!;
        if (cachedFile.containsKey(shiftCode)) {
          // REMOVE log
          // print("Cache hit for $shiftCode in $fileName");
          return cachedFile[shiftCode];
        }
        // If file is cached but shift isn't, no need to reload file
        // print("Cache miss for shift $shiftCode in cached file $fileName");
        // return null; // Shift not in this specific cached file
      }

      // 2. If not in cache (or shift not in cached file), load and parse the file
      // REMOVE log
      // print("Cache miss for file $fileName, loading and parsing...");
      final csvData = await rootBundle.loadString('assets/$fileName');
      final lines = csvData.split('\n'); 
      final Map<String, Duration> parsedDurations = {};
      bool headerSkipped = false; // Flag to skip header row

      // 2. If not in cache (or shift not in cached file), load and parse the file (for PZ/BusCheck)
      for (final line in lines) {
        if (line.trim().isEmpty) continue;

        // Skip header row specifically for buscheck.csv
        if (isBusCheck && !headerSkipped) {
            headerSkipped = true;
            continue;
        }

        final parts = line.split(',');
        String currentShiftCode = parts[0].trim();
        Duration? duration;

        try {
          if (isBusCheck) {
            // buscheck.csv: duty,day,start,finish
            if (parts.length >= 4) {
              // Match based on the 'duty' column (index 0)
              if (currentShiftCode == shiftCode) {
                 final startTime = _parseTimeOfDay(parts[2].trim());
                 final endTime = _parseTimeOfDay(parts[3].trim());
                 if (startTime != null && endTime != null) {
                   duration = _calculateDuration(startTime, endTime);
                 } else {
                    // REMOVE log
                    // print('Error parsing start/end time for buscheck shift $currentShiftCode in $fileName: Line: $line');
                 }
              }
            }
          } else if (isUniShift) {
             // THIS BLOCK IS NOW UNREACHABLE / REDUNDANT because UNI logic is handled above
             // Remove or comment out this block if desired, but leaving it empty is fine.
          } else {
            // PZ_DUTIES files: shift,duty,...,work,... (work is index 14)
            // if (currentShiftCode == shiftCode) print('[STAT DEBUG PZ - ${fileName}] Checking line for $shiftCode: Parts=${parts.length}, Line=$line');
            
            if (parts.length > 14) { // Ensure index 14 exists
               // if (currentShiftCode == shiftCode) print('[STAT DEBUG PZ - ${fileName}] Comparing \'$currentShiftCode\' == \'$shiftCode\'');
               
               if (currentShiftCode == shiftCode) {
                  // print('[STAT DEBUG PZ - ${fileName}] Match for $shiftCode! Trying to parse workTime from parts[14]: \'${parts[14]}\'');
                  
                  final workTimeStr = parts[14].trim();
                  final timeParts = workTimeStr.split(':');
                  if (timeParts.length >= 2) {
                    // print('[STAT DEBUG PZ - ${fileName}] Parsing duration parts: ${timeParts[0]}h, ${timeParts[1]}m');
                    duration = Duration(
                      hours: int.parse(timeParts[0]),
                      minutes: int.parse(timeParts[1])
                    );
                    // print('[STAT DEBUG PZ - ${fileName}] Successfully parsed duration: $duration');
                  } else {
                    // print('[STAT DEBUG PZ Error - ${fileName}] Error parsing explicit work duration parts for PZ shift $currentShiftCode: $workTimeStr, Line: $line');
                  }
               } 
            } else {
                // if (currentShiftCode == shiftCode) print('[STAT DEBUG PZ Error - ${fileName}] Not enough parts (${parts.length}) for shift $shiftCode on line: $line');
            }
          }

          // If a duration was successfully calculated/parsed for the CURRENT line's shift code
          if (duration != null) {
             parsedDurations[currentShiftCode] = duration;
          }

        } catch (e, s) { // Inner catch for parsing/processing errors
          // print('*** ERROR processing line for shift $currentShiftCode in $fileName ***');
          // print('Error details: $e');
          // print('Stack trace: $s'); // Print the stack trace
        }
      }

      // 3. Store the parsed data in the cache (even if the specific shift wasn't found, cache the file)
      _csvWorkTimeCache[fileName] = parsedDurations;
      // REMOVE log
      // print("Cached data for $fileName");

      // 4. Return the requested duration from the now-cached data
      if (parsedDurations.containsKey(shiftCode)) {
         return parsedDurations[shiftCode];
      } else {
         // REMOVE log
         // print("Shift $shiftCode not found in parsed file $fileName");
         return null;
      }

    } catch (e, s) { // Outer catch
      // print('*** ERROR loading or processing CSV: $fileName for shift $shiftCode ***');
      // print('Error details: $e');
      // print('Stack trace: $s'); // Print the stack trace
      return null; 
    }
  }

  // --- ADD HELPER FUNCTION for loading/parsing a SINGLE UNI file --- 
  Future<Duration?> _tryLoadUniShiftFromFile(String shiftCode, String fileName) async {
     // print('[STAT DEBUG UNI Helper] Trying file: \'$fileName\' for shift: \'$shiftCode\'');
     try {
        // 1. Check cache first
        if (_csvWorkTimeCache.containsKey(fileName)) {
            final cachedFile = _csvWorkTimeCache[fileName]!;
            if (cachedFile.containsKey(shiftCode)) {
                // print('[STAT DEBUG UNI Helper] Cache HIT in \'$fileName\' for \'$shiftCode\'');
                return cachedFile[shiftCode];
            }
            // Shift not in this cached file, no need to reload
            // print('[STAT DEBUG UNI Helper] Cache MISS (shift) in \'$fileName\' for \'$shiftCode\'');
            return null; 
        }

        // 2. Load and parse file
        // print('[STAT DEBUG UNI Helper] Cache MISS (file) \'$fileName\'. Loading...');
        final csvData = await rootBundle.loadString('assets/$fileName');
        final lines = csvData.split('\n'); 
        final Map<String, Duration> parsedDurations = {};

        for (final line in lines) {
            if (line.trim().isEmpty) continue;
            final parts = line.split(',');
            
            if (parts.isNotEmpty) {
               final currentShiftCode = parts[0].trim();
               Duration? duration;

               // UNI CSV Parsing logic (same as before)
               if (parts.length >= 5) {
                   final startTime = _parseTimeOfDay(parts[1].trim());
                   final endTime = _parseTimeOfDay(parts[4].trim()); 
                   if (startTime != null && endTime != null) {
                       duration = _calculateDuration(startTime, endTime);
                   } else {
                       // print('[STAT DEBUG UNI Helper Error] Failed parsing time for \'$currentShiftCode\' in \'$fileName\'. Line: $line');
                   }
               }
               
               if (duration != null) {
                  parsedDurations[currentShiftCode] = duration;
               }
            }
        }

        // 3. Update cache for this file
        _csvWorkTimeCache[fileName] = parsedDurations;
        // print('[STAT DEBUG UNI Helper] Cached data for \'$fileName\'');

        // 4. Return duration if found, otherwise null
        if (parsedDurations.containsKey(shiftCode)) {
            // print('[STAT DEBUG UNI Helper] Found \'$shiftCode\' after parsing \'$fileName\'');
            return parsedDurations[shiftCode];
        } else {
            // print('[STAT DEBUG UNI Helper] Shift \'$shiftCode\' NOT found after parsing \'$fileName\'');
            return null;
        }

     } catch (e, s) {
        // print('*** ERROR in _tryLoadUniShiftFromFile ($fileName) for shift $shiftCode ***');
        // print('Error details: $e');
        // print('Stack trace: $s');
        return null;
     }
  }

  // Helper function to parse HH:MM strings into TimeOfDay (reuse from calendar screen if possible)
  TimeOfDay? _parseTimeOfDay(String? timeString) {
     if (timeString == null || timeString.isEmpty || timeString.toLowerCase() == 'nan') return null;
    try {
      final parts = timeString.split(':');
      if (parts.length >= 2) {
        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);
        if (hour != null && minute != null && hour >= 0 && hour < 24 && minute >= 0 && minute < 60) {
          return TimeOfDay(hour: hour, minute: minute);
        }
      }
    } catch (e) {
      // REMOVE log
      // print("Error parsing time string '$timeString': $e");
    }
    return null;
  }

  // Helper function to calculate duration between two TimeOfDay, handling overnight
  Duration _calculateDuration(TimeOfDay start, TimeOfDay end) {
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    if (endMinutes >= startMinutes) {
      return Duration(minutes: endMinutes - startMinutes);
    } else {
      // Overnight shift
      return Duration(minutes: (24 * 60 - startMinutes) + endMinutes);
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
      // REMOVE log
      // print('Error checking bank holiday: $e');
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

  // --- Add Calculation Logic --- 

  Future<void> _calculateSundayPairStatistics() async {
    if (_startDate == null) {
      if (mounted) setState(() => _sundayStatsLoading = false);
      return; // Cannot calculate without roster start date
    }

    if (mounted) setState(() => _sundayStatsLoading = true);

    final now = DateTime.now();
    const rosterCycleDays = 35; // 5 weeks * 7 days
    const maxMinutes = 870; // 14.5 hours

    try {
      // --- Determine current 5-week block --- 
      // Normalize now and _startDate to midnight UTC for consistent calculations
      final normalizedNow = DateTime.utc(now.year, now.month, now.day);
      final normalizedStartDate = DateTime.utc(_startDate!.year, _startDate!.month, _startDate!.day);

      // --- Corrected Logic --- 
      // 1. Find the actual start date of the cycle block containing the user's _startDate
      final referenceCycleStartDate = normalizedStartDate.subtract(Duration(days: _startWeek * 7));

      // 2. Calculate cycle shift relative to this reference start date
      final daysSinceReference = normalizedNow.difference(referenceCycleStartDate).inDays;
      final cycleShift = (daysSinceReference / rosterCycleDays).floor();
      
      // 3. Calculate the start date of the cycle containing 'now'
      final currentCycleStartDate = referenceCycleStartDate.add(Duration(days: cycleShift * rosterCycleDays));
      // --- End Corrected Logic --- 
      
      // Ensure the currentCycleStartDate corresponds to the start week (_startWeek)
      // It should be the Sunday of the week that has the roster pattern index matching _startWeek.
      // Adjust if necessary (this logic assumes _startDate is already the correct Sunday for _startWeek)
      // No adjustment needed here based on RosterService logic if _startDate is correctly set.

      // The L-Sunday is the start of Week 0 of this cycle
      // The E-Sunday is the start of Week 2 of this cycle
      final currentLsun = currentCycleStartDate; // Week 0, Day 0
      final currentEsun = currentCycleStartDate.add(const Duration(days: 14)); // Week 2, Day 0

      // --- Determine previous 5-week block ---
      final previousCycleStartDate = currentCycleStartDate.subtract(const Duration(days: rosterCycleDays));
      final previousLsun = previousCycleStartDate;
      final previousEsun = previousCycleStartDate.add(const Duration(days: 14));

      // --- Calculate hours for the pair in each block ---
      // Get Duration and Titles for each target Sunday
      final currentLsunInfo = await _getWorkHoursForDate(currentLsun);
      final currentEsunInfo = await _getWorkHoursForDate(currentEsun);
      final previousLsunInfo = await _getWorkHoursForDate(previousLsun);
      final previousEsunInfo = await _getWorkHoursForDate(previousEsun);

      // --- Combine and Calculate --- 
      final List<Map<String, dynamic>> currentShifts = [...currentLsunInfo, ...currentEsunInfo];
      final List<Map<String, dynamic>> previousShifts = [...previousLsunInfo, ...previousEsunInfo];

      final currentTotalDuration = currentShifts.fold<Duration>(
        Duration.zero,
        (sum, shift) => sum + (shift['duration'] as Duration)
      );
      final previousTotalDuration = previousShifts.fold<Duration>(
        Duration.zero,
        (sum, shift) => sum + (shift['duration'] as Duration)
      );

      // Update state
      if (mounted) {
        setState(() {
          _currentBlockLsunDate = currentLsun;
          _currentBlockEsunDate = currentEsun;
          _currentBlockSundayShifts = currentShifts; // Store combined list
          _currentBlockTotalSunHours = currentTotalDuration; // Store total
          _currentBlockLimitExceeded = currentTotalDuration.inMinutes > maxMinutes;
          
          _previousBlockLsunDate = previousLsun;
          _previousBlockEsunDate = previousEsun;
          _previousBlockSundayShifts = previousShifts; // Store combined list
          _previousBlockTotalSunHours = previousTotalDuration; // Store total
          _previousBlockLimitExceeded = previousTotalDuration.inMinutes > maxMinutes;

          _sundayStatsLoading = false;
        });
      }
    } catch (e) {
      // REMOVE log
      // print("Error calculating Sunday pair stats: $e");
      if (mounted) setState(() => _sundayStatsLoading = false);
    }
  }

  // Helper to get list of shift details (date, title, duration) for a specific date
  Future<List<Map<String, dynamic>>> _getWorkHoursForDate(DateTime targetDate) async {
    List<Map<String, dynamic>> shiftsDetails = []; // List to hold shift details
    // Use midnight in the local timezone for the key, matching how events are likely stored
    final localMidnightTargetDate = DateTime(targetDate.year, targetDate.month, targetDate.day);

    // Check if the date exists in the events map
    if (widget.events.containsKey(localMidnightTargetDate)) {
      final eventsOnDate = widget.events[localMidnightTargetDate]!;
      for (final event in eventsOnDate) {
        if (event.isWorkShift) {
          final workTime = await _calculateWorkTime(event); // Use existing calculation
          shiftsDetails.add({
            'date': localMidnightTargetDate, // Store the date for display
            'title': event.title,       // Store the title
            'duration': workTime,      // Store the duration
          });
        }
      }
    }
    return shiftsDetails;
  }

  // Helper to build the rows for individual shift details
  List<Widget> _buildShiftDetailRows(
      List<Map<String, dynamic>> shifts,
      DateFormat dateFormatter,
      String Function(Duration) formatDuration
  ) {
    return shifts.map((shift) {
      final date = shift['date'] as DateTime;
      final title = shift['title'] as String;
      final duration = shift['duration'] as Duration;
      return Padding(
        padding: const EdgeInsets.only(top: 2.0), // Small spacing between lines
        child: Text(
          "${dateFormatter.format(date)}: $title (${formatDuration(duration)})",
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
      );
    }).toList();
  }

  // --- Add Calculation Logic for Start Hour Frequency --- 
  Map<String, int> _getMostFrequentStartHours() {
    Map<int, int> hourCounts = {}; // Use int as key initially

    widget.events.forEach((date, events) {
      for (final event in events) {
        if (event.isWorkShift) {
          final startHour = event.startTime.hour;
          hourCounts[startHour] = (hourCounts[startHour] ?? 0) + 1;
        }
      }
    });

    // Convert to sorted Map<String, int> with formatted hour string
    final sortedEntries = hourCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value)); // Sort by count descending
    
    // Format hour as "HH:00" for display
    return Map.fromEntries(sortedEntries.map((entry) {
      final hourString = entry.key.toString().padLeft(2, '0') + ":00";
      return MapEntry(hourString, entry.value);
    }));
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

  // Add new method to calculate break statistics
  Map<String, dynamic> _calculateBreakStatistics() {
    print('Calculating break statistics...'); // Debug print
    
    final DateTime now = DateTime.now();
    
    // This week (Sunday to Saturday)
    final thisWeekStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday % 7));
    final thisWeekEnd = thisWeekStart.add(const Duration(days: 6));
    
    // Last week (previous Sunday to Saturday)
    final lastWeekEnd = thisWeekStart.subtract(const Duration(days: 1));
    final lastWeekStart = lastWeekEnd.subtract(const Duration(days: 6));
    
    // This month
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final thisMonthEnd = (now.month < 12)
        ? DateTime(now.year, now.month + 1, 1).subtract(const Duration(days: 1))
        : DateTime(now.year + 1, 1, 1).subtract(const Duration(days: 1));
        
    // Last month
    final lastMonthEnd = thisMonthStart.subtract(const Duration(days: 1));
    final lastMonthStart = DateTime(lastMonthEnd.year, lastMonthEnd.month, 1);
    
    // Get all events with late break status from the map of events
    final List<Event> eventsWithBreakStatus = [];
    widget.events.forEach((date, dayEvents) {
      for (final event in dayEvents) {
        if (event.hasLateBreak == true) {
          eventsWithBreakStatus.add(event);
        }
      }
    });
    
    // Final result map
    Map<String, dynamic> result = {
      'thisweek': _calculateBreakStatsForPeriod(eventsWithBreakStatus, thisWeekStart, thisWeekEnd),
      'lastweek': _calculateBreakStatsForPeriod(eventsWithBreakStatus, lastWeekStart, lastWeekEnd),
      'thismonth': _calculateBreakStatsForPeriod(eventsWithBreakStatus, thisMonthStart, thisMonthEnd),
      'lastmonth': _calculateBreakStatsForPeriod(eventsWithBreakStatus, lastMonthStart, lastMonthEnd),
      'alltime': _calculateBreakStatsForPeriod(eventsWithBreakStatus, null, null),
    };
    
    print('Break statistics calculated: ${result.length} periods'); // Debug print
    print('Found ${eventsWithBreakStatus.length} events with late break status'); // Debug
    return result;
  }
  
  Map<String, dynamic> _calculateBreakStatsForPeriod(
    List<Event> events, DateTime? startDate, DateTime? endDate) {
    
    // Filter by date range if specified
    List<Event> filteredEvents = events;
    if (startDate != null && endDate != null) {
      filteredEvents = events.where((event) {
        final eventDate = DateTime(event.startDate.year, event.startDate.month, event.startDate.day);
        return eventDate.isAtSameMomentAs(startDate) || 
               eventDate.isAtSameMomentAs(endDate) || 
               (eventDate.isAfter(startDate) && eventDate.isBefore(endDate));
      }).toList();
    }
    
    // Count statistics
    int total = filteredEvents.length;
    int fullBreak = filteredEvents.where((e) => e.tookFullBreak == true).length;
    int overtime = filteredEvents.where((e) => e.tookFullBreak == false).length;
    
    // Calculate total overtime minutes
    int totalOvertimeMinutes = 0;
    for (final event in filteredEvents) {
      if (event.tookFullBreak == false && event.overtimeDuration != null) {
        totalOvertimeMinutes += event.overtimeDuration!;
      }
    }
    
    return {
      'total': total,
      'fullBreak': fullBreak,
      'overtime': overtime,
      'totalOvertimeMinutes': totalOvertimeMinutes,
    };
  }
}
