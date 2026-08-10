import 'package:flutter/material.dart';
import 'package:spdrivercalendar/features/calendar/widgets/animated_selected_day_cell.dart';

/// Presentation-only month-grid cell.
///
/// All calendar rules and service lookups remain with the caller; this widget
/// only renders the supplied state.
class CalendarDayCell extends StatelessWidget {
  const CalendarDayCell({
    super.key,
    required this.date,
    required this.displayText,
    required this.shift,
    required this.backgroundColor,
    required this.cellColor,
    required this.selectedBorderColor,
    this.isDayInLieu = false,
    this.isHoliday = false,
    this.hasEvents = false,
    this.isSaturdayService = false,
    this.hasNotes = false,
    this.hasBankHolidayRedundant = false,
    this.isToday = false,
    this.isBankHoliday = false,
    this.isOutsideDay = false,
    this.isSelected = false,
    this.animatedSelection = true,
  });

  final DateTime date;
  final String displayText;
  final String shift;
  final Color? backgroundColor;
  final Color cellColor;
  final Color selectedBorderColor;
  final bool isDayInLieu;
  final bool isHoliday;
  final bool hasEvents;
  final bool isSaturdayService;
  final bool hasNotes;
  final bool hasBankHolidayRedundant;
  final bool isToday;
  final bool isBankHoliday;
  final bool isOutsideDay;
  final bool isSelected;
  final bool animatedSelection;

  static double dateFontSizeForWidth(double screenWidth) {
    if (screenWidth < 350) return 11;
    if (screenWidth < 600) return 12;
    return 13;
  }

  static double dutyFontSizeForWidth(double screenWidth) {
    if (screenWidth < 350) return 8;
    if (screenWidth < 450) return 9;
    if (screenWidth < 600) return 9.5;
    return 10;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final badgeSizes = _CalendarBadgeSizes.forWidth(screenWidth);
    final standardContent = _buildContent(
      context,
      screenWidth: screenWidth,
      badgeSizes: badgeSizes,
      textColor: Theme.of(context).colorScheme.onSurface,
      showEventIndicator: true,
    );

    return Opacity(
      opacity: isOutsideDay ? 0.4 : 1,
      child: _buildCellContainer(
        context,
        screenWidth: screenWidth,
        badgeSizes: badgeSizes,
        standardContent: standardContent,
      ),
    );
  }

