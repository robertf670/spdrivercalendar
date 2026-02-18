import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spdrivercalendar/models/shift_info.dart';
import 'package:spdrivercalendar/features/calendar/services/event_service.dart';
import 'package:spdrivercalendar/features/calendar/services/roster_service.dart';
import 'package:spdrivercalendar/models/event.dart';
import 'package:spdrivercalendar/models/holiday.dart';
import 'package:spdrivercalendar/models/bank_holiday.dart';
import 'package:spdrivercalendar/services/color_customization_service.dart';
import 'package:spdrivercalendar/core/services/storage_service.dart';
import 'package:spdrivercalendar/core/constants/app_constants.dart';
import 'package:spdrivercalendar/services/rest_day_swap_service.dart';

// Cached data structure for a single day
class _DayCellData {
  final String shift;
  final ShiftInfo? shiftInfo;
  final List<Event> events;
  final BankHoliday? bankHoliday;
  final Holiday? holiday;
  final Holiday? dayInLieuHoliday;
  final Holiday? unpaidLeaveHoliday;
  final bool isSaturdayService;
  final bool hasWfoEvent;
  final Color? cellColor;
  final Color eventDotColor;
  final bool hasSickDay;
  final Color? sickDayColor;

  _DayCellData({
    required this.shift,
    this.shiftInfo,
    required this.events,
    this.bankHoliday,
    this.holiday,
    this.dayInLieuHoliday,
    this.unpaidLeaveHoliday,
    required this.isSaturdayService,
    required this.hasWfoEvent,
    this.cellColor,
    required this.eventDotColor,
    required this.hasSickDay,
    this.sickDayColor,
  });
}

class YearViewScreen extends StatefulWidget {
  final int year;
  final Map<String, ShiftInfo> shiftInfoMap;
  final DateTime? startDate;
  final int startWeek;
  final List<Holiday> holidays;
  final List<BankHoliday>? bankHolidays;

  const YearViewScreen({
    super.key,
    required this.year,
    required this.shiftInfoMap,
    this.startDate,
    this.startWeek = 0,
    required this.holidays,
    this.bankHolidays,
  });

  @override
  YearViewScreenState createState() => YearViewScreenState();
}

class YearViewScreenState extends State<YearViewScreen> {
  static const Color holidayColor = Color(0xFF00BCD4); // Teal color for holidays
  late int _currentYear; // Store year in state to avoid closure issues
  bool _markedInEnabled = false;
  String _markedInStatus = 'Shift';
  
  // Progressive loading state
  final Set<int> _loadedMonths = {}; // Track which months have finished loading
  bool _isInitialLoad = true; // Track if this is the first load
  
  // Caching system
  Map<String, _DayCellData> _dayCellCache = {}; // Cache key: "year-month-day"
  Map<String, BankHoliday> _bankHolidayMap = {}; // Pre-indexed bank holidays
  Map<String, List<Holiday>> _holidayMap = {}; // Pre-indexed holidays by date
  Map<String, bool> _saturdayServiceCache = {}; // Cache Saturday service checks
  
  // Pre-computed colors (avoid repeated lookups)
  final Color _dayInLieuColor = ColorCustomizationService.getColorForShift('DAY_IN_LIEU');
  final Color _unpaidLeaveColor = Colors.purple;
  final Color _winterHolidayColor = Colors.blue;
  final Color _summerHolidayColor = Colors.orange;
  final Color _otherHolidayColor = Colors.green;

  @override
  void initState() {
    super.initState();
    _currentYear = widget.year;
    _buildIndexes();
    // Load settings first, then build cache
    _loadMarkedInSettings().then((_) {
      if (mounted) {
        _preloadMonthsProgressive();
      }
    });
  }

