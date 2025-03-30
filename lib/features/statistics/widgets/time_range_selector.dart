import 'package:flutter/material.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';

class TimeRangeSelector extends StatelessWidget {
  final String currentRange;
  final List<String> availableRanges;
  final ValueChanged<String?> onChanged;

  const TimeRangeSelector({
    Key? key,
    required this.currentRange,
    required this.availableRanges,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: currentRange,
        isExpanded: true,
        underline: const SizedBox(), // Remove the default underline
        items: availableRanges.map((range) {
          return DropdownMenuItem(
            value: range,
            child: Row(
              children: [
                Icon(
                  _getTimeRangeIcon(range),
                  size: 18,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(range),
              ],
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  IconData _getTimeRangeIcon(String range) {
    switch (range) {
      case 'This Week':
        return Icons.calendar_today;
      case 'Last Week':
      case 'This Month':
      case 'Last Month':
        return Icons.calendar_month; // Consolidate similar icons
      case 'All Time':
        return Icons.history;
      default:
        return Icons.calendar_today;
    }
  }
} 