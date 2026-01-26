import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spdrivercalendar/models/event.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:spdrivercalendar/features/calendar/services/roster_service.dart';
import 'package:spdrivercalendar/core/services/storage_service.dart';
import 'package:spdrivercalendar/core/constants/app_constants.dart';
import 'package:spdrivercalendar/features/calendar/services/holiday_service.dart';
import 'package:spdrivercalendar/models/holiday.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';

// Import the new widgets
import '../widgets/frequency_chart.dart';
import '../widgets/shift_type_summary_card.dart';
import '../widgets/work_time_stats_card.dart';
import '../widgets/spread_statistics_card.dart';
import '../widgets/break_statistics_card.dart';
import '../widgets/sick_days_statistics_card.dart';
import '../widgets/holiday_days_statistics_card.dart';
import '../widgets/work_time_trend_chart.dart';
import '../widgets/shift_type_pie_chart.dart';
import '../widgets/earnings_calculator_card.dart';
import '../widgets/statistics_export_service.dart';
import 'package:share_plus/share_plus.dart';
import '../../../services/days_in_lieu_service.dart';
import '../../../services/annual_leave_service.dart';
import '../../../services/color_customization_service.dart';

enum ShiftType {
  early,   // 04:00 - 09:59
  relief,  // 10:00 - 13:59
  late,    // 14:00 - 18:59
  night,   // 19:00 - 03:59
  bogey,   // Any duty with X suffix
  spare,   // Spare duties
  uniEuro, // Duties starting with numbers/pattern
}

class StatisticsScreen extends StatefulWidget {
  final Map<DateTime, List<Event>> events;

  const StatisticsScreen({
    super.key,
    required this.events,
  });

  @override
  StatisticsScreenState createState() => StatisticsScreenState();
}

