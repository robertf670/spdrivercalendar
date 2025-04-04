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
    // Determine text color based on theme brightness
    final textColor = Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87;
    final iconColor = Theme.of(context).brightness == Brightness.dark ? Colors.white70 : AppTheme.primaryColor;
    final dropdownBackgroundColor = Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        // Remove fixed background color, let it inherit or use theme-based color if needed
        // color: Colors.grey[100], 
        borderRadius: BorderRadius.circular(8),
        // Optionally add a subtle border that adapts
        border: Border.all(color: Theme.of(context).dividerColor, width: 0.5),
      ),
      child: DropdownButton<String>(
        value: currentRange,
        isExpanded: true,
        underline: const SizedBox(), // Remove the default underline
        // Style dropdown for dark/light mode
        style: TextStyle(color: textColor), // Selected item text color
        iconEnabledColor: iconColor, // Arrow icon color
        dropdownColor: dropdownBackgroundColor, // Menu background
        items: availableRanges.map((range) {
          return DropdownMenuItem(
            value: range,
            child: Row(
              children: [
                Icon(
                  _getTimeRangeIcon(range),
                  size: 18,
                  color: iconColor, // Icon color inside menu item
                ),
                const SizedBox(width: 8),
                // Ensure item text is readable in dropdown menu
                Text(range, style: TextStyle(color: textColor)), 
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