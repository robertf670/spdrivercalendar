import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spdrivercalendar/models/shift_info.dart';
import 'package:spdrivercalendar/features/calendar/services/event_service.dart';
import 'package:spdrivercalendar/models/event.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';

class WeekViewScreen extends StatefulWidget {
  final DateTime selectedDate;
  final Map<String, ShiftInfo> shiftInfoMap;

  const WeekViewScreen({
    Key? key,
    required this.selectedDate,
    required this.shiftInfoMap,
  }) : super(key: key);

  @override
  WeekViewScreenState createState() => WeekViewScreenState();
}

class WeekViewScreenState extends State<WeekViewScreen> {
  late DateTime _currentWeekStart;
  late List<DateTime> _weekDays;

  @override
  void initState() {
    super.initState();
    _calculateWeekStart();
    _generateWeekDays();
  }

  void _calculateWeekStart() {
    // Calculate the start of the week (Sunday)
    // DateTime.weekday: Monday = 1, Sunday = 7
    final weekday = widget.selectedDate.weekday;
    // For Sunday-first week: Sunday = 0 days back, Monday = 1 day back, etc.
    final daysFromSunday = weekday % 7; // Sunday (7) becomes 0, Monday (1) becomes 1, etc.
    _currentWeekStart = widget.selectedDate.subtract(Duration(days: daysFromSunday));
  }

  void _generateWeekDays() {
    _weekDays = List.generate(7, (index) => _currentWeekStart.add(Duration(days: index)));
  }

  void _navigateWeek(int direction) {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(Duration(days: 7 * direction));
      _generateWeekDays();
    });
  }

  ShiftInfo? _getShiftForDate(DateTime date) {
    final dateString = DateFormat('yyyy-MM-dd').format(date);
    return widget.shiftInfoMap[dateString];
  }

  List<Event> _getEventsForDate(DateTime date) {
    return EventService.getEventsForDay(date);
  }

  bool _isToday(DateTime date) {
    final today = DateTime.now();
    return date.year == today.year && 
           date.month == today.month && 
           date.day == today.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Week View'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: 'Go to Current Week',
            onPressed: () {
              setState(() {
                final today = DateTime.now();
                final weekday = today.weekday;
                final daysFromSunday = weekday % 7;
                _currentWeekStart = today.subtract(Duration(days: daysFromSunday));
                _generateWeekDays();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Week navigation header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _navigateWeek(-1),
                ),
                Text(
                  '${DateFormat('MMM d').format(_weekDays.first)} - ${DateFormat('MMM d, yyyy').format(_weekDays.last)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _navigateWeek(1),
                ),
              ],
            ),
          ),
          
          // Week view content - Stacked layout (1-3-3)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Column(
                children: [
                  // Row 1: Sunday only (centered)
                  Expanded(
                    flex: 1,
                    child: Row(
                      children: [
                        const Expanded(child: SizedBox()), // Left spacer
                        Expanded(
                          flex: 2,
                          child: _buildDayCard(_weekDays[0]), // Sunday (first in the week starting Sunday)
                        ),
                        const Expanded(child: SizedBox()), // Right spacer
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Row 2: Monday, Tuesday, Wednesday
                  Expanded(
                    flex: 1,
                    child: Row(
                      children: [
                        Expanded(child: _buildDayCard(_weekDays[1])), // Monday
                        const SizedBox(width: 8),
                        Expanded(child: _buildDayCard(_weekDays[2])), // Tuesday
                        const SizedBox(width: 8),
                        Expanded(child: _buildDayCard(_weekDays[3])), // Wednesday
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Row 3: Thursday, Friday, Saturday
                  Expanded(
                    flex: 1,
                    child: Row(
                      children: [
                        Expanded(child: _buildDayCard(_weekDays[4])), // Thursday
                        const SizedBox(width: 8),
                        Expanded(child: _buildDayCard(_weekDays[5])), // Friday
                        const SizedBox(width: 8),
                        Expanded(child: _buildDayCard(_weekDays[6])), // Saturday
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCard(DateTime day) {
    final shift = _getShiftForDate(day);
    final events = _getEventsForDate(day);
    final workEvents = events.where((event) => event.isWorkShift).toList();
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isToday(day) 
            ? AppTheme.primaryColor 
            : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          width: _isToday(day) ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Day header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: _isToday(day) 
                ? AppTheme.primaryColor.withValues(alpha: 0.1)
                : Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Column(
              children: [
                Text(
                  DateFormat('EEEE').format(day),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: _isToday(day) ? AppTheme.primaryColor : null,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  DateFormat('MMM d').format(day),
                  style: TextStyle(
                    fontSize: 13,
                    color: _isToday(day) 
                      ? AppTheme.primaryColor 
                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                // Always reserve space for TODAY badge to maintain consistent height
                const SizedBox(height: 4),
                Container(
                  height: 18, // Fixed height for consistency
                  child: _isToday(day) 
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'TODAY',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(), // Invisible placeholder
                ),
              ],
            ),
          ),
          
          // Day content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  // Shift info
                  if (shift != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                      decoration: BoxDecoration(
                        color: shift.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: shift.color, width: 1),
                      ),
                      child: Text(
                        shift.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: shift.color,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  
                  // Work events
                  if (workEvents.isNotEmpty) ...[
                    Expanded(
                      child: ListView.builder(
                        itemCount: workEvents.length,
                        itemBuilder: (context, index) => _buildDayDutyItem(workEvents[index]),
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.free_breakfast,
                              size: 32,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Free Day',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  
                  // Non-work events
                  if (events.any((event) => !event.isWorkShift)) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Other Events',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 2),
                          ...events.where((event) => !event.isWorkShift).take(2).map((event) => 
                            Text(
                              event.title,
                              style: const TextStyle(fontSize: 9),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          if (events.where((event) => !event.isWorkShift).length > 2)
                            Text(
                              '+${events.where((event) => !event.isWorkShift).length - 2} more',
                              style: const TextStyle(fontSize: 8),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayDutyItem(Event event) {
    final hasBreaks = event.breakStartTime != null && event.breakEndTime != null;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(6),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        children: [
          // Duty title
          Text(
            event.title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 4),
          
          // Start - End time
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  event.formattedStartTime,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: const Icon(Icons.arrow_forward, size: 10),
                ),
                Text(
                  event.formattedEndTime,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          
          // Break times
          if (hasBreaks) ...[
            const SizedBox(height: 3),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.pause_circle_outline, size: 10),
                const SizedBox(width: 3),
                Text(
                  '${_formatTimeOfDay(event.breakStartTime!)}-${_formatTimeOfDay(event.breakEndTime!)}',
                  style: TextStyle(
                    fontSize: 9,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ],
          
          // Work time
          if (event.workTime != null) ...[
            const SizedBox(height: 3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _formatDuration(event.workTime!),
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }



  String _formatTimeOfDay(TimeOfDay timeOfDay) {
    final hour = timeOfDay.hour.toString().padLeft(2, '0');
    final minute = timeOfDay.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }
}