class StatisticsScreenState extends State<StatisticsScreen> 
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;
  
  String _timeRange = 'This Week';
  String _breakTimeRange = 'This Week';
  String _sickDaysTimeRange = 'This Month';
  String _holidayDaysTimeRange = DateTime.now().year.toString();
  final List<String> _timeRanges = [
    'This Week', 
    'Last Week', 
    'This Month', 
    'Last Month', 
    'All Time'
  ];
  final List<String> _sickDaysTimeRanges = [
    'This Month',
    'Last Month',
    'Last 3 Months',
    'Last 6 Months',
    'Jan-Jun',
    'Jul-Dec',
    'This Year',
    'Last Year',
  ];
  
  // Generate holiday days time ranges dynamically based on current year
  List<String> get _holidayDaysTimeRanges {
    final currentYear = DateTime.now().year;
    // Include current year and 2 years before and after
    return List.generate(5, (index) => (currentYear - 2 + index).toString());
  }

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
  
  // Cache for parsed CSV spread data: Key = filename, Value = Map<ShiftCode, Duration>
  final Map<String, Map<String, Duration>> _csvSpreadTimeCache = {};

  // Constants for work durations
  static const Duration spareDutyWorkDuration = Duration(hours: 7, minutes: 38);

  // Roster settings
  DateTime? _startDate;
  int _startWeek = 0;
  
  // Marked-in settings
  bool _markedInEnabled = false;
  String _markedInStatus = 'Shift';

  // State variable to hold the future for work time stats
  Future<Map<String, Duration>>? _workTimeStatsFuture;
  
  // State variable to hold the future for spread stats
  Future<Map<String, Duration>>? _spreadStatsFuture;
  
  // State variable to hold the future for holiday days stats
  Future<Map<String, dynamic>>? _holidayDaysStatsFuture;
  
  // State variable for monthly trend data
  Future<Map<String, Duration>>? _monthlyTrendFuture;

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
  
  // Scroll controllers for each tab
  final ScrollController _workTimeScrollController = ScrollController();
  final ScrollController _summaryScrollController = ScrollController();
  final ScrollController _frequencyScrollController = ScrollController();
  
  // Days in lieu balance state
  int _daysInLieuRemaining = 0;
  int _daysInLieuUsed = 0;

  // Annual leave balance state
  int _annualLeaveRemaining = 0;
  int _annualLeaveUsed = 0;

  // Expandable sections state
  final Map<String, bool> _expandedSections = {
    'Work Time Statistics': false,
    'Spread Statistics': false,
    'Rostered Sunday Pair Hours': false,
    'Shift Type Summary': false,
    'Break Statistics': false,
    'Holiday Balance': false,
    'Sick Days Statistics': false,
    'Most Frequent Shifts': false,
    'Most Frequent Buses': false,
    'Most Frequent Start Hours': false,
  };
  
  @override
  void initState() {
    super.initState();
    // Ensure TabController length is 3
    _tabController = TabController(length: 3, vsync: this);
    _loadExpandedSections();
    _initializeStatistics();
  }
  
  Future<void> _loadExpandedSections() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _expandedSections['Work Time Statistics'] = prefs.getBool('stats_expanded_work_time') ?? false;
      _expandedSections['Spread Statistics'] = prefs.getBool('stats_expanded_spread') ?? false;
      _expandedSections['Rostered Sunday Pair Hours'] = prefs.getBool('stats_expanded_sunday_pair') ?? false;
      // Migrate Shift Type Distribution to Shift Type Summary if it was expanded
      final shiftDistributionExpanded = prefs.getBool('stats_expanded_shift_distribution') ?? false;
      final shiftSummaryExpanded = prefs.getBool('stats_expanded_shift_summary') ?? false;
      _expandedSections['Shift Type Summary'] = shiftDistributionExpanded || shiftSummaryExpanded;
      _expandedSections['Break Statistics'] = prefs.getBool('stats_expanded_break') ?? false;
      // Migrate Holiday Days Statistics to Holiday Balance if it was expanded
      final holidayDaysStatsExpanded = prefs.getBool('stats_expanded_holiday') ?? false;
      final holidayBalanceExpanded = prefs.getBool('stats_expanded_holiday_balance') ?? false;
      _expandedSections['Holiday Balance'] = holidayDaysStatsExpanded || holidayBalanceExpanded;
      // Migrate old keys to new combined section
      final daysInLieuExpanded = prefs.getBool('stats_expanded_days_in_lieu') ?? false;
      final annualLeaveExpanded = prefs.getBool('stats_expanded_annual_leave') ?? false;
      _expandedSections['Holiday Balance'] = daysInLieuExpanded || annualLeaveExpanded;
      _expandedSections['Sick Days Statistics'] = prefs.getBool('stats_expanded_sick') ?? false;
      _expandedSections['Most Frequent Shifts'] = prefs.getBool('stats_expanded_frequent_shifts') ?? false;
      _expandedSections['Most Frequent Buses'] = prefs.getBool('stats_expanded_frequent_buses') ?? false;
      _expandedSections['Most Frequent Start Hours'] = prefs.getBool('stats_expanded_frequent_hours') ?? false;
    });
  }
  
  Future<void> _saveExpandedSection(String section, bool expanded) async {
    final prefs = await SharedPreferences.getInstance();
    String key;
    switch (section) {
      case 'Work Time Statistics':
        key = 'stats_expanded_work_time';
        break;
      case 'Spread Statistics':
        key = 'stats_expanded_spread';
        break;
      case 'Rostered Sunday Pair Hours':
        key = 'stats_expanded_sunday_pair';
        break;
      case 'Shift Type Summary':
        key = 'stats_expanded_shift_summary';
        break;
      case 'Break Statistics':
        key = 'stats_expanded_break';
        break;
      case 'Holiday Balance':
        key = 'stats_expanded_holiday_balance';
        break;
      case 'Sick Days Statistics':
        key = 'stats_expanded_sick';
        break;
      case 'Most Frequent Shifts':
        key = 'stats_expanded_frequent_shifts';
        break;
      case 'Most Frequent Buses':
        key = 'stats_expanded_frequent_buses';
        break;
      case 'Most Frequent Start Hours':
        key = 'stats_expanded_frequent_hours';
        break;
      default:
        return;
    }
    await prefs.setBool(key, expanded);
  }

  @override
  void didUpdateWidget(covariant StatisticsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.events != oldWidget.events) {
      _workTimeStatsFuture = _calculateWorkTimeStatistics();
      _spreadStatsFuture = _calculateSpreadStatistics();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh balances when screen becomes visible
    _loadDaysInLieuBalance();
    _loadAnnualLeaveBalance();
  }

  @override
  void dispose() {
    // Dispose TabController
    _tabController?.dispose();
    _workTimeScrollController.dispose();
    _summaryScrollController.dispose();
    _frequencyScrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeStatistics() async {
    // Clear the cache on initialization to prevent stale data issues
    _csvWorkTimeCache.clear();
    _csvSpreadTimeCache.clear(); 
    
    await _loadRosterSettings();
    await _loadMarkedInSettings();
    await _loadDaysInLieuBalance();
    await _loadAnnualLeaveBalance();
    if (mounted) {
       setState(() {
         _workTimeStatsFuture = _calculateWorkTimeStatistics();
         _spreadStatsFuture = _calculateSpreadStatistics();
         _holidayDaysStatsFuture = _calculateHolidayDaysStatistics();
         _monthlyTrendFuture = _calculateMonthlyTrends();
         // Trigger Sunday pair calculation (no need to await here, UI will update)
         _calculateSundayPairStatistics(); 
       });
    }
  }

  Future<void> _loadDaysInLieuBalance() async {
    final remaining = await DaysInLieuService.getRemainingDays();
    final used = await DaysInLieuService.getUsedDays();
    if (mounted) {
      setState(() {
        _daysInLieuRemaining = remaining;
        _daysInLieuUsed = used;
      });
    }
  }

  Future<void> _loadAnnualLeaveBalance() async {
    final remaining = await AnnualLeaveService.getRemainingDays();
    final used = await AnnualLeaveService.getUsedDays();
    if (mounted) {
      setState(() {
        _annualLeaveRemaining = remaining;
        _annualLeaveUsed = used;
      });
    }
  }

  // Responsive sizing helper method
  Map<String, double> _getResponsiveSizes(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Very small screens (narrow phones)
    if (screenWidth < 350) {
      return {
        'padding': 8.0,              // Reduced from 16
        'cardPadding': 12.0,          // Reduced from 16
        'cardSpacing': 12.0,          // Reduced from 16
        'sectionSpacing': 8.0,        // Reduced spacing
        'titleFontSize': 14.0,        // Reduced from 18
      };
    }
    // Small phones (like older iPhones)
    else if (screenWidth < 400) {
      return {
        'padding': 10.0,
        'cardPadding': 14.0,
        'cardSpacing': 14.0,
        'sectionSpacing': 10.0,
        'titleFontSize': 15.0,
      };
    }
    // Mid-range phones (like Galaxy S23)
    else if (screenWidth < 450) {
      return {
        'padding': 12.0,
        'cardPadding': 15.0,
        'cardSpacing': 15.0,
        'sectionSpacing': 12.0,
        'titleFontSize': 16.0,
      };
    }
    // Regular phones and larger
    else {
      return {
        'padding': 16.0,             // Original size
        'cardPadding': 16.0,         // Original size
        'cardSpacing': 16.0,         // Original size
        'sectionSpacing': 16.0,      // Original size
        'titleFontSize': 18.0,       // Original size
      };
    }
  }

  Widget _buildExpandableSection({
    required String title,
    required List<Widget> children,
    IconData? icon,
    String? subtitle,
  }) {
    final isExpanded = _expandedSections[title] ?? false;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    return Card(
      margin: EdgeInsets.symmetric(
        vertical: 4.0,
        horizontal: isSmallScreen ? 0.0 : 4.0,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          leading: icon != null
              ? Icon(icon, color: AppTheme.primaryColor)
              : null,
          title: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.primaryColor,
              fontSize: isSmallScreen ? 18 : 20,
            ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    fontStyle: FontStyle.italic,
                  ),
                )
              : null,
          initiallyExpanded: isExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              _expandedSections[title] = expanded;
            });
            _saveExpandedSection(title, expanded);
          },
          tilePadding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 12.0 : 16.0,
            vertical: 8.0,
          ),
          childrenPadding: EdgeInsets.zero,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(AppTheme.borderRadius),
                  bottomRight: Radius.circular(AppTheme.borderRadius),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 8.0 : 16.0,
                  vertical: 8.0,
                ),
                child: Column(
                  children: children,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    // Check if TabController is initialized
    if (_tabController == null) {
      // Return a loading indicator or empty container until initialized
      return Scaffold(
        appBar: AppBar(title: const Text('Shift Statistics')), // Keep AppBar for consistency
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Proceed with the build now that controller is guaranteed to be non-null
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shift Statistics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Export Statistics',
            onPressed: _exportStatistics,
          ),
        ],
        // Add TabBar to the bottom of the AppBar
        bottom: TabBar(
          controller: _tabController!, // Use null assertion
          indicatorColor: Theme.of(context).colorScheme.onPrimary, // Highlight selected tab indicator
          labelColor: Theme.of(context).colorScheme.onPrimary, // Color for selected tab label
          unselectedLabelColor: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7), // Slightly dimmer for unselected
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
    final sizes = _getResponsiveSizes(context);
    
    // Format helper for duration
    String formatDuration(Duration d) {
      if (d == Duration.zero) return "0h 0m";
      final hours = d.inHours;
      final minutes = d.inMinutes.remainder(60);
      return "${hours}h ${minutes}m";
    }

    // Date formatter
    final DateFormat listTitleDateFormatter = DateFormat('MMM d'); // For ListTile title
    final DateFormat detailDateFormatter = DateFormat('dd/MM/yy'); // For detail lines

    return Scrollbar(
      controller: _workTimeScrollController,
      thumbVisibility: true,
      thickness: 6,
      radius: const Radius.circular(3),
      child: SingleChildScrollView(
        controller: _workTimeScrollController,
        padding: EdgeInsets.all(sizes['padding']!),
        child: Column( // Use Column to allow multiple Cards/Widgets
        children: [
          _buildExpandableSection(
            title: 'Work Time Statistics',
            subtitle: 'Break times and Rest Days not included in calculation',
            icon: Icons.access_time,
            children: [
              const SizedBox(height: 8),
              _workTimeStatsFuture == null
                ? const Center(child: CircularProgressIndicator())
                : WorkTimeStatisticsCard(
                    workTimeStatsFuture: _workTimeStatsFuture!,
                  ),
            ],
          ),
          SizedBox(height: sizes['cardSpacing']!), // Spacing between cards
          _buildExpandableSection(
            title: 'Spread Statistics',
            subtitle: 'Time worked over 10 hours on M-F duties only',
            icon: Icons.timer,
            children: [
              const SizedBox(height: 8),
              _spreadStatsFuture == null
                ? const Center(child: CircularProgressIndicator())
                : SpreadStatisticsCard(
                    spreadStatsFuture: _spreadStatsFuture!,
                  ),
            ],
          ),
          SizedBox(height: sizes['cardSpacing']!),
          // Monthly Trend Chart
          _buildExpandableSection(
            title: 'Monthly Work Time Trend',
            subtitle: 'Last 12 months',
            icon: Icons.trending_up,
            children: [
              const SizedBox(height: 8),
              _monthlyTrendFuture == null
                ? const Center(child: CircularProgressIndicator())
                : FutureBuilder<Map<String, Duration>>(
                    future: _monthlyTrendFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError || !snapshot.hasData) {
                        return const Center(child: Text('Unable to load trend data'));
                      }
                      return WorkTimeTrendChart(
                        monthlyData: snapshot.data!,
                      );
                    },
                  ),
            ],
          ),
          SizedBox(height: sizes['cardSpacing']!), // Spacing between cards
          _buildExpandableSection(
            title: 'Rostered Sunday Pair Hours',
            subtitle: 'Sum of hours worked on specific rostered Late & Early Sundays (Max 14h 30m). Entitled to overtime if time is more than 14h 30m. If the second Sunday has not happened yet, and the time is more than 14h 30m, you have the right to finish in the garage',
            icon: Icons.calendar_today,
            children: [
              const SizedBox(height: 8),
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
                    'Current Sundays${(_currentBlockLsunDate != null && _currentBlockEsunDate != null) ? ' (${listTitleDateFormatter.format(_currentBlockLsunDate!)} + ${listTitleDateFormatter.format(_currentBlockEsunDate!)})' : ''}',
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
                    : Icon(Icons.check_circle_outline, color: Theme.of(context).colorScheme.primary),
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
                    'Previous Sundays${(_previousBlockLsunDate != null && _previousBlockEsunDate != null) ? ' (${listTitleDateFormatter.format(_previousBlockLsunDate!)} + ${listTitleDateFormatter.format(_previousBlockEsunDate!)})' : ''}',
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
                    : Icon(Icons.check_circle_outline, color: Theme.of(context).colorScheme.primary),
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
        ],
      ),
      ),
    );
  }

  Widget _buildSummaryTab() {
    final sizes = _getResponsiveSizes(context);
    
    return Scrollbar(
      controller: _summaryScrollController,
      thumbVisibility: true,
      thickness: 6,
      radius: const Radius.circular(3),
      child: SingleChildScrollView(
        controller: _summaryScrollController,
        padding: EdgeInsets.all(sizes['padding']!),
        child: Column(
        children: [
          // Shift Type Summary (combines Distribution pie chart and Summary statistics)
          _buildExpandableSection(
            title: 'Shift Type Summary',
            subtitle: 'Rest Days not included in calculation',
            icon: Icons.bar_chart,
            children: [
              const SizedBox(height: 8),
              // Pie Chart
              ShiftTypePieChart(
                shiftCounts: {
                  'Early': _calculateSummaryStatistics()['earlyShifts'] ?? 0,
                  'Relief': _calculateSummaryStatistics()['reliefShifts'] ?? 0,
                  'Late': _calculateSummaryStatistics()['lateShifts'] ?? 0,
                  'Night': _calculateSummaryStatistics()['nightShifts'] ?? 0,
                  'Spare': _calculateSummaryStatistics()['spareShifts'] ?? 0,
                  'Bogey': _calculateSummaryStatistics()['bogeyShifts'] ?? 0,
                  'Overtime': _calculateSummaryStatistics()['overtimeShifts'] ?? 0,
                },
              ),
              const SizedBox(height: 16),
              // Detailed Statistics
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
            ],
          ),
          
          SizedBox(height: sizes['cardSpacing']!),
          
          // Earnings Calculator
          _buildExpandableSection(
            title: 'Earnings Calculator',
            subtitle: 'Estimated earnings based on spread pay',
            icon: Icons.calculate,
            children: [
              const SizedBox(height: 8),
              _workTimeStatsFuture == null || _spreadStatsFuture == null
                ? const Center(child: CircularProgressIndicator())
                : FutureBuilder(
                    future: Future.wait([
                      _workTimeStatsFuture!,
                      _spreadStatsFuture!,
                    ]),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError || !snapshot.hasData) {
                        return const Center(child: Text('Unable to load earnings data'));
                      }
                      final workTimeStats = snapshot.data![0];
                      final spreadStats = snapshot.data![1];
                      final summaryStats = _calculateSummaryStatistics();
                      return EarningsCalculatorCard(
                        totalWorkTime: workTimeStats['total'] ?? Duration.zero,
                        thisWeekSpreadTime: spreadStats['thisWeek'] ?? Duration.zero,
                        lastWeekSpreadTime: spreadStats['lastWeek'] ?? Duration.zero,
                        overtimeShifts: summaryStats['overtimeShifts'] ?? 0,
                        overtimeDuration: const Duration(),
                      );
                    },
                  ),
            ],
          ),
          
          SizedBox(height: sizes['cardSpacing']!),
          
          // Break Statistics Card
          _buildExpandableSection(
            title: 'Break Statistics',
            icon: Icons.free_breakfast,
            children: [
              const SizedBox(height: 8),
              BreakStatisticsCard(
                breakStats: _calculateBreakStatistics(),
                currentRange: _breakTimeRange,
                availableRanges: _timeRanges,
                onChanged: (newRange) {
                  if (newRange != null) {
                    setState(() {
                      _breakTimeRange = newRange;
                    });
                    // Break stats time range changed
                  }
                },
              ),
            ],
          ),
          
          SizedBox(height: sizes['cardSpacing']!),
          
          // Holiday Balance (combines Holiday Days Statistics and Balance)
          _buildExpandableSection(
            title: 'Holiday Balance',
            icon: Icons.beach_access,
            children: [
              const SizedBox(height: 8),
              // Holiday Days Statistics
              _holidayDaysStatsFuture == null
                ? const Center(child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: CircularProgressIndicator(),
                  ))
                : FutureBuilder<Map<String, dynamic>>(
                    future: _holidayDaysStatsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: CircularProgressIndicator(),
                        ));
                      }
                      
                      if (snapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'Error loading holiday statistics: ${snapshot.error}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        );
                      }
                      
                      final holidayStats = snapshot.data ?? {};
                      
                      return HolidayDaysStatisticsCard(
                        holidayStats: holidayStats,
                        currentRange: _holidayDaysTimeRange,
                        availableRanges: _holidayDaysTimeRanges,
                        onChanged: (newRange) {
                          if (newRange != null) {
                            setState(() {
                              _holidayDaysTimeRange = newRange;
                            });
                          }
                        },
                      );
                    },
                  ),
              const SizedBox(height: 16),
              // Balance Card (Annual Leave and Days In Lieu)
              _buildHolidayBalanceCard(),
            ],
          ),
          
          SizedBox(height: sizes['cardSpacing']!),
          
          // Sick Days Statistics Card
          _buildExpandableSection(
            title: 'Sick Days Statistics',
            icon: Icons.medical_services,
            children: [
              const SizedBox(height: 8),
              SickDaysStatisticsCard(
                sickStats: _calculateSickDaysStatistics(),
                currentRange: _sickDaysTimeRange,
                availableRanges: _sickDaysTimeRanges,
                onChanged: (newRange) {
                  if (newRange != null) {
                    setState(() {
                      _sickDaysTimeRange = newRange;
                    });
                  }
                },
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildFrequencyTab() {
    final sizes = _getResponsiveSizes(context);
    
    return Scrollbar(
      controller: _frequencyScrollController,
      thumbVisibility: true,
      thickness: 6,
      radius: const Radius.circular(3),
      child: SingleChildScrollView(
        controller: _frequencyScrollController,
        padding: EdgeInsets.all(sizes['padding']!),
        child: Column(
          children: [
            // --- Shifts Section ---
            _buildExpandableSection(
              title: 'Most Frequent Shifts',
              subtitle: 'Mon-Fri shifts only',
              icon: Icons.work,
              children: [
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    DropdownButton<int>(
                      value: _numberOfShiftsToShow,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      iconEnabledColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      items: _shiftNumberOptions.map((int value) {
                        return DropdownMenuItem<int>(
                          value: value,
                          child: Text('Top $value', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
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
                const SizedBox(height: 8),
                FrequencyChart(
                  frequencyData: Map.fromEntries(
                     _getAllTimeFrequentShifts().entries.take(_numberOfShiftsToShow)
                  ),
                  emptyDataMessage: 'No Mon-Fri shift data available',
                ),
              ],
            ),
            
            SizedBox(height: sizes['cardSpacing']!),

            // --- Buses Section ---
            _buildExpandableSection(
              title: 'Most Frequent Buses',
              subtitle: 'All time',
              icon: Icons.directions_bus,
              children: [
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    DropdownButton<int>(
                      value: _numberOfBusesToShow,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      iconEnabledColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      items: _busNumberOptions.map((int value) {
                        return DropdownMenuItem<int>(
                          value: value,
                          child: Text('Top $value', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
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
                const SizedBox(height: 8),
                FrequencyChart(
                  frequencyData: Map.fromEntries(
                    _getMostFrequentBuses().entries.take(_numberOfBusesToShow)
                  ),
                  emptyDataMessage: 'No bus assignment data available',
                ),
              ],
            ),

            SizedBox(height: sizes['cardSpacing']!),

            // --- Start Hour Frequency Chart ---
            _buildExpandableSection(
              title: 'Most Frequent Start Hours',
              subtitle: 'Groups logged work shifts by their starting hour (e.g., 06:00-06:59)',
              icon: Icons.schedule,
              children: [
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    DropdownButton<int>(
                      value: _numberOfStartHoursToShow,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      iconEnabledColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      items: _startHourNumberOptions.map((int value) {
                        return DropdownMenuItem<int>(
                          value: value,
                          child: Text('Top $value', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
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
                const SizedBox(height: 8),
                FrequencyChart(
                  frequencyData: Map.fromEntries(
                    _getMostFrequentStartHours().entries.take(_numberOfStartHoursToShow)
                  ),
                  emptyDataMessage: 'No shift start time data available',
                ),
              ],
            ),
          ],
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
            
            if (!countedIds.contains(event.id)) {
              countedIds.add(event.id);
              
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
    // Statistics always use Sunday-Saturday weeks regardless of calendar display preference
    switch (_timeRange) {
      case 'This Week':
        // Start from Sunday of current week
        final firstDayOfWeek = now.subtract(Duration(days: now.weekday % 7));
        startDate = DateTime(firstDayOfWeek.year, firstDayOfWeek.month, firstDayOfWeek.day);
        endDate = startDate.add(const Duration(days: 6));
        break;
      case 'Last Week':
        // Last week (previous Sunday to Saturday) - match work time calculation logic
        final thisWeekStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday % 7));
        final lastWeekEnd = DateTime(thisWeekStart.year, thisWeekStart.month, thisWeekStart.day).subtract(const Duration(days: 1)); // End on previous Saturday
        startDate = DateTime(lastWeekEnd.year, lastWeekEnd.month, lastWeekEnd.day).subtract(const Duration(days: 6)); // Start on previous Sunday
        endDate = lastWeekEnd;
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
    int overtimeShifts = 0; // Add overtime shifts counter
    int workForOthersShifts = 0; // Work For Others shifts counter
    
    // Track processed event IDs to avoid counting duplicates
    final Set<String> processedIds = {};
    
    // --- Refactored Processing Logic --- 
    widget.events.forEach((date, events) { // Iterate through all dates in the events map
      for (final event in events) { // Iterate through events on that date
        // Skip if already processed (handles cases where event might span midnight)
        if (processedIds.contains(event.id)) continue;
        
        // Check if event falls within the selected date range
        // Use event.startDate for the check
        if (!event.startDate.isBefore(startDate) && 
            event.startDate.isBefore(endDate.add(const Duration(days: 1)))) {
          
          processedIds.add(event.id); // Mark as processed

          // First check if this is a Work For Others shift
          if (event.isWorkForOthers) {
            workForOthersShifts++;
            continue; // Skip further processing for WFO shifts (they're not counted in restDaysWorked)
          }

          // Then check if this is an overtime shift
          if (event.isWorkShift && event.title.contains('(OT)')) {
            overtimeShifts++;
            continue; // Skip further processing for overtime shifts
          }
          
          // Only consider non-overtime work shifts for regular statistics
          if (!event.isWorkShift) continue;

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
            if (shiftCode.startsWith('SP') || shiftCode == '22B/01') {
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
      'overtimeShifts': overtimeShifts, // Add overtime shifts to returned data
      'workForOthersShifts': workForOthersShifts, // Add Work For Others shifts to returned data
      'dateRange': dateRangeStr,
    };
  }

  Future<Duration> _calculateWorkTime(Event event) async {


    if (!event.isWorkShift) {

      return Duration.zero;
    }

    // For spare duties (fixed 7h 38m) and 22B/01 (fixed 8h 30m)
    if (event.title.startsWith('SP')) {

      return const Duration(hours: 7, minutes: 38);
    }
    
    // For 22B/01 Sunday duty (same work time as spare duties: 7h 38m, excluding break)
    if (event.title == '22B/01') {
      return const Duration(hours: 7, minutes: 38);
    }

    // For all other duties, rely on _loadWorkTimeFromCSV
    final dayOfWeek = await _getDayOfWeek(event.startDate);

    final workTime = await _loadWorkTimeFromCSV(event, dayOfWeek);
    
    // If CSV lookup succeeds, return the duration
    if (workTime != null) {

      return workTime;
    }
    
    // If CSV lookup fails (shift not found, file error, parsing error, etc.)
    // return Duration.zero instead of falling back to potentially inaccurate calculation.
    // Keep original warning for actual failures

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

      
      // Check for Jamestown Road shifts first (before UNI check)
      } else if (shiftCode.startsWith('811/')) {
        // Handle Jamestown Road shifts
        return await _loadJamestownWorkTime(shiftCode);
      
      // Check for UNI using firstMatch with simplified regex
      } else if (RegExp(r'^\d+/').firstMatch(shiftCode) != null) { // Use \d+ (one or more digits)

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

        
        // Try primary file first
        Duration? uniDuration = await _tryLoadUniShiftFromFile(shiftCode, primaryFileName);
        
        // If not found in primary, try fallback
        uniDuration ??= await _tryLoadUniShiftFromFile(shiftCode, fallbackFileName);
        
        // If found in either file, return the duration
        if (uniDuration != null) {

           return uniDuration;
        }
        
        // If not found in either, fall through to return null (handled after catch block)

        fileName = ''; // Set filename to empty to prevent PZ block execution & ensure null return
        // --- End New UNI Logic ---

      // Handle PZ shifts (if not BusCheck or UNI)
      } else {


        final match = RegExp(r'PZ(\d+)/').firstMatch(shiftCode);
        if (match != null) {

          zoneNumber = match.group(1) ?? '1';

        } else {

        }
        fileName = RosterService.getShiftFilename(zoneNumber, dayOfWeek, event.startDate);

      }

      // Ensure a filename was determined (or explicitly cleared by UNI logic)
      if (fileName.isEmpty && !isUniShift) { // Modified condition

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

          return cachedFile[shiftCode];
        }
        // If file is cached but shift isn't, no need to reload file

        // return null; // Shift not in this specific cached file
      }

      // 2. If not in cache (or shift not in cached file), load and parse the file

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
                 }
              }
            }
          } else if (isUniShift) {
             // THIS BLOCK IS NOW UNREACHABLE / REDUNDANT because UNI logic is handled above
             // Remove or comment out this block if desired, but leaving it empty is fine.
          } else {
            // PZ_DUTIES files: shift,duty,...,work,... (work is index 14)

            
            if (parts.length > 14) { // Ensure index 14 exists

               
               if (currentShiftCode == shiftCode) {

                  
                  final workTimeStr = parts[14].trim();
                  final timeParts = workTimeStr.split(':');
                  if (timeParts.length >= 2) {

                    duration = Duration(
                      hours: int.parse(timeParts[0]),
                      minutes: int.parse(timeParts[1])
                    );

                  } else {

                  }
               } 
            } else {

            }
          }

          // If a duration was successfully calculated/parsed for the CURRENT line's shift code
          if (duration != null) {
             parsedDurations[currentShiftCode] = duration;
          }

        } catch (e) { // Inner catch for parsing/processing errors
          // Error processing line for shift - continue to next line
        }
      }

      // 3. Store the parsed data in the cache (even if the specific shift wasn't found, cache the file)
      _csvWorkTimeCache[fileName] = parsedDurations;


      // 4. Return the requested duration from the now-cached data
      if (parsedDurations.containsKey(shiftCode)) {
         return parsedDurations[shiftCode];
      } else {

         return null;
      }

    } catch (e) { // Outer catch
      // Error loading or processing CSV file
      return null; 
    }
  }

  // --- ADD HELPER FUNCTION for loading Jamestown work time ---
  Future<Duration?> _loadJamestownWorkTime(String shiftCode) async {
    try {
      // Check cache first
      const fileName = 'JAMESTOWN_DUTIES.csv';
      if (_csvWorkTimeCache.containsKey(fileName)) {
        final cachedFile = _csvWorkTimeCache[fileName]!;
        if (cachedFile.containsKey(shiftCode)) {
          return cachedFile[shiftCode];
        }
      }

      // Load and parse JAMESTOWN_DUTIES.csv
      final csvData = await rootBundle.loadString('assets/$fileName');
      final lines = csvData.split('\n');
      final Map<String, Duration> parsedDurations = {};

      // Skip header line and process data
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim().replaceAll('\r', '');
        if (line.isEmpty) continue;
        
        final parts = line.split(',');
        // Expected format: shift,duty,report,depart,location,startbreak,startbreaklocation,breakreport,finishbreak,finishbreaklocation,finish,finishlocation,signoff,spread,work,relief,route
        if (parts.length >= 15) {
          final currentShiftCode = parts[0].trim();
          final workTimeStr = parts[14].trim(); // work column
          
          if (workTimeStr.isNotEmpty && workTimeStr.toLowerCase() != 'nan') {
            // Parse work time in HH:MM format
            final timeParts = workTimeStr.split(':');
            if (timeParts.length >= 2) {
              try {
                final hours = int.parse(timeParts[0]);
                final minutes = int.parse(timeParts[1]);
                final duration = Duration(hours: hours, minutes: minutes);
                parsedDurations[currentShiftCode] = duration;
              } catch (e) {
                // Failed to parse work time for shift
              }
            }
          }
        }
      }

      // Cache the parsed data
      _csvWorkTimeCache[fileName] = parsedDurations;

      // Return the duration for the requested shift
      return parsedDurations[shiftCode];
    } catch (e) {
      // Failed to load Jamestown work time CSV
      return null;
    }
  }

  // --- ADD HELPER FUNCTION for loading/parsing a SINGLE UNI file --- 
  Future<Duration?> _tryLoadUniShiftFromFile(String shiftCode, String fileName) async {

     try {
        // 1. Check cache first
        if (_csvWorkTimeCache.containsKey(fileName)) {
            final cachedFile = _csvWorkTimeCache[fileName]!;
            if (cachedFile.containsKey(shiftCode)) {

                return cachedFile[shiftCode];
            }
            // Shift not in this cached file, no need to reload

            return null; 
        }

        // 2. Load and parse file

        final csvData = await rootBundle.loadString('assets/$fileName');
        final lines = csvData.split('\n'); 
        final Map<String, Duration> parsedDurations = {};

        bool headerSkippedUni = false;
        for (final line in lines) {
            if (line.trim().isEmpty) continue;
            
            // Skip header row
            if (!headerSkippedUni) {
              headerSkippedUni = true;
              continue;
            }
            
            final parts = line.split(',');
            
            if (parts.isNotEmpty) {
               final currentShiftCode = parts[0].trim();
               Duration? duration;

               // New 17-column format: shift,duty,report,depart,location,startbreak,startbreaklocation,breakreport,finishbreak,finishbreaklocation,finish,finishlocation,signoff,spread,work,relief,routes
               // Use work time directly from column 14
               if (parts.length >= 15) {
                   final workTimeStr = parts.length > 14 ? parts[14].trim() : '';
                   if (workTimeStr.isNotEmpty && workTimeStr.toLowerCase() != 'nan') {
                       // Parse work time in HH:MM:SS or HH:MM format
                       final timeParts = workTimeStr.split(':');
                       if (timeParts.length >= 2) {
                           duration = Duration(
                               hours: int.parse(timeParts[0]),
                               minutes: int.parse(timeParts[1])
                           );
                       }
                   }
               }
               
               if (duration != null) {
                  parsedDurations[currentShiftCode] = duration;
               }
            }
        }

        // 3. Update cache for this file
        _csvWorkTimeCache[fileName] = parsedDurations;


        // 4. Return duration if found, otherwise null
        if (parsedDurations.containsKey(shiftCode)) {

            return parsedDurations[shiftCode];
        } else {

            return null;
        }

     } catch (e) {
       // Failed to load UNI shift work time CSV
       return null;
     }
  }

  // Calculate spread time for UNI shifts (start to finish time)
  Future<Duration?> _calculateUniSpreadTime(String shiftCode) async {
    try {
      // Only use UNI_M-F.csv for spread calculations (M-F only)
      const fileName = 'UNI_M-F.csv';
      
      // Check cache first (reuse existing spread cache)
      if (_csvSpreadTimeCache.containsKey(fileName)) {
        final cachedFile = _csvSpreadTimeCache[fileName]!;
        if (cachedFile.containsKey(shiftCode)) {
          return cachedFile[shiftCode];
        }
      }

      // Load and parse UNI_M-F.csv
      final csvData = await rootBundle.loadString('assets/$fileName');
      final lines = csvData.split('\n');
      final Map<String, Duration> parsedSpreadTimes = {};

      bool headerSkippedSpread = false;
      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        
        // Skip header row
        if (!headerSkippedSpread) {
          headerSkippedSpread = true;
          continue;
        }
        
        final parts = line.split(',');
        
        // New 17-column format: shift,duty,report,depart,location,startbreak,startbreaklocation,breakreport,finishbreak,finishbreaklocation,finish,finishlocation,signoff,spread,work,relief,routes
        if (parts.length >= 14) {
          final currentShiftCode = parts[0].trim();
          final spreadTimeStr = parts.length > 13 ? parts[13].trim() : '';
          
          // Use spread time directly from CSV column 13
          if (spreadTimeStr.isNotEmpty && spreadTimeStr.toLowerCase() != 'nan') {
            final timeParts = spreadTimeStr.split(':');
            if (timeParts.length >= 2) {
              final spreadDuration = Duration(
                hours: int.parse(timeParts[0]),
                minutes: int.parse(timeParts[1])
              );
              parsedSpreadTimes[currentShiftCode] = spreadDuration;
            }
          }
        }
      }

      // Cache the parsed data
      _csvSpreadTimeCache[fileName] = parsedSpreadTimes;

      // Return the requested duration
      return parsedSpreadTimes[shiftCode];
    } catch (e) {
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
      // Silently handle time parsing errors - invalid format
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
    // Check if this is a special Saturday service date first (takes precedence over bank holidays)
    // Dec 29-31 run Saturday service even if they're bank holidays
    if (RosterService.isSaturdayService(date)) {
      return 'SAT';
    }
    
    // Then check if it's a Bank Holiday
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

      return false;
    }
  }

  Future<Map<String, Duration>> _calculateWorkTimeStatistics() async {
    final now = DateTime.now();

    // This week (Sunday to Saturday) - Statistics always use Sunday-Saturday weeks
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
        
        // FIXED: Consistent null ID handling to prevent double-counting midnight-spanning shifts
        if (!event.isWorkShift || event.title.contains('(OT)') || processedIds.contains(event.id)) {
            continue;
        }
        processedIds.add(event.id);

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

  Future<Map<String, Duration>> _calculateSpreadStatistics() async {
    final now = DateTime.now();

    // This week (Sunday to Saturday) - Statistics always use Sunday-Saturday weeks
    final thisWeekStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday % 7));
    final thisWeekEnd = DateTime(thisWeekStart.year, thisWeekStart.month, thisWeekStart.day).add(const Duration(days: 6));

    // Last week (previous Sunday to Saturday)
    final lastWeekEnd = DateTime(thisWeekStart.year, thisWeekStart.month, thisWeekStart.day).subtract(const Duration(days: 1));
    final lastWeekStart = DateTime(lastWeekEnd.year, lastWeekEnd.month, lastWeekEnd.day).subtract(const Duration(days: 6));

    // This month
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final thisMonthEnd = (now.month < 12)
        ? DateTime(now.year, now.month + 1, 1)
        : DateTime(now.year + 1, 1, 1);

    // Last month (not used in current implementation but keeping for future expansion)
    // final lastMonthStart = (now.month > 1)
    //     ? DateTime(now.year, now.month - 1, 1)
    //     : DateTime(now.year - 1, 12, 1);
    // final lastMonthEnd = thisMonthStart;

    Duration thisWeekSpread = Duration.zero;
    Duration lastWeekSpread = Duration.zero;
    Duration thisMonthSpread = Duration.zero;

    Set<String> processedIds = {};

    for (final entry in widget.events.entries) {
      final date = entry.key;
      final events = entry.value;

      final normalizedDate = DateTime.utc(date.year, date.month, date.day);

      // Skip if this is a rest day (respects marked-in status)
      final bool isRest = await _isRestDay(normalizedDate);

      if (isRest) {
        continue;
      }

      for (final event in events) {
        final eventNormalizedStartDate = DateTime.utc(event.startDate.year, event.startDate.month, event.startDate.day);
        
        // Only process Monday-Friday work shifts, no duplicates, no overtime
        final dayOfWeek = event.startDate.weekday;
        if (dayOfWeek < DateTime.monday || dayOfWeek > DateTime.friday ||
            !event.isWorkShift || 
            event.title.contains('(OT)') || 
            processedIds.contains(event.id)) {
          continue;
        }
        processedIds.add(event.id);

        final spreadPay = await _calculateSpreadPay(event);

        // Check This Week
        if (!eventNormalizedStartDate.isBefore(thisWeekStart) && !eventNormalizedStartDate.isAfter(thisWeekEnd)) {
          thisWeekSpread += spreadPay;
        }

        // Check Last Week
        if (!eventNormalizedStartDate.isBefore(lastWeekStart) && !eventNormalizedStartDate.isAfter(lastWeekEnd)) {
          lastWeekSpread += spreadPay;
        }

        // Check This Month
        if (!eventNormalizedStartDate.isBefore(thisMonthStart) && eventNormalizedStartDate.isBefore(thisMonthEnd)) {
          thisMonthSpread += spreadPay;
        }
      }
    }

    return {
      'thisWeek': thisWeekSpread,
      'lastWeek': lastWeekSpread,
      'thisMonth': thisMonthSpread,
    };
  }

  Future<Duration> _calculateSpreadPay(Event event) async {
    if (!event.isWorkShift) {
      return Duration.zero;
    }

    // For spare duties and 22B/01 - no spread pay (they're typically shorter shifts)
    if (event.title.startsWith('SP') || event.title == '22B/01') {
      return Duration.zero;
    }

    final spreadTime = await _calculateSpreadTime(event);
    if (spreadTime == null) {
      return Duration.zero;
    }

    // Calculate spread pay: anything over 10 hours
    const tenHours = Duration(hours: 10);
    if (spreadTime > tenHours) {
      return spreadTime - tenHours;
    }

    return Duration.zero;
  }

  Future<Duration?> _calculateSpreadTime(Event event) async {
    final shiftCode = event.title;

    try {
      // Handle different shift types similar to _calculateWorkTime
      bool isBusCheck = false;
      bool isUniShift = false;
      String fileName = '';
      String zoneNumber = '1';
      String dayOfWeek = '';

      // BusCheck shifts
      if (shiftCode.startsWith('BC')) {
        isBusCheck = true;
        fileName = 'buscheck.csv';
      }
      // UNI shifts (identified by pattern like 307/01, 807/90, etc.)
      else if (RegExp(r'^\d+/').firstMatch(shiftCode) != null) {
        isUniShift = true;
        // For UNI shifts, we calculate spread from start to finish time
        return await _calculateUniSpreadTime(shiftCode);
      }
      // PZ shifts
      else {
        final match = RegExp(r'PZ(\d+)/').firstMatch(shiftCode);
        if (match != null) {
          zoneNumber = match.group(1) ?? '1';
        }
        fileName = RosterService.getShiftFilename(zoneNumber, dayOfWeek, event.startDate);
      }

      if (fileName.isEmpty && !isUniShift) {
        return null;
      }


      // Check cache first
      if (_csvSpreadTimeCache.containsKey(fileName)) {
        final cachedFile = _csvSpreadTimeCache[fileName]!;
        if (cachedFile.containsKey(shiftCode)) {
          return cachedFile[shiftCode];
        }
      }

      // Load and parse the CSV file
      final csvData = await rootBundle.loadString('assets/$fileName');
      final lines = csvData.split('\n');
      final Map<String, Duration> parsedSpreadTimes = {};
      bool headerSkipped = false;

      for (final line in lines) {
        if (line.trim().isEmpty) continue;

        // Skip header row for buscheck.csv
        if (isBusCheck && !headerSkipped) {
          headerSkipped = true;
          continue;
        }

        final parts = line.split(',');
        String currentShiftCode = parts[0].trim();
        Duration? duration;

        try {
          if (isBusCheck) {
            // BusCheck doesn't have spread data in the same format
            return null;
          } else {
            // PZ_DUTIES files: shift,duty,...,spread,work,... (spread is index 13)
            if (parts.length > 13) {
              if (currentShiftCode == shiftCode) {
                final spreadTimeStr = parts[13].trim();
                final timeParts = spreadTimeStr.split(':');
                if (timeParts.length >= 2) {
                  duration = Duration(
                    hours: int.parse(timeParts[0]),
                    minutes: int.parse(timeParts[1])
                  );
                }
              }
            }
          }

          if (duration != null) {
            parsedSpreadTimes[currentShiftCode] = duration;
          }
        } catch (e) {
          // Error processing line - continue
        }
      }

      // Cache the parsed data
      _csvSpreadTimeCache[fileName] = parsedSpreadTimes;

      // Return the requested duration
      return parsedSpreadTimes[shiftCode];
    } catch (e) {
      return null;
    }
  }

  Map<String, int> _getMostFrequentBuses() {
    Map<String, int> busCounts = {};
    Set<String> processedIds = {}; // Add duplicate prevention
    
    widget.events.forEach((date, events) {
      for (final event in events) {
        // FIXED: Added duplicate prevention for midnight-spanning events
        if (processedIds.contains(event.id)) continue;
        processedIds.add(event.id);

        // Use getAllBusesUsed() to get all buses (primary + breakdown buses) for statistics
        final allBuses = event.getAllBusesUsed();
        for (final busNumber in allBuses) {
          if (busNumber.isNotEmpty) {
            if (busCounts.containsKey(busNumber)) {
              busCounts[busNumber] = busCounts[busNumber]! + 1;
            } else {
              busCounts[busNumber] = 1;
            }
          }
        }
      }
    });
    
    // Sort by frequency (highest to lowest)
    final sortedEntries = busCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return Map.fromEntries(sortedEntries);
  }

  // Helper method to check if a shift is a workout shift
  bool _isWorkoutShift(Event event) {
    try {
      // We can't use async methods in this context, so we'll use a heuristic
      // based on common workout shift patterns. This is the same approach used elsewhere
      // in the codebase for performance reasons.
      
      // Common workout shift patterns - duties that are typically workouts
      // This is a simplified check - the full check would require async break time lookup
      final title = event.title.toLowerCase();
      
      // Check for common workout patterns (you may need to adjust these based on your data)
      if (title.contains('workout') || 
          title.contains('wo') ||
          // Add other patterns as needed
          false) {
        return true;
      }
      
      // For now, we'll return false and let the system handle it as a regular shift
      // The overtime detection is the more important fix for the user's immediate need
      return false;
    } catch (e) {
      return false;
    }
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
        // Only include rostered work shifts, exclude overtime shifts
        if (event.isWorkShift && !event.title.contains('(OT)')) {
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
                          style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
        ),
      );
    }).toList();
  }

  // --- Add Calculation Logic for Start Hour Frequency --- 
  Map<String, int> _getMostFrequentStartHours() {
    Map<int, int> hourCounts = {}; // Use int as key initially
    Set<String> processedIds = {}; // Add duplicate prevention

    widget.events.forEach((date, events) {
      for (final event in events) {
        // FIXED: Added duplicate prevention for midnight-spanning events and exclude overtime shifts
        if (!event.isWorkShift || event.title.contains('(OT)') || processedIds.contains(event.id)) continue;
        processedIds.add(event.id);

        final startHour = event.startTime.hour;
        hourCounts[startHour] = (hourCounts[startHour] ?? 0) + 1;
      }
    });

    // Convert to sorted Map<String, int> with formatted hour string
    final sortedEntries = hourCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value)); // Sort by count descending
    
    // Format hour as "HH:00" for display
    return Map.fromEntries(sortedEntries.map((entry) {
      final hourString = "${entry.key.toString().padLeft(2, '0')}:00";
      return MapEntry(hourString, entry.value);
    }));
  }

  Future<void> _loadRosterSettings() async {
    final startDateString = await StorageService.getString(AppConstants.startDateKey);
    final startWeek = await StorageService.getInt(AppConstants.startWeekKey, defaultValue: 0);
    
    if (mounted) {
      setState(() {
        if (startDateString != null) {
          _startDate = DateTime.parse(startDateString);
        }
        _startWeek = startWeek;
      });
    }
  }

  Future<void> _loadMarkedInSettings() async {
    final markedInEnabled = await StorageService.getBool(AppConstants.markedInEnabledKey);
    final markedInStatus = await StorageService.getString(AppConstants.markedInStatusKey) ?? '';
    if (mounted) {
      setState(() {
        // Determine if marked-in is actually enabled (enabled flag must be true AND status must not be empty)
        _markedInEnabled = markedInEnabled && markedInStatus.isNotEmpty;
        _markedInStatus = markedInStatus.isEmpty ? 'Spare' : markedInStatus;
      });
    }
  }

  // Check if a date is a rest day, respecting marked-in status
  Future<bool> _isRestDay(DateTime date) async {
    // Check if marked in is enabled
    if (_markedInEnabled) {
      // M-F marked in logic: W on Mon-Fri, R on Sat-Sun
      // Bank holidays are REST days for M-F
      if (_markedInStatus == 'M-F') {
        // Check if this is a bank holiday
        final isBankHolidayDate = await isBankHoliday(date);
        if (isBankHolidayDate) {
          // If M-F marked in is enabled, bank holidays are always R (Rest)
          return true;
        }
        
        // weekday: 1=Monday, 2=Tuesday, ..., 6=Saturday, 7=Sunday
        final weekday = date.weekday;
        if (weekday >= 1 && weekday <= 5) {
          return false; // Work days Mon-Fri
        } else {
          return true; // Rest days Sat-Sun
        }
      }
      
      // Shift marked in: use normal roster calculation
      if (_markedInStatus == 'Shift') {
        if (_startDate == null) return false;
        final String shiftType = RosterService.getShiftForDate(date, _startDate!, _startWeek);
        return shiftType == 'R';
      }
    }
    
    // Normal roster calculation
    if (_startDate == null) return false;
    final String shiftType = RosterService.getShiftForDate(date, _startDate!, _startWeek);
    return shiftType == 'R';
  }

  // Add new method to calculate break statistics
  Map<String, dynamic> _calculateBreakStatistics() {
    // Calculating break statistics
    
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
    
    // FIXED: Get all events with late break status from the map of events with duplicate prevention
    final List<Event> eventsWithBreakStatus = [];
    final Set<String> processedIds = {}; // Add duplicate prevention
    
    widget.events.forEach((date, dayEvents) {
      for (final event in dayEvents) {
        // Only add events that haven't been processed yet (prevents midnight-spanning duplicates)
        if (event.hasLateBreak == true && !processedIds.contains(event.id)) {
          processedIds.add(event.id);
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
    
    // Break statistics calculated
    // Found events with late break status
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
  
  // Calculate sick days statistics
  Map<String, dynamic> _calculateSickDaysStatistics() {
    final DateTime now = DateTime.now();
    
    // This month
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final thisMonthEnd = (now.month < 12)
        ? DateTime(now.year, now.month + 1, 1).subtract(const Duration(days: 1))
        : DateTime(now.year + 1, 1, 1).subtract(const Duration(days: 1));
    
    // Last month
    DateTime lastMonthStart;
    DateTime lastMonthEnd;
    if (now.month > 1) {
      lastMonthStart = DateTime(now.year, now.month - 1, 1);
      lastMonthEnd = DateTime(now.year, now.month, 1).subtract(const Duration(days: 1));
    } else {
      lastMonthStart = DateTime(now.year - 1, 12, 1);
      lastMonthEnd = DateTime(now.year, 1, 1).subtract(const Duration(days: 1));
    }
    
    // Last 3 months (including current month)
    DateTime last3MonthsStart;
    if (now.month >= 3) {
      last3MonthsStart = DateTime(now.year, now.month - 2, 1);
    } else {
      last3MonthsStart = DateTime(now.year - 1, 12 + now.month - 2, 1);
    }
    final last3MonthsEnd = thisMonthEnd;
    
    // Last 6 months (including current month)
    DateTime last6MonthsStart;
    if (now.month >= 6) {
      last6MonthsStart = DateTime(now.year, now.month - 5, 1);
    } else {
      last6MonthsStart = DateTime(now.year - 1, 12 + now.month - 5, 1);
    }
    final last6MonthsEnd = thisMonthEnd;
    
    // Jan-Jun (January 1 to June 30 of current year)
    final janJunStart = DateTime(now.year, 1, 1);
    final janJunEnd = DateTime(now.year, 6, 30);
    
    // Jul-Dec (July 1 to December 31 of current year)
    final julDecStart = DateTime(now.year, 7, 1);
    final julDecEnd = DateTime(now.year, 12, 31);
    
    // This year (January 1 to December 31)
    final thisYearStart = DateTime(now.year, 1, 1);
    final thisYearEnd = DateTime(now.year, 12, 31);
    
    // Last year (January 1 to December 31 of previous year)
    final lastYearStart = DateTime(now.year - 1, 1, 1);
    final lastYearEnd = DateTime(now.year - 1, 12, 31);
    
    // Get all events with sick day status
    final List<Event> eventsWithSickDays = [];
    final Set<String> processedIds = {};
    
    widget.events.forEach((date, dayEvents) {
      for (final event in dayEvents) {
        // Only add events that have a sick day type and haven't been processed yet
        if (event.sickDayType != null && !processedIds.contains(event.id)) {
          processedIds.add(event.id);
          eventsWithSickDays.add(event);
        }
      }
    });
    
    // Calculate statistics for each period
    return {
      'thismonth': _calculateSickDaysStatsForPeriod(eventsWithSickDays, thisMonthStart, thisMonthEnd),
      'lastmonth': _calculateSickDaysStatsForPeriod(eventsWithSickDays, lastMonthStart, lastMonthEnd),
      'last3months': _calculateSickDaysStatsForPeriod(eventsWithSickDays, last3MonthsStart, last3MonthsEnd),
      'last6months': _calculateSickDaysStatsForPeriod(eventsWithSickDays, last6MonthsStart, last6MonthsEnd),
      'janjun': _calculateSickDaysStatsForPeriod(eventsWithSickDays, janJunStart, janJunEnd),
      'juldec': _calculateSickDaysStatsForPeriod(eventsWithSickDays, julDecStart, julDecEnd),
      'thisyear': _calculateSickDaysStatsForPeriod(eventsWithSickDays, thisYearStart, thisYearEnd),
      'lastyear': _calculateSickDaysStatsForPeriod(eventsWithSickDays, lastYearStart, lastYearEnd),
    };
  }
  
  Map<String, dynamic> _calculateSickDaysStatsForPeriod(
    List<Event> events, DateTime startDate, DateTime endDate) {
    
    // Filter by date range
    final filteredEvents = events.where((event) {
      final eventDate = DateTime(event.startDate.year, event.startDate.month, event.startDate.day);
      return !eventDate.isBefore(startDate) && !eventDate.isAfter(endDate);
    }).toList();
    
    // Count by type
    int total = filteredEvents.length;
    int normal = filteredEvents.where((e) => e.sickDayType == 'normal').length;
    int selfCertified = filteredEvents.where((e) => e.sickDayType == 'self-certified').length;
    int forceMajeure = filteredEvents.where((e) => e.sickDayType == 'force-majeure').length;
    
    return {
      'total': total,
      'normal': normal,
      'selfCertified': selfCertified,
      'forceMajeure': forceMajeure,
    };
  }

  // Calculate holiday days statistics
  Future<Map<String, dynamic>> _calculateHolidayDaysStatistics() async {
    final DateTime now = DateTime.now();
    
    // Get all holidays
    final List<Holiday> holidays = await HolidayService.getHolidays();
    
    // Calculate statistics for each year (current year ± 2 years)
    final Map<String, dynamic> stats = {};
    final currentYear = now.year;
    
    for (int yearOffset = -2; yearOffset <= 2; yearOffset++) {
      final year = currentYear + yearOffset;
      final yearStart = DateTime(year, 1, 1);
      final yearEnd = DateTime(year, 12, 31);
      stats[year.toString()] = await _calculateHolidayDaysStatsForPeriod(holidays, yearStart, yearEnd);
    }
    
    return stats;
  }
  
  Future<Map<String, dynamic>> _calculateHolidayDaysStatsForPeriod(
    List<Holiday> holidays, DateTime startDate, DateTime endDate) async {
    
    int totalDays = 0;
    int summerDays = 0;
    int winterDays = 0;
    int unpaidLeaveDays = 0;
    int dayInLieuDays = 0;
    int otherDays = 0;
    
    // Check if user is on M-F schedule
    final isMFSchedule = _markedInEnabled && _markedInStatus == 'M-F';
    
    // Normalize dates to midnight for comparison
    final normalizedStart = DateTime(startDate.year, startDate.month, startDate.day);
    final normalizedEnd = DateTime(endDate.year, endDate.month, endDate.day);
    
    for (final holiday in holidays) {
      // Normalize holiday dates
      final holidayStart = DateTime(holiday.startDate.year, holiday.startDate.month, holiday.startDate.day);
      final holidayEnd = DateTime(holiday.endDate.year, holiday.endDate.month, holiday.endDate.day);
      
      // Check if holiday overlaps with the period
      if (holidayEnd.isBefore(normalizedStart) || holidayStart.isAfter(normalizedEnd)) {
        continue; // No overlap
      }
      
      // Calculate the overlap
      final overlapStart = holidayStart.isAfter(normalizedStart) ? holidayStart : normalizedStart;
      final overlapEnd = holidayEnd.isBefore(normalizedEnd) ? holidayEnd : normalizedEnd;
      
      // Calculate days in overlap (inclusive)
      final daysInOverlap = overlapEnd.difference(overlapStart).inDays + 1;
      
      if (daysInOverlap > 0) {
        int countedDays;
        
        // For M-F schedules: exclude bank holidays from the count
        if (isMFSchedule && (holiday.type == 'summer' || holiday.type == 'winter' || holiday.type == 'other')) {
          // Count only working days (Mon-Fri), excluding bank holidays
          int workingDays = 0;
          DateTime currentDate = overlapStart;
          while (!currentDate.isAfter(overlapEnd)) {
            final weekday = currentDate.weekday;
            // Count only Monday-Friday (weekday 1-5)
            if (weekday >= 1 && weekday <= 5) {
              // Check if it's a bank holiday - exclude if it is
              final isBankHolidayDate = await isBankHoliday(currentDate);
              if (!isBankHolidayDate) {
                workingDays++;
              }
            }
            currentDate = currentDate.add(const Duration(days: 1));
          }
          countedDays = workingDays;
        } else {
          // For non-M-F schedules or other holiday types: use original calculation
          // For summer and winter weeks: count 5 days per week (since 2 rest days are already accounted for)
          // For other holidays: count all days normally
          if (holiday.type == 'summer' || holiday.type == 'winter') {
            // Calculate as 5 days per week
            // For a full week (7 days), count as 5 days
            // For partial weeks, calculate proportionally: (days / 7) * 5
            countedDays = ((daysInOverlap / 7) * 5).round();
          } else if (holiday.type == 'unpaid_leave') {
            // Unpaid leave counts all days normally
            countedDays = daysInOverlap;
          } else if (holiday.type == 'day_in_lieu') {
            // Day In Lieu counts all days normally
            countedDays = daysInOverlap;
          } else {
            // Other holidays count all days normally
            countedDays = daysInOverlap;
          }
        }
        
        // Add to appropriate category
        if (holiday.type == 'summer') {
          summerDays += countedDays;
        } else if (holiday.type == 'winter') {
          winterDays += countedDays;
        } else if (holiday.type == 'unpaid_leave') {
          unpaidLeaveDays += countedDays;
        } else if (holiday.type == 'day_in_lieu') {
          dayInLieuDays += countedDays;
        } else {
          otherDays += countedDays;
        }
        
        totalDays += countedDays;
      }
    }
    
    return {
      'total': totalDays,
      'summer': summerDays,
      'winter': winterDays,
      'unpaidLeave': unpaidLeaveDays,
      'dayInLieu': dayInLieuDays,
      'other': otherDays,
    };
  }

  // Calculate monthly trends for the last 12 months
  Future<Map<String, Duration>> _calculateMonthlyTrends() async {
    final now = DateTime.now();
    final Map<String, Duration> monthlyData = {};
    
    // Calculate for last 12 months
    for (int i = 11; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      final monthStart = DateTime(monthDate.year, monthDate.month, 1);
      final monthEnd = monthDate.month < 12
          ? DateTime(monthDate.year, monthDate.month + 1, 1)
          : DateTime(monthDate.year + 1, 1, 1);
      
      Duration monthWork = Duration.zero;
      Set<String> processedIds = {};
      
      for (final entry in widget.events.entries) {
        final date = entry.key;
        final events = entry.value;
        final normalizedDate = DateTime.utc(date.year, date.month, date.day);
        
        // Skip rest days
        final String shiftType = (_startDate != null)
            ? RosterService.getShiftForDate(normalizedDate, _startDate!, _startWeek)
            : '';
        if (shiftType == 'R') continue;
        
        for (final event in events) {
          final eventNormalizedStartDate = DateTime.utc(
            event.startDate.year,
            event.startDate.month,
            event.startDate.day,
          );
          
          if (!event.isWorkShift ||
              event.title.contains('(OT)') ||
              processedIds.contains(event.id)) {
            continue;
          }
          processedIds.add(event.id);
          
          // Check if event is in this month
          if (!eventNormalizedStartDate.isBefore(monthStart) &&
              eventNormalizedStartDate.isBefore(monthEnd)) {
            final workTime = await _calculateWorkTime(event);
            monthWork += workTime;
          }
        }
      }
      
      final monthKey = '${monthDate.year}-${monthDate.month.toString().padLeft(2, '0')}';
      monthlyData[monthKey] = monthWork;
    }
    
    return monthlyData;
  }

  Widget _buildHolidayBalanceCard() {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final dayInLieuColor = ColorCustomizationService.getColorForShift('DAY_IN_LIEU');
    final hasZeroAnnualLeave = _annualLeaveRemaining == 0;
    final hasZeroDaysInLieu = _daysInLieuRemaining == 0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Annual Leave Section
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Annual Leave',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Remaining',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$_annualLeaveRemaining',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: hasZeroAnnualLeave ? Colors.orange : primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Theme.of(context).dividerColor,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Used (Future)',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$_annualLeaveUsed',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).textTheme.headlineMedium?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (hasZeroAnnualLeave)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orange,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'No days remaining. Only future holidays count toward used days.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            // Divider between sections
            const Divider(height: 24),
            // Days In Lieu Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Days In Lieu',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Remaining',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$_daysInLieuRemaining',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: hasZeroDaysInLieu ? Colors.orange : dayInLieuColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Theme.of(context).dividerColor,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Used',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$_daysInLieuUsed',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).textTheme.headlineMedium?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (hasZeroDaysInLieu)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'No days remaining.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            // Common message at bottom
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Update balances in Settings > Holidays & Leave.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Export statistics
  Future<void> _exportStatistics() async {
    try {
      // Get current statistics
      final workTimeStats = await _workTimeStatsFuture ?? {};
      final shiftTypeStats = _calculateSummaryStatistics();
      final breakStats = _calculateBreakStatistics();
      
      // Convert shift type stats to Map<String, int>
      final shiftTypeMap = <String, int>{
        'Early': shiftTypeStats['earlyShifts'] ?? 0,
        'Relief': shiftTypeStats['reliefShifts'] ?? 0,
        'Late': shiftTypeStats['lateShifts'] ?? 0,
        'Night': shiftTypeStats['nightShifts'] ?? 0,
        'Spare': shiftTypeStats['spareShifts'] ?? 0,
        'Bogey': shiftTypeStats['bogeyShifts'] ?? 0,
        'Overtime': shiftTypeStats['overtimeShifts'] ?? 0,
      };
      
      // Generate text summary
      final summary = StatisticsExportService.generateTextSummary(
        workTimeStats: workTimeStats,
        shiftTypeStats: shiftTypeMap,
        breakStats: breakStats,
      );
      
      // Share the summary
      if (mounted) {
        await Share.share(summary, subject: 'Shift Statistics Export');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting statistics: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
