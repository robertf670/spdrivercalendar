import 'package:flutter/material.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';
import 'time_range_selector.dart';

class HolidayDaysStatisticsCard extends StatelessWidget {
  final Map<String, dynamic> holidayStats;
  final String currentRange;
  final List<String> availableRanges;
  final ValueChanged<String?> onChanged;

  const HolidayDaysStatisticsCard({
    super.key, 
    required this.holidayStats,
    required this.currentRange,
    required this.availableRanges,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.beach_access,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Booked Holiday Days',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TimeRangeSelector(
              currentRange: currentRange,
              availableRanges: availableRanges,
              onChanged: onChanged,
            ),
            const SizedBox(height: 16),
            
            // Get data for the selected time range
            Builder(
              builder: (context) {
                final periodKey = _getPeriodKey(currentRange);
                if (_hasPeriodData(holidayStats, periodKey)) {
                  return _buildTimeRangeSection(context, holidayStats[periodKey]);
                } else {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(
                      child: Text(
                        'No holiday days booked for this period',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getPeriodKey(String range) {
    // The range is already a year string (e.g., "2024", "2025")
    // Validate it's a valid year format, otherwise default to current year
    final year = int.tryParse(range);
    if (year != null && year >= 2000 && year <= 2100) {
      return range;
    }
    return DateTime.now().year.toString();
  }

  bool _hasPeriodData(Map<String, dynamic> stats, String period) {
    if (!stats.containsKey(period)) return false;
    final periodData = stats[period] as Map<String, dynamic>?;
    if (periodData == null) return false;
    
    final total = periodData['total'] as int? ?? 0;
    return total > 0;
  }

  Widget _buildTimeRangeSection(BuildContext context, Map<String, dynamic> periodData) {
    final total = periodData['total'] as int? ?? 0;
    final summer = periodData['summer'] as int? ?? 0;
    final winter = periodData['winter'] as int? ?? 0;
    final other = periodData['other'] as int? ?? 0;
    
    // Calculate percentages
    final summerPercent = total > 0 ? (summer / total * 100).round() : 0;
    final winterPercent = total > 0 ? (winter / total * 100).round() : 0;
    final otherPercent = total > 0 ? (other / total * 100).round() : 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Total row
        _buildHolidayStatRow(
          'Total Days Booked', 
          '$total', 
          Theme.of(context).colorScheme.primary,
          isTotal: true,
        ),
        const Divider(height: 16),
        
        // Breakdown rows
        _buildHolidayStatRow(
          'Summer Weeks', 
          '$summer${total > 0 ? ' ($summerPercent%)' : ''}', 
          Colors.orange,
        ),
        _buildHolidayStatRow(
          'Winter Weeks', 
          '$winter${total > 0 ? ' ($winterPercent%)' : ''}', 
          Colors.blue,
        ),
        _buildHolidayStatRow(
          'Other Holidays', 
          '$other${total > 0 ? ' ($otherPercent%)' : ''}', 
          Colors.green,
        ),
        
        // Visual breakdown bar
        if (total > 0)
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Column(
              children: [
                SizedBox(
                  height: 12,
                  child: Row(
                    children: [
                      if (summer > 0)
                        Expanded(
                          flex: summer,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(6),
                                bottomLeft: const Radius.circular(6),
                                topRight: winter == 0 && other == 0 
                                    ? const Radius.circular(6) 
                                    : Radius.zero,
                                bottomRight: winter == 0 && other == 0 
                                    ? const Radius.circular(6) 
                                    : Radius.zero,
                              ),
                            ),
                          ),
                        ),
                      if (winter > 0)
                        Expanded(
                          flex: winter,
                          child: Container(
                            color: Colors.blue,
                          ),
                        ),
                      if (other > 0)
                        Expanded(
                          flex: other,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.only(
                                topRight: const Radius.circular(6),
                                bottomRight: const Radius.circular(6),
                                topLeft: summer == 0 && winter == 0 
                                    ? const Radius.circular(6) 
                                    : Radius.zero,
                                bottomLeft: summer == 0 && winter == 0 
                                    ? const Radius.circular(6) 
                                    : Radius.zero,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (summer > 0)
                      _buildLegendItem('Summer', Colors.orange),
                    if (winter > 0)
                      _buildLegendItem('Winter', Colors.blue),
                    if (other > 0)
                      _buildLegendItem('Other', Colors.green),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildHolidayStatRow(String label, String value, Color color, {bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isTotal ? 2.0 : 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 15,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: isTotal ? 15 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}
