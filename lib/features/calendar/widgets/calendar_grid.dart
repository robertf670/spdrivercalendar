import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spdrivercalendar/features/calendar/widgets/calendar_day_cell.dart';
import 'package:table_calendar/table_calendar.dart';

typedef CalendarGridDayBuilder = Widget Function(
  DateTime date, {
  required bool isToday,
  required bool isOutsideDay,
  bool isSelected,
});

/// Month header and grid with state ownership delegated to the caller.
class CalendarGrid extends StatelessWidget {
  const CalendarGrid({
    super.key,
    required this.tableKey,
    required this.focusedDay,
    required this.selectedDay,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onShowYear,
    required this.onDaySelected,
    required this.onPageChanged,
    required this.eventLoader,
    required this.dayBuilder,
  });

  final Key tableKey;
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onShowYear;
  final Future<void> Function(DateTime selectedDay, DateTime focusedDay)
      onDaySelected;
  final ValueChanged<DateTime> onPageChanged;
  final List<Object?> Function(DateTime day) eventLoader;
  final CalendarGridDayBuilder dayBuilder;

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scaledDaysOfWeekHeight = textScaler.scale(22) + 16;
    final scaledRowHeight = math.max(
      textScaler.scale(52) + textScaler.scale(10),
      textScaler.scale(CalendarDayCell.dateFontSizeForWidth(screenWidth)) +
          textScaler.scale(
                CalendarDayCell.dutyFontSizeForWidth(screenWidth),
              ) *
              2 +
          textScaler.scale(14),
    );
    final horizontalPadding = screenWidth < 350
        ? 8.0
        : screenWidth < 450
            ? 12.0
            : 16.0;
    final titleHorizontalPadding = screenWidth < 350 ? 8.0 : 16.0;
    final titleFontSize = screenWidth < 350 ? 16.0 : 18.0;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            vertical: 8,
            horizontal: horizontalPadding,
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: onPreviousMonth,
              ),
              Expanded(
                child: GestureDetector(
                  onTap: onShowYear,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: titleHorizontalPadding,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.5),
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        DateFormat('  MMMM yyyy').format(focusedDay),
                        style: TextStyle(
                          fontSize: titleFontSize,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: onNextMonth,
              ),
            ],
          ),
        ),
        TableCalendar<Object?>(
          key: tableKey,
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: focusedDay,
          calendarFormat: CalendarFormat.month,
          daysOfWeekHeight: scaledDaysOfWeekHeight,
          rowHeight: scaledRowHeight,
          headerVisible: false,
          availableGestures: AvailableGestures.horizontalSwipe,
          selectedDayPredicate: (day) => isSameDay(selectedDay, day),
          onDaySelected: (selected, focused) async {
            await onDaySelected(selected, focused);
          },
          onPageChanged: onPageChanged,
          eventLoader: eventLoader,
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
            ),
            weekendStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          calendarStyle: CalendarStyle(
            outsideDaysVisible: true,
            markersMaxCount: 0,
            markersAnchor: 1,
            defaultTextStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
            ),
            weekendTextStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          calendarBuilders: CalendarBuilders<Object?>(
            defaultBuilder: (context, date, _) {
              return dayBuilder(
                date,
                isToday: false,
                isOutsideDay: false,
              );
            },
            todayBuilder: (context, date, _) {
              return dayBuilder(
                date,
                isToday: true,
                isOutsideDay: false,
              );
            },
            outsideBuilder: (context, date, _) {
              return dayBuilder(
                date,
                isToday: false,
                isOutsideDay: true,
              );
            },
            selectedBuilder: (context, date, _) {
              return dayBuilder(
                date,
                isToday: false,
                isOutsideDay: false,
                isSelected: true,
              );
            },
            markerBuilder: (context, date, events) => null,
          ),
        ),
      ],
    );
  }
}
