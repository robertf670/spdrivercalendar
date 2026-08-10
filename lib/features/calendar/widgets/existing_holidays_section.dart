import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spdrivercalendar/features/calendar/utils/holiday_type_presentation.dart';
import 'package:spdrivercalendar/features/calendar/utils/holiday_year_grouping.dart';
import 'package:spdrivercalendar/models/holiday.dart';
import 'package:spdrivercalendar/services/color_customization_service.dart';

/// Year-grouped existing holidays list used inside [AddHolidaysDialog].
///
/// Delete persistence stays with the caller via [onDeleteHoliday]. After a
/// successful delete the section shows a snackbar, pops the parent dialog, then
/// calls [onAfterDelete] so the caller can reopen a refreshed dialog.
class ExistingHolidaysSection extends StatefulWidget {
  const ExistingHolidaysSection({
    super.key,
    required this.holidays,
    required this.onDeleteHoliday,
    required this.onAfterDelete,
    this.holidayColor = const Color(0xFF00BCD4),
  });

  final List<Holiday> holidays;
  final Future<void> Function(Holiday holiday) onDeleteHoliday;
  final VoidCallback onAfterDelete;
  final Color holidayColor;

  @override
  State<ExistingHolidaysSection> createState() =>
      _ExistingHolidaysSectionState();
}

class _ExistingHolidaysSectionState extends State<ExistingHolidaysSection> {
  final Map<int, bool> _yearExpanded = {};

  Map<String, double> _getResponsiveSizes(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;

    if (screenWidth < 350) {
      return {
        'padding': 8.0,
        'headerPadding': 10.0,
        'itemPadding': 8.0,
        'spacing': 8.0,
        'headerFontSize': 14.0,
        'subtitleFontSize': 11.0,
        'yearFontSize': 14.0,
        'itemTitleFontSize': 13.0,
        'itemSubtitleFontSize': 11.0,
        'iconSize': 18.0,
        'headerIconSize': 18.0,
        'badgeIconSize': 10.0,
        'badgeFontSize': 10.0,
        'maxHeight': screenHeight * 0.35,
        'borderRadius': 10.0,
      };
    } else if (screenWidth < 400) {
      return {
        'padding': 10.0,
        'headerPadding': 12.0,
        'itemPadding': 9.0,
        'spacing': 10.0,
        'headerFontSize': 15.0,
        'subtitleFontSize': 11.5,
        'yearFontSize': 15.0,
        'itemTitleFontSize': 13.5,
        'itemSubtitleFontSize': 11.5,
        'iconSize': 19.0,
        'headerIconSize': 19.0,
        'badgeIconSize': 11.0,
        'badgeFontSize': 10.5,
        'maxHeight': screenHeight * 0.38,
        'borderRadius': 11.0,
      };
    } else if (screenWidth < 450) {
      return {
        'padding': 11.0,
        'headerPadding': 12.0,
        'itemPadding': 10.0,
        'spacing': 11.0,
        'headerFontSize': 15.5,
        'subtitleFontSize': 12.0,
        'yearFontSize': 15.5,
        'itemTitleFontSize': 14.0,
        'itemSubtitleFontSize': 12.0,
        'iconSize': 20.0,
        'headerIconSize': 20.0,
        'badgeIconSize': 11.5,
        'badgeFontSize': 11.0,
        'maxHeight': screenHeight * 0.4,
        'borderRadius': 12.0,
      };
    } else if (screenWidth < 600) {
      return {
        'padding': 12.0,
        'headerPadding': 12.0,
        'itemPadding': 10.0,
        'spacing': 12.0,
        'headerFontSize': 16.0,
        'subtitleFontSize': 12.0,
        'yearFontSize': 16.0,
        'itemTitleFontSize': 14.0,
        'itemSubtitleFontSize': 12.0,
        'iconSize': 20.0,
        'headerIconSize': 20.0,
        'badgeIconSize': 12.0,
        'badgeFontSize': 11.0,
        'maxHeight': screenHeight * 0.4,
        'borderRadius': 12.0,
      };
    } else if (screenWidth < 900) {
      return {
        'padding': 14.0,
        'headerPadding': 14.0,
        'itemPadding': 12.0,
        'spacing': 14.0,
        'headerFontSize': 17.0,
        'subtitleFontSize': 13.0,
        'yearFontSize': 17.0,
        'itemTitleFontSize': 15.0,
        'itemSubtitleFontSize': 13.0,
        'iconSize': 22.0,
        'headerIconSize': 22.0,
        'badgeIconSize': 13.0,
        'badgeFontSize': 12.0,
        'maxHeight': screenHeight * 0.45,
        'borderRadius': 14.0,
      };
    }
    return {
      'padding': 16.0,
      'headerPadding': 16.0,
      'itemPadding': 14.0,
      'spacing': 16.0,
      'headerFontSize': 18.0,
      'subtitleFontSize': 14.0,
      'yearFontSize': 18.0,
      'itemTitleFontSize': 16.0,
      'itemSubtitleFontSize': 14.0,
      'iconSize': 24.0,
      'headerIconSize': 24.0,
      'badgeIconSize': 14.0,
      'badgeFontSize': 13.0,
      'maxHeight': screenHeight * 0.5,
      'borderRadius': 16.0,
    };
  }

