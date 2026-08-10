import 'package:flutter/material.dart';

/// Month grid used by multi-date holiday pickers.
///
/// Selection styling intentionally stays green to match prior calendar-screen
/// behaviour across holiday types.
class MultiSelectCalendar extends StatelessWidget {
  const MultiSelectCalendar({
    super.key,
    required this.currentMonth,
    required this.selectedDates,
    required this.onDateTapped,
  });

  final DateTime currentMonth;
  final Set<DateTime> selectedDates;
  final ValueChanged<DateTime> onDateTapped;

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
    final lastDayOfMonth =
        DateTime(currentMonth.year, currentMonth.month + 1, 0);
    final firstDayOfWeek = firstDayOfMonth.weekday % 7;
    final daysInMonth = lastDayOfMonth.day;

    final dates = <DateTime>[
      for (var day = 1; day <= daysInMonth; day++)
        DateTime(currentMonth.year, currentMonth.month, day),
    ];

    final previousMonthDates = <DateTime>[];
    if (firstDayOfWeek > 0) {
      final previousMonth =
          DateTime(currentMonth.year, currentMonth.month - 1);
      final lastDayOfPreviousMonth =
          DateTime(previousMonth.year, previousMonth.month + 1, 0);
      for (var i = firstDayOfWeek - 1; i >= 0; i--) {
        previousMonthDates.add(
          DateTime(
            previousMonth.year,
            previousMonth.month,
            lastDayOfPreviousMonth.day - i,
          ),
        );
      }
    }

    final nextMonthDates = <DateTime>[];
    final totalCells = previousMonthDates.length + dates.length;
    final remainingCells = 42 - totalCells;
    if (remainingCells > 0) {
      for (var day = 1; day <= remainingCells; day++) {
        nextMonthDates.add(
          DateTime(currentMonth.year, currentMonth.month + 1, day),
        );
      }
    }

    final allDates = [...previousMonthDates, ...dates, ...nextMonthDates];
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final weekdayLabels = textScale > 1.1
        ? <String>['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']
        : <String>['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final weekdayStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ) ??
        TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurface,
        );
    final cellAspectRatio =
        textScale > 1.2 ? 0.62 : (textScale > 1.05 ? 0.78 : 0.92);

    return Column(
      children: [
        Row(
          children: weekdayLabels
              .map(
                (day) => Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: weekdayStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: cellAspectRatio,
          ),
          itemCount: allDates.length,
          itemBuilder: (context, index) {
            final date = allDates[index];
            final isCurrentMonth = date.month == currentMonth.month;
            final normalizedDate = DateTime(date.year, date.month, date.day);
            final isSelected = selectedDates.contains(normalizedDate);
            final now = DateTime.now();
            final isToday = normalizedDate.year == now.year &&
                normalizedDate.month == now.month &&
                normalizedDate.day == now.day;

            final minDate = now.subtract(const Duration(days: 365));
            final maxDate = now.add(const Duration(days: 365));
            final isWithinRange =
                !date.isBefore(minDate) && !date.isAfter(maxDate);

            final isDark = Theme.of(context).brightness == Brightness.dark;
            final defaultTextColor = Theme.of(context).colorScheme.onSurface;
            final mutedTextColor = isDark
                ? Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5)
                : Colors.grey.shade600;

            return GestureDetector(
              onTap: isWithinRange && isCurrentMonth
                  ? () => onDateTapped(date)
                  : null,
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.green
                      : isToday
                          ? (isDark
                              ? Colors.green.shade900.withValues(alpha: 0.5)
                              : Colors.green.shade100)
                          : Colors.transparent,
                  shape: BoxShape.circle,
                  border: isToday && !isSelected
                      ? Border.all(color: Colors.green, width: 2)
                      : null,
                ),
                child: Center(
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : !isCurrentMonth
                              ? mutedTextColor
                              : !isWithinRange
                                  ? mutedTextColor
                                  : defaultTextColor,
                      fontWeight: isSelected || isToday
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