  void _buildIndexes() {
    // Pre-index bank holidays for O(1) lookup
    _bankHolidayMap.clear();
    if (widget.bankHolidays != null) {
      for (final bh in widget.bankHolidays!) {
        final key = _getDateKey(bh.date);
        _bankHolidayMap[key] = bh;
      }
    }
    
    // Pre-index holidays by date for O(1) lookup
    _holidayMap.clear();
    for (final holiday in widget.holidays) {
      // Add holiday to all dates it spans
      final start = DateTime(holiday.startDate.year, holiday.startDate.month, holiday.startDate.day);
      final end = DateTime(holiday.endDate.year, holiday.endDate.month, holiday.endDate.day);
      var current = start;
      while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
        final key = _getDateKey(current);
        _holidayMap.putIfAbsent(key, () => []).add(holiday);
        current = current.add(const Duration(days: 1));
      }
    }
  }

  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }

  Future<void> _loadMarkedInSettings() async {
    final markedInEnabled = await StorageService.getBool(AppConstants.markedInEnabledKey);
    final markedInStatus = await StorageService.getString(AppConstants.markedInStatusKey) ?? '';
    if (mounted) {
      // Check if M-F settings changed
      final newMarkedInEnabled = markedInEnabled && markedInStatus.isNotEmpty;
      final newMarkedInStatus = markedInStatus.isEmpty ? 'Spare' : markedInStatus;
      final settingsChanged = _markedInEnabled != newMarkedInEnabled || 
                              _markedInStatus != newMarkedInStatus;
      
      setState(() {
        // Determine if marked-in is actually enabled (enabled flag must be true AND status must not be empty)
        _markedInEnabled = newMarkedInEnabled;
        _markedInStatus = newMarkedInStatus;
      });
      
      // If M-F settings changed, clear cache and rebuild
      if (settingsChanged) {
        _dayCellCache.clear();
        _loadedMonths.clear();
        _isInitialLoad = true;
        if (mounted) {
          _preloadMonthsProgressive();
        }
      }
    }
  }

  @override
  void didUpdateWidget(YearViewScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update state if year changed
    if (oldWidget.year != widget.year) {
      _currentYear = widget.year;
      _loadedMonths.clear();
      _dayCellCache.clear();
      _saturdayServiceCache.clear();
      _isInitialLoad = true;
      _buildIndexes();
      _preloadMonthsProgressive();
    }
    // Reload marked-in settings in case they changed
    if (oldWidget.holidays != widget.holidays || 
        oldWidget.bankHolidays != widget.bankHolidays) {
      _buildIndexes();
      _dayCellCache.clear(); // Clear cache when holidays change
    }
    _loadMarkedInSettings();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload marked-in settings when screen becomes visible again
    // This ensures settings are fresh when navigating back to the screen
    _loadMarkedInSettings();
  }

  Future<void> _preloadMonthsProgressive() async {
    // Load months progressively - show them as they finish loading
    // This provides immediate feedback instead of blocking until all 12 are ready
    
    // Start loading all months in parallel
    final futures = <Future>[];
    for (int month = 1; month <= 12; month++) {
      final date = DateTime(_currentYear, month, 1);
      final future = EventService.preloadMonth(date).then((_) {
        if (mounted) {
          setState(() {
            _loadedMonths.add(month);
            // Build cache for this month
            _buildMonthCache(month);
          });
        }
      }).catchError((_) {
        // Still mark as loaded even if there's an error
        if (mounted) {
          setState(() {
            _loadedMonths.add(month);
          });
        }
      });
      futures.add(future);
    }
    
    // Don't wait for all - let them complete progressively
    // This allows UI to update as months finish loading
    _isInitialLoad = false;
    if (mounted) {
      setState(() {});
    }
  }

  void _buildMonthCache(int month) {
    // Pre-compute and cache all day cell data for a month
    final daysInMonth = DateTime(_currentYear, month + 1, 0).day;
    
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_currentYear, month, day);
      final key = _getDateKey(date);
      
      // Skip if already cached
      if (_dayCellCache.containsKey(key)) continue;
      
      // Compute all data for this day
      final shift = _getShiftForDate(date);
      final shiftInfo = widget.shiftInfoMap[shift];
      final events = EventService.getEventsForDay(date);
      final bankHoliday = _bankHolidayMap[key];
      
      // Get holidays for this date (O(1) lookup)
      final dateHolidays = _holidayMap[key] ?? [];
      final holiday = dateHolidays.isNotEmpty ? dateHolidays.first : null;
      final dayInLieuHoliday = dateHolidays.firstWhere(
        (h) => h.type == 'day_in_lieu',
        orElse: () => Holiday(id: '', startDate: DateTime.now(), endDate: DateTime.now(), type: ''),
      );
      final unpaidLeaveHoliday = dateHolidays.firstWhere(
        (h) => h.type == 'unpaid_leave',
        orElse: () => Holiday(id: '', startDate: DateTime.now(), endDate: DateTime.now(), type: ''),
      );
      
      // Cache Saturday service check
      final saturdayServiceKey = '${date.year}-${date.month}-${date.day}';
      if (!_saturdayServiceCache.containsKey(saturdayServiceKey)) {
        _saturdayServiceCache[saturdayServiceKey] = RosterService.isSaturdayService(date);
      }
      final isSaturdayService = _saturdayServiceCache[saturdayServiceKey]!;
      
      // Check for WFO event
      final hasWfoEvent = events.any((event) => event.isWorkForOthers);
      final wfoColor = widget.shiftInfoMap['WFO']?.color;
      
      // Check for sick day
      final sickDayEvent = events.firstWhere(
        (event) => event.sickDayType != null,
        orElse: () => Event(
          id: '',
          title: '',
          startDate: date,
          startTime: const TimeOfDay(hour: 0, minute: 0),
          endDate: date,
          endTime: const TimeOfDay(hour: 0, minute: 0),
          isHoliday: false,
          hasLateBreak: false,
          tookFullBreak: false,
          isWorkForOthers: false,
        ),
      );
      final hasSickDay = sickDayEvent.sickDayType != null;
      final sickDayColor = hasSickDay 
          ? ColorCustomizationService.getColorForSickType(sickDayEvent.sickDayType) 
          : null;
      
      // Determine holiday color
      Color holidayColorValue = _otherHolidayColor;
      if (holiday != null) {
        switch (holiday.type) {
          case 'winter':
            holidayColorValue = _winterHolidayColor;
            break;
          case 'summer':
            holidayColorValue = _summerHolidayColor;
            break;
          case 'other':
            holidayColorValue = _otherHolidayColor;
            break;
        }
      }
      
      // Rest day color takes precedence when holiday falls on a rest day
      final isRestDay = shift == 'R';
      final useRestDayColorForHoliday = isRestDay &&
          shiftInfo != null &&
          (dayInLieuHoliday.id.isNotEmpty || unpaidLeaveHoliday.id.isNotEmpty || holiday != null);

      // Determine cell color
      Color? cellColor;
      if (hasSickDay && sickDayColor != null) {
        cellColor = sickDayColor.withValues(alpha: 0.3);
      } else if (useRestDayColorForHoliday) {
        cellColor = shiftInfo.color.withValues(alpha: 0.3);
      } else if (dayInLieuHoliday.id.isNotEmpty) {
        cellColor = _dayInLieuColor.withValues(alpha: 0.3);
      } else if (unpaidLeaveHoliday.id.isNotEmpty) {
        cellColor = _unpaidLeaveColor.withValues(alpha: 0.3);
      } else if (holiday != null) {
        cellColor = holidayColorValue.withValues(alpha: 0.3);
      } else if (hasWfoEvent && wfoColor != null) {
        cellColor = wfoColor.withValues(alpha: 0.3);
      } else if (shiftInfo != null) {
        cellColor = shiftInfo.color.withValues(alpha: 0.3);
      }
      
      // Determine event dot color
      Color eventDotColor = Colors.grey;
      if (hasSickDay && sickDayColor != null) {
        eventDotColor = sickDayColor;
      } else if (useRestDayColorForHoliday) {
        eventDotColor = shiftInfo.color;
      } else if (dayInLieuHoliday.id.isNotEmpty) {
        eventDotColor = _dayInLieuColor;
      } else if (unpaidLeaveHoliday.id.isNotEmpty) {
        eventDotColor = _unpaidLeaveColor;
      } else if (holiday != null) {
        eventDotColor = holidayColorValue;
      } else if (hasWfoEvent && wfoColor != null) {
        eventDotColor = wfoColor;
      } else if (shiftInfo != null) {
        eventDotColor = shiftInfo.color;
      }
      
      // Cache the computed data
      _dayCellCache[key] = _DayCellData(
        shift: shift,
        shiftInfo: shiftInfo,
        events: events,
        bankHoliday: bankHoliday,
        holiday: holiday,
        dayInLieuHoliday: dayInLieuHoliday.id.isNotEmpty ? dayInLieuHoliday : null,
        unpaidLeaveHoliday: unpaidLeaveHoliday.id.isNotEmpty ? unpaidLeaveHoliday : null,
        isSaturdayService: isSaturdayService,
        hasWfoEvent: hasWfoEvent,
        cellColor: cellColor,
        eventDotColor: eventDotColor,
        hasSickDay: hasSickDay,
        sickDayColor: sickDayColor,
      );
    }
  }

  String _getRosterShiftForDate(DateTime date) {
    if (widget.startDate == null) return '';
    if (_markedInEnabled) {
      if (_markedInStatus == 'M-F') {
        final key = _getDateKey(date);
        if (_bankHolidayMap.containsKey(key)) return 'R';
        final weekday = date.weekday;
        if (weekday >= 1 && weekday <= 5) return 'W';
        return 'R';
      }
      if (_markedInStatus == 'Shift') {
        return RosterService.getShiftForDate(date, widget.startDate!, widget.startWeek);
      }
    }
    return RosterService.getShiftForDate(date, widget.startDate!, widget.startWeek);
  }

  String _getShiftForDate(DateTime date) {
    return RestDaySwapService.getShiftForDate(
      date,
      startDate: widget.startDate,
      startWeek: widget.startWeek,
      rosterGetter: _getRosterShiftForDate,
    ).shift;
  }

  bool isToday(DateTime date) {
    final today = DateTime.now();
    return date.year == today.year && 
           date.month == today.month && 
           date.day == today.day;
  }

  @override
  Widget build(BuildContext context) {
    // Force rebuild when year changes by using a key
    return Scaffold(
      key: ValueKey('year_view_$_currentYear'),
      appBar: AppBar(
        title: Text('Year View - $_currentYear'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: 'Go to Current Year',
            onPressed: () {
              final currentYear = DateTime.now().year;
              if (currentYear != _currentYear) {
                setState(() {
                  _currentYear = currentYear;
                  _loadedMonths.clear();
                  _dayCellCache.clear();
                  _saturdayServiceCache.clear();
                  _isInitialLoad = true;
                });
                _buildIndexes();
                _preloadMonthsProgressive();
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Year navigation header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
                    spreadRadius: 0,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () {
                        setState(() {
                          _currentYear = _currentYear - 1;
                          _loadedMonths.clear();
                          _dayCellCache.clear();
                          _saturdayServiceCache.clear();
                          _isInitialLoad = true;
                        });
                        _buildIndexes();
                        _preloadMonthsProgressive();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.chevron_left,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4),
                          Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.2),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '$_currentYear',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () {
                        setState(() {
                          _currentYear = _currentYear + 1;
                          _loadedMonths.clear();
                          _dayCellCache.clear();
                          _saturdayServiceCache.clear();
                          _isInitialLoad = true;
                        });
                        _buildIndexes();
                        _preloadMonthsProgressive();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.chevron_right,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Progressive loading indicator or grid
            Expanded(
              child: _isInitialLoad && _loadedMonths.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            'Loading calendar...',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        // Determine number of columns based on screen width
                        final screenWidth = constraints.maxWidth;
                        int crossAxisCount = 3; // Default to 3 columns
                        if (screenWidth > 900) {
                          crossAxisCount = 4; // 4 columns on very large screens
                        } else if (screenWidth < 600) {
                          crossAxisCount = 2; // 2 columns on small screens
                        }
                        
                        // Calculate responsive values based on screen width
                        final isSmallScreen = screenWidth < 600;
                        final isLargeScreen = screenWidth > 900;
                        
                        // Responsive spacing
                        final gridPadding = isSmallScreen ? 6.0 : (isLargeScreen ? 12.0 : 8.0);
                        final gridSpacing = isSmallScreen ? 6.0 : (isLargeScreen ? 12.0 : 8.0);
                        
                        // Responsive aspect ratio (smaller screens need taller cells)
                        final aspectRatio = isSmallScreen ? 0.92 : (isLargeScreen ? 0.98 : 0.95);
                        
                        return SingleChildScrollView(
                          padding: EdgeInsets.all(gridPadding),
                          child: GridView.builder(
                            key: ValueKey('year_grid_$_currentYear'), // Force rebuild when year changes
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: gridSpacing,
                              mainAxisSpacing: gridSpacing,
                              childAspectRatio: aspectRatio,
                            ),
                            itemCount: 12,
                            itemBuilder: (context, index) {
                              final month = index + 1;
                              final currentYear = _currentYear;
                              final isLoaded = _loadedMonths.contains(month);
                              
                              // Show loading placeholder for months not yet loaded
                              if (!isLoaded) {
                                return _buildLoadingPlaceholder(month, screenWidth);
                              }
                              
                              // Wrap each month in RepaintBoundary for performance
                              return RepaintBoundary(
                                child: _buildMonthCalendar(month, currentYear, screenWidth),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingPlaceholder(int month, double screenWidth) {
    final isSmallScreen = screenWidth < 600;
    final isLargeScreen = screenWidth > 900;
    final monthPadding = isSmallScreen ? 8.0 : (isLargeScreen ? 12.0 : 10.0);
    final monthDate = DateTime(_currentYear, month, 1);
    final monthName = DateFormat('MMMM').format(monthDate);
    
    return Container(
      padding: EdgeInsets.all(monthPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(height: 8),
          Text(
            monthName.toUpperCase(),
            style: TextStyle(
              fontSize: isSmallScreen ? 11.0 : (isLargeScreen ? 13.0 : 12.0),
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthCalendar(int month, [int? explicitYear, double? screenWidth]) {
    // Use explicit year if provided, otherwise use _currentYear from state
    final currentYear = explicitYear ?? _currentYear;
    final monthDate = DateTime(currentYear, month, 1);
    final monthName = DateFormat('MMMM').format(monthDate);
    final isCurrentMonth = monthDate.year == DateTime.now().year &&
                          monthDate.month == DateTime.now().month;
    
    // Calculate responsive values based on screen width
    final isSmallScreen = screenWidth != null && screenWidth < 600;
    final isLargeScreen = screenWidth != null && screenWidth > 900;
    
    // Responsive font sizes
    final monthHeaderFontSize = isSmallScreen ? 11.0 : (isLargeScreen ? 13.0 : 12.0);
    final dayHeaderFontSize = isSmallScreen ? 8.0 : (isLargeScreen ? 10.0 : 9.0);
    
    // Responsive spacing
    final monthPadding = isSmallScreen ? 8.0 : (isLargeScreen ? 12.0 : 10.0);
    final monthHeaderPaddingH = isSmallScreen ? 5.0 : (isLargeScreen ? 8.0 : 6.0);
    final monthHeaderPaddingV = isSmallScreen ? 2.0 : (isLargeScreen ? 4.0 : 3.0);
    final spacingAfterHeader = isSmallScreen ? 3.0 : (isLargeScreen ? 5.0 : 4.0);
    final spacingAfterDayHeaders = isSmallScreen ? 1.0 : (isLargeScreen ? 3.0 : 2.0);
    
    // Calculate first day of month and what day of week it falls on
    // Sunday = 0, Monday = 1, ..., Saturday = 6
    final firstDayOfMonth = DateTime(currentYear, month, 1);
    final firstDayWeekday = firstDayOfMonth.weekday % 7; // Convert to Sunday-first (Sunday=0)
    
    // Get number of days in month
    final daysInMonth = DateTime(currentYear, month + 1, 0).day;
    
    // Calculate days from previous month to show
    final daysFromPreviousMonth = firstDayWeekday;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Navigate back to calendar screen with this month selected
          final yearToUse = currentYear;
          final monthToUse = month;
          
          // Create date with explicit values
          final selectedDate = DateTime(yearToUse, monthToUse, 1);
          
          // Pop back to calendar screen with the selected date
          Navigator.of(context).pop(selectedDate);
        },
        child: Container(
          padding: EdgeInsets.all(monthPadding),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCurrentMonth
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
              width: isCurrentMonth ? 2.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isCurrentMonth
                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
                spreadRadius: isCurrentMonth ? 1 : 0,
                blurRadius: isCurrentMonth ? 8 : 4,
                offset: Offset(0, isCurrentMonth ? 3 : 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Month header with better styling
              Container(
                padding: EdgeInsets.symmetric(horizontal: monthHeaderPaddingH, vertical: monthHeaderPaddingV),
                decoration: BoxDecoration(
                  color: isCurrentMonth
                      ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
                      : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  monthName.toUpperCase(),
                  style: TextStyle(
                    fontSize: monthHeaderFontSize,
                    fontWeight: FontWeight.bold,
                    color: isCurrentMonth
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              SizedBox(height: spacingAfterHeader),
            
              // Day headers (S, M, T, W, T, F, S)
              Row(
                children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) {
                  return Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: TextStyle(
                          fontSize: dayHeaderFontSize,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              
              SizedBox(height: spacingAfterDayHeaders),
            
            // Calendar grid
            ...List.generate(
              (daysFromPreviousMonth + daysInMonth + 6) ~/ 7, // Number of weeks needed
              (weekIndex) {
                return Row(
                  children: List.generate(7, (dayIndex) {
                    final dayNumber = weekIndex * 7 + dayIndex - daysFromPreviousMonth + 1;
                    
                    // Previous month days
                    if (dayNumber <= 0) {
                      final prevMonth = month == 1 ? 12 : month - 1;
                      final prevYear = month == 1 ? currentYear - 1 : currentYear;
                      final prevMonthDays = DateTime(prevYear, prevMonth + 1, 0).day;
                      final day = prevMonthDays + dayNumber;
                      final date = DateTime(prevYear, prevMonth, day);
                      return Expanded(
                        child: _buildMiniDayCell(
                          date, 
                          isCurrentMonth: false, 
                          isOutsideMonth: true,
                          screenWidth: screenWidth,
                        ),
                      );
                    }
                    
                    // Next month days
                    if (dayNumber > daysInMonth) {
                      final nextMonth = month == 12 ? 1 : month + 1;
                      final nextYear = month == 12 ? currentYear + 1 : currentYear;
                      final day = dayNumber - daysInMonth;
                      final date = DateTime(nextYear, nextMonth, day);
                      return Expanded(
                        child: _buildMiniDayCell(
                          date, 
                          isCurrentMonth: false, 
                          isOutsideMonth: true,
                          screenWidth: screenWidth,
                        ),
                      );
                    }
                    
                    // Current month days
                    final date = DateTime(currentYear, month, dayNumber);
                    return Expanded(
                      child: _buildMiniDayCell(
                        date, 
                        isCurrentMonth: isCurrentMonth, 
                        isOutsideMonth: false,
                        screenWidth: screenWidth,
                      ),
                    );
                  }),
                );
              },
            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniDayCell(
    DateTime date, {
    required bool isCurrentMonth,
    required bool isOutsideMonth,
    double? screenWidth,
  }) {
    // Calculate responsive values based on screen width
    final isSmallScreen = screenWidth != null && screenWidth < 600;
    final isLargeScreen = screenWidth != null && screenWidth > 900;
    
    // Responsive cell sizes
    final dayCellHeight = isSmallScreen ? 20.0 : (isLargeScreen ? 24.0 : 22.0);
    final dayCellMargin = isSmallScreen ? 0.3 : (isLargeScreen ? 0.7 : 0.5);
    final dayNumberFontSize = isSmallScreen ? 9.0 : (isLargeScreen ? 11.0 : 10.0);
    final eventDotSize = isSmallScreen ? 4.0 : (isLargeScreen ? 6.0 : 5.0);
    final satBadgeFontSize = isSmallScreen ? 6.0 : (isLargeScreen ? 8.0 : 7.0);
    final satBadgePaddingH = isSmallScreen ? 2.0 : (isLargeScreen ? 4.0 : 3.0);
    final satBadgePaddingV = isSmallScreen ? 0.5 : (isLargeScreen ? 1.5 : 1.0);
    final eventDotOffset = isSmallScreen ? 1.0 : (isLargeScreen ? 3.0 : 2.0);
    final satBadgeOffset = isSmallScreen ? 0.5 : (isLargeScreen ? 2.0 : 1.0);
    
    // Get cached data (O(1) lookup)
    final key = _getDateKey(date);
    final cachedData = _dayCellCache[key];
    
    // If not cached (for outside month days or not yet loaded), compute on the fly
    if (cachedData == null) {
      // For outside month days, use minimal computation
      final bankHoliday = _bankHolidayMap[key];
      final isBankHoliday = bankHoliday != null;
      
      return Opacity(
        opacity: isOutsideMonth ? 0.25 : 1.0,
        child: Container(
          margin: EdgeInsets.all(dayCellMargin),
          height: dayCellHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            border: isToday(date)
                ? Border.all(
                    color: isBankHoliday ? Colors.red : Colors.blue,
                    width: 2.5,
                  )
                : isBankHoliday
                    ? Border.all(
                        color: Colors.red,
                        width: 2,
                      )
                    : null,
          ),
          child: Center(
            child: Text(
              '${date.day}',
              style: TextStyle(
                fontSize: dayNumberFontSize,
                fontWeight: isToday(date) ? FontWeight.bold : FontWeight.w500,
                color: isToday(date) 
                    ? (isBankHoliday ? Colors.red : Colors.blue)
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ),
      );
    }
    
    // Use cached data for fast rendering
    final isBankHoliday = cachedData.bankHoliday != null;
    
    return Opacity(
      opacity: isOutsideMonth ? 0.25 : 1.0,
      child: Container(
        margin: EdgeInsets.all(dayCellMargin),
        height: dayCellHeight,
        decoration: BoxDecoration(
          color: cachedData.cellColor,
          borderRadius: BorderRadius.circular(5),
          border: isToday(date)
              ? Border.all(
                  color: isBankHoliday ? Colors.red : Colors.blue,
                  width: 2.5,
                )
              : isBankHoliday
                  ? Border.all(
                      color: Colors.red,
                      width: 2,
                    )
                  : null,
        ),
        child: Stack(
          children: [
            // Day number
            Center(
              child: Text(
                '${date.day}',
                style: TextStyle(
                  fontSize: dayNumberFontSize,
                  fontWeight: isToday(date) ? FontWeight.bold : FontWeight.w500,
                  color: isToday(date) 
                      ? (isBankHoliday ? Colors.red : Colors.blue)
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            // Saturday service indicator
            if (cachedData.isSaturdayService && !isOutsideMonth)
              Positioned(
                top: satBadgeOffset,
                left: satBadgeOffset,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: satBadgePaddingH, vertical: satBadgePaddingV),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade600,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(5),
                      bottomRight: Radius.circular(5),
                    ),
                  ),
                  child: Text(
                    'SAT',
                    style: TextStyle(
                      fontSize: satBadgeFontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      height: 1.0,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            // Event indicator dot
            if (cachedData.events.isNotEmpty && !isOutsideMonth)
              Positioned(
                bottom: eventDotOffset,
                right: eventDotOffset,
                child: Container(
                  width: eventDotSize,
                  height: eventDotSize,
                  decoration: BoxDecoration(
                    color: cachedData.eventDotColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