  Widget _buildCellContainer(
    BuildContext context, {
    required double screenWidth,
    required _CalendarBadgeSizes badgeSizes,
    required Widget standardContent,
  }) {
    if (isSelected && animatedSelection) {
      return AnimatedSelectedDayCell(
        backgroundColor: backgroundColor,
        isToday: isToday,
        isBankHoliday: isBankHoliday,
        borderColor: selectedBorderColor,
        child: standardContent,
      );
    }

    if (isSelected) {
      final selectedColor = isBankHoliday
          ? Colors.red.withValues(alpha: 0.7)
          : const Color(0xFF1565C0);
      return Container(
        margin: const EdgeInsets.all(2),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selectedColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: isBankHoliday ? Colors.red : const Color(0xFF0D47A1),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: selectedColor.withValues(alpha: 0.4),
              blurRadius: 6,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: _buildContent(
          context,
          screenWidth: screenWidth,
          badgeSizes: badgeSizes,
          textColor: Colors.white,
          showEventIndicator: false,
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: isToday
            ? Border.all(
                color: isBankHoliday ? Colors.red : Colors.blue,
                width: 2,
              )
            : isBankHoliday
                ? Border.all(color: Colors.red, width: 1.5)
                : null,
      ),
      child: standardContent,
    );
  }

  Widget _buildContent(
    BuildContext context, {
    required double screenWidth,
    required _CalendarBadgeSizes badgeSizes,
    required Color textColor,
    required bool showEventIndicator,
  }) {
    return Stack(
      children: [
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${date.day}',
                style: TextStyle(
                  fontSize: dateFontSizeForWidth(screenWidth),
                  color: textColor,
                ),
              ),
              if (displayText.isNotEmpty && (!isHoliday || shift == 'R')) ...[
                Text(
                  displayText,
                  style: TextStyle(
                    fontSize: dutyFontSizeForWidth(screenWidth),
                    fontWeight: FontWeight.bold,
                    height: 1,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (isDayInLieu)
                _statusText(
                  'Lieu',
                  screenWidth: screenWidth,
                  color: textColor,
                )
              else if (isHoliday && shift != 'R')
                _statusText(
                  'H',
                  screenWidth: screenWidth,
                  color: textColor,
                ),
            ],
          ),
        ),
        if (isSaturdayService)
          Positioned(
            top: badgeSizes.top,
            left: badgeSizes.left,
            child: Container(
              key: const ValueKey('calendar_day_sat_badge'),
              padding: EdgeInsets.symmetric(
                horizontal: badgeSizes.horizontalPadding,
                vertical: badgeSizes.verticalPadding,
              ),
              decoration: BoxDecoration(
                color: Colors.orange.shade600,
                borderRadius: BorderRadius.circular(badgeSizes.radius),
              ),
              child: Text(
                'SAT',
                style: TextStyle(
                  fontSize: badgeSizes.fontSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1,
                ),
              ),
            ),
          ),
        if (hasNotes)
          Positioned(
            top: badgeSizes.top,
            right: badgeSizes.left,
            child: Icon(
              Icons.note,
              key: const ValueKey('calendar_day_note_badge'),
              size: badgeSizes.fontSize * 1.5,
              color: cellColor,
            ),
          ),
        if (hasBankHolidayRedundant)
          Positioned(
            bottom: badgeSizes.top,
            left: badgeSizes.left,
            child: Container(
              key: const ValueKey('calendar_day_redundant_badge'),
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: Colors.amber.shade800,
                shape: BoxShape.circle,
                border: Border.all(color: textColor, width: 0.5),
              ),
            ),
          ),
        if (hasEvents && showEventIndicator)
          Positioned(
            bottom: 2,
            right: 2,
            child: Container(
              key: const ValueKey('calendar_day_event_badge'),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: cellColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }

  Widget _statusText(
    String text, {
    required double screenWidth,
    required Color color,
  }) {
    return Text(
      text,
      style: TextStyle(
        fontSize: dutyFontSizeForWidth(screenWidth),
        fontWeight: FontWeight.bold,
        color: color,
        height: 1,
      ),
      maxLines: 1,
      overflow: TextOverflow.clip,
    );
  }
}

class _CalendarBadgeSizes {
  const _CalendarBadgeSizes({
    required this.fontSize,
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.radius,
    required this.top,
    required this.left,
  });

  final double fontSize;
  final double horizontalPadding;
  final double verticalPadding;
  final double radius;
  final double top;
  final double left;

  factory _CalendarBadgeSizes.forWidth(double screenWidth) {
    if (screenWidth < 350) {
      return const _CalendarBadgeSizes(
        fontSize: 6,
        horizontalPadding: 2,
        verticalPadding: 0.5,
        radius: 3,
        top: 1,
        left: 1,
      );
    }
    if (screenWidth < 450) {
      return const _CalendarBadgeSizes(
        fontSize: 7,
        horizontalPadding: 3,
        verticalPadding: 1,
        radius: 4,
        top: 2,
        left: 2,
      );
    }
    if (screenWidth < 600) {
      return const _CalendarBadgeSizes(
        fontSize: 8,
        horizontalPadding: 3.5,
        verticalPadding: 1,
        radius: 4,
        top: 2,
        left: 2,
      );
    }
    if (screenWidth < 900) {
      return const _CalendarBadgeSizes(
        fontSize: 9,
        horizontalPadding: 4,
        verticalPadding: 1.5,
        radius: 5,
        top: 3,
        left: 3,
      );
    }
    return const _CalendarBadgeSizes(
      fontSize: 10,
      horizontalPadding: 5,
      verticalPadding: 2,
      radius: 5,
      top: 3,
      left: 3,
    );
  }
}