  Widget _buildTypeBadge(
    String type,
    int count,
    Color color,
    Map<String, double> sizes,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: sizes['padding']! * 0.5,
        vertical: sizes['padding']! * 0.17,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? color.withValues(alpha: 0.2)
            : color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(sizes['borderRadius']! * 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            type == 'Winter'
                ? Icons.ac_unit
                : type == 'Summer'
                    ? Icons.wb_sunny
                    : type == 'Unpaid Leave'
                        ? Icons.money_off
                        : type == 'Day In Lieu'
                            ? Icons.event_available
                            : Icons.event,
            size: sizes['badgeIconSize']!,
            color: color,
          ),
          SizedBox(width: sizes['padding']! * 0.33),
          Text(
            '$count',
            style: TextStyle(
              fontSize: sizes['badgeFontSize']!,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndDelete(Holiday holiday, Map<String, double> sizes) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.red.shade400,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Flexible(child: Text('Remove Holiday')),
          ],
        ),
        content: const Text('Are you sure you want to remove this holiday?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    await widget.onDeleteHoliday(holiday);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text('Holiday removed successfully')),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    widget.onAfterDelete();
  }

  Widget _buildHolidayItem(
    Holiday holiday,
    Map<String, double> sizes,
  ) {
    final dateText = holiday.startDate == holiday.endDate
        ? DateFormat('MMM d, yyyy').format(holiday.startDate)
        : '${DateFormat('MMM d, yyyy').format(holiday.startDate)} - ${DateFormat('MMM d, yyyy').format(holiday.endDate)}';
    final presentation = holidayTypePresentation(holiday.type);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(sizes['itemPadding']!),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        borderRadius: BorderRadius.circular(sizes['borderRadius']! * 0.67),
        border: Border.all(
          color: isDark
              ? Theme.of(context).dividerColor
              : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(sizes['padding']! * 0.8),
            decoration: BoxDecoration(
              color: isDark
                  ? presentation.color.withValues(alpha: 0.2)
                  : presentation.color.withValues(alpha: 0.1),
              borderRadius:
                  BorderRadius.circular(sizes['borderRadius']! * 0.67),
            ),
            child: Icon(
              presentation.icon,
              color: presentation.color,
              size: sizes['iconSize']!,
            ),
          ),
          SizedBox(width: sizes['spacing']!),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  presentation.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: sizes['itemTitleFontSize']!,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateText,
                  style: TextStyle(
                    fontSize: sizes['itemSubtitleFontSize']!,
                    color: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.color
                        ?.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: sizes['spacing']! * 0.67),
          InkWell(
            onTap: () => _confirmAndDelete(holiday, sizes),
            borderRadius:
                BorderRadius.circular(sizes['borderRadius']! * 0.67),
            child: Container(
              padding: EdgeInsets.all(sizes['padding']! * 0.5),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius:
                    BorderRadius.circular(sizes['borderRadius']! * 0.67),
              ),
              child: Icon(
                Icons.delete_outline,
                color: Colors.red.shade400,
                size: sizes['iconSize']! * 0.9,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearSection(
    int year,
    List<Holiday> yearHolidays,
    Map<String, double> sizes,
  ) {
    final isExpanded = _yearExpanded[year] ?? false;
    final winterCount = yearHolidays.where((h) => h.type == 'winter').length;
    final summerCount = yearHolidays.where((h) => h.type == 'summer').length;
    final unpaidLeaveCount =
        yearHolidays.where((h) => h.type == 'unpaid_leave').length;
    final dayInLieuCount =
        yearHolidays.where((h) => h.type == 'day_in_lieu').length;
    final otherCount = yearHolidays.where((h) => h.type == 'other').length;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).cardColor
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(sizes['borderRadius']!),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).dividerColor
              : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _yearExpanded[year] = !isExpanded;
              });
            },
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(sizes['borderRadius']!),
            ),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: sizes['padding']!,
                vertical: sizes['padding']! * 0.83,
              ),
              child: Row(
                children: [
                  Flexible(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: sizes['padding']! * 0.83,
                        vertical: sizes['padding']! * 0.5,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? widget.holidayColor.withValues(alpha: 0.2)
                            : widget.holidayColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(
                          sizes['borderRadius']! * 0.67,
                        ),
                      ),
                      child: Text(
                        year.toString(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: sizes['yearFontSize']!,
                          color: widget.holidayColor,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: sizes['spacing']!),
                  Expanded(
                    child: Wrap(
                      spacing: sizes['spacing']! * 0.5,
                      runSpacing: sizes['spacing']! * 0.5,
                      children: [
                        if (winterCount > 0)
                          _buildTypeBadge(
                            'Winter',
                            winterCount,
                            Colors.blue,
                            sizes,
                          ),
                        if (summerCount > 0)
                          _buildTypeBadge(
                            'Summer',
                            summerCount,
                            Colors.orange,
                            sizes,
                          ),
                        if (unpaidLeaveCount > 0)
                          _buildTypeBadge(
                            'Unpaid Leave',
                            unpaidLeaveCount,
                            Colors.purple,
                            sizes,
                          ),
                        if (dayInLieuCount > 0)
                          _buildTypeBadge(
                            'Day In Lieu',
                            dayInLieuCount,
                            ColorCustomizationService.getColorForShift(
                              'DAY_IN_LIEU',
                            ),
                            sizes,
                          ),
                        if (otherCount > 0)
                          _buildTypeBadge(
                            'Holiday',
                            otherCount,
                            Colors.grey,
                            sizes,
                          ),
                      ],
                    ),
                  ),
                  SizedBox(width: sizes['spacing']! * 0.5),
                  Container(
                    padding: EdgeInsets.all(sizes['padding']! * 0.33),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Theme.of(context).cardColor
                          : Colors.white,
                      borderRadius: BorderRadius.circular(
                        sizes['borderRadius']! * 0.5,
                      ),
                    ),
                    child: Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: sizes['iconSize']!,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1),
            ...yearHolidays.asMap().entries.map((entry) {
              final index = entry.key;
              final holiday = entry.value;
              return Column(
                children: [
                  if (index > 0) SizedBox(height: sizes['spacing']! * 0.33),
                  Padding(
                    padding: EdgeInsets.all(sizes['padding']!),
                    child: _buildHolidayItem(holiday, sizes),
                  ),
                ],
              );
            }),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sizes = _getResponsiveSizes(context);
    final holidaysByYear = groupHolidaysByYear(widget.holidays);
    final sortedYears = holidaysByYear.keys.toList();
    final totalHolidays = widget.holidays.length;
    final totalYears = sortedYears.length;

    for (final year in sortedYears) {
      _yearExpanded.putIfAbsent(year, () => false);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(sizes['headerPadding']!),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? widget.holidayColor.withValues(alpha: 0.15)
                : widget.holidayColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(sizes['borderRadius']!),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? widget.holidayColor.withValues(alpha: 0.4)
                  : widget.holidayColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(sizes['padding']!),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? widget.holidayColor.withValues(alpha: 0.25)
                      : widget.holidayColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(
                    sizes['borderRadius']! * 0.67,
                  ),
                ),
                child: Icon(
                  Icons.calendar_today,
                  color: widget.holidayColor,
                  size: sizes['headerIconSize']!,
                ),
              ),
              SizedBox(width: sizes['spacing']!),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Existing Holidays',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: sizes['headerFontSize']!,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$totalHolidays ${totalHolidays == 1 ? 'holiday' : 'holidays'} across $totalYears ${totalYears == 1 ? 'year' : 'years'}',
                      style: TextStyle(
                        fontSize: sizes['subtitleFontSize']!,
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color
                            ?.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: sizes['spacing']!),
        Column(
          children: List.generate(sortedYears.length, (index) {
            final year = sortedYears[index];
            final section = _buildYearSection(
              year,
              holidaysByYear[year]!,
              sizes,
            );
            if (index > 0) {
              return Column(
                children: [
                  SizedBox(height: sizes['spacing']! * 0.67),
                  section,
                ],
              );
            }
            return section;
          }),
        ),
      ],
    );
  }
}
