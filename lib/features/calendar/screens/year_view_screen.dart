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

  @override
  void initState() {
    super.initState();
    _currentYear = widget.year; // Initialize with widget.year
    _loadMarkedInSettings();
    // Preload events for visible months only (first 3-4 months) in background
    // This allows UI to show immediately while events load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadVisibleMonths();
    });
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

  @override
  void didUpdateWidget(YearViewScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update state if year changed
    if (oldWidget.year != widget.year) {
      _currentYear = widget.year;
    }
    // Reload marked-in settings in case they changed
    _loadMarkedInSettings();
  }

  Future<void> _preloadVisibleMonths() async {
    // Only preload first few months that are likely visible
    // Events will load on-demand for other months as user scrolls
    final futures = <Future>[];
    for (int month = 1; month <= 4; month++) {
      final date = DateTime(_currentYear, month, 1);
      futures.add(EventService.preloadMonth(date).catchError((_) {}));
    }
    // Load in background without blocking
    Future.wait(futures).then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  String getShiftForDate(DateTime date) {
    if (widget.startDate == null) return '';
    
    // Check if marked in is enabled
    if (_markedInEnabled) {
      // M-F marked in logic: W on Mon-Fri, R on Sat-Sun
      // Bank holidays are REST days for M-F
      if (_markedInStatus == 'M-F') {
        // Check if this is a bank holiday
        final bankHoliday = getBankHoliday(date);
        if (bankHoliday != null) {
          // If M-F marked in is enabled, bank holidays are always R (Rest)
          return 'R';
        }
        
        // weekday: 1=Monday, 2=Tuesday, ..., 6=Saturday, 7=Sunday
        final weekday = date.weekday;
        if (weekday >= 1 && weekday <= 5) {
          return 'W'; // Work days Mon-Fri
        } else {
          return 'R'; // Rest days Sat-Sun
        }
      }
      
      // Shift marked in: use normal roster calculation
      // (Zone selection is stored but doesn't affect shift calculation here)
      if (_markedInStatus == 'Shift') {
        return RosterService.getShiftForDate(date, widget.startDate!, widget.startWeek);
      }
    }
    
    // Default or normal roster calculation
    return RosterService.getShiftForDate(date, widget.startDate!, widget.startWeek);
  }

  List<Event> getEventsForDay(DateTime date) {
    return EventService.getEventsForDay(date);
  }

  BankHoliday? getBankHoliday(DateTime date) {
    if (widget.bankHolidays == null) return null;
    try {
      return widget.bankHolidays!.firstWhere(
        (bh) => bh.date.year == date.year && 
                bh.date.month == date.month && 
                bh.date.day == date.day,
      );
    } catch (e) {
      return null;
    }
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
                });
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
                        });
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
                        });
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
            
            // Scrollable year view with all months in a grid
            Expanded(
              child: LayoutBuilder(
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
                        // Use _currentYear from state, not widget.year, to avoid closure issues
                        final currentYear = _currentYear;
                        return _buildMonthCalendar(month, currentYear, screenWidth);
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

  Widget _buildMonthCalendar(int month, [int? explicitYear, double? screenWidth]) {
    // Use explicit year if provided, otherwise use _currentYear from state
    // This ensures we use the correct year from state, not widget.year
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
          // CRITICAL: Use currentYear parameter which comes from _currentYear state variable
          // This ensures we use the correct year even after navigating between years
          final yearToUse = currentYear; // This should be 2025 if we navigated to 2025
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
    
    final shift = getShiftForDate(date);
    final shiftInfo = widget.shiftInfoMap[shift];
    final events = getEventsForDay(date);
    final bankHoliday = getBankHoliday(date);
    final isBankHoliday = bankHoliday != null;
    final isHoliday = widget.holidays.any((h) => h.containsDate(date));
    final dayInLieuHoliday = widget.holidays.firstWhere(
      (h) => h.containsDate(date) && h.type == 'day_in_lieu',
      orElse: () => Holiday(id: '', startDate: DateTime.now(), endDate: DateTime.now(), type: ''),
    );
    final isDayInLieu = dayInLieuHoliday.id.isNotEmpty;
    final unpaidLeaveHoliday = widget.holidays.firstWhere(
      (h) => h.containsDate(date) && h.type == 'unpaid_leave',
      orElse: () => Holiday(id: '', startDate: DateTime.now(), endDate: DateTime.now(), type: ''),
    );
    final isUnpaidLeave = unpaidLeaveHoliday.id.isNotEmpty;
    final isSaturdayService = RosterService.isSaturdayService(date);
    
    // Check if there's a WFO event on this day
    final hasWfoEvent = events.any((event) => event.isWorkForOthers);
    final wfoColor = widget.shiftInfoMap['WFO']?.color;
    final dayInLieuColor = ColorCustomizationService.getColorForShift('DAY_IN_LIEU');
    
    // Check for sick day events - priority over other colors
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
    final sickDayColor = hasSickDay ? ColorCustomizationService.getColorForSickType(sickDayEvent.sickDayType) : null;
    
    // Determine holiday color (needed for event dot)
    Color holidayColor = Colors.green;
    if (isHoliday) {
      final holiday = widget.holidays.firstWhere((h) => h.containsDate(date));
      switch (holiday.type) {
        case 'winter':
          holidayColor = Colors.blue;
          break;
        case 'summer':
          holidayColor = Colors.orange;
          break;
        case 'other':
          holidayColor = Colors.green;
          break;
        default:
          holidayColor = Colors.green;
      }
    }
    
    // Determine cell color
    Color? cellColor;
    if (hasSickDay && sickDayColor != null) {
      cellColor = sickDayColor.withValues(alpha: 0.3);
    } else if (isDayInLieu) {
      cellColor = dayInLieuColor.withValues(alpha: 0.3);
    } else if (isUnpaidLeave) {
      cellColor = Colors.purple.withValues(alpha: 0.3);
    } else if (isHoliday) {
      cellColor = holidayColor.withValues(alpha: 0.3);
    } else if (hasWfoEvent && wfoColor != null) {
      cellColor = wfoColor.withValues(alpha: 0.3);
    } else if (shiftInfo != null) {
      cellColor = shiftInfo.color.withValues(alpha: 0.3);
    }
    
    return Opacity(
      opacity: isOutsideMonth ? 0.25 : 1.0,
      child: Container(
        margin: EdgeInsets.all(dayCellMargin),
        height: dayCellHeight,
        decoration: BoxDecoration(
          color: cellColor,
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
            if (isSaturdayService && !isOutsideMonth)
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
                      color: Colors.white,
                      height: 1.0,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            // Event indicator dot
            if (events.isNotEmpty && !isOutsideMonth)
              Positioned(
                bottom: eventDotOffset,
                right: eventDotOffset,
                child: Container(
                  width: eventDotSize,
                  height: eventDotSize,
                  decoration: BoxDecoration(
                    color: hasSickDay && sickDayColor != null
                        ? sickDayColor
                        : isDayInLieu
                            ? dayInLieuColor
                            : isUnpaidLeave
                                ? Colors.purple
                                : isHoliday
                                    ? holidayColor
                                    : hasWfoEvent && wfoColor != null
                                        ? wfoColor
                                        : shiftInfo?.color ?? Colors.grey,
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
