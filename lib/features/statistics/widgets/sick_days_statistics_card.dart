import 'package:flutter/material.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';
import 'time_range_selector.dart';

class SickDaysStatisticsCard extends StatelessWidget {
  final Map<String, dynamic> sickStats;
  final String currentRange;
  final List<String> availableRanges;
  final ValueChanged<String?> onChanged;

  const SickDaysStatisticsCard({
    super.key, 
    required this.sickStats,
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
                  Icons.sick,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Sick Days Statistics',
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
                if (_hasPeriodData(sickStats, periodKey)) {
                  return _buildTimeRangeSection(context, sickStats[periodKey]);
                } else {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(
                      child: Text(
                        'No sick days recorded for this period',
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
    switch (range) {
      case 'This Month':
        return 'thismonth';
      case 'Last Month':
        return 'lastmonth';
      case 'Last 3 Months':
        return 'last3months';
      case 'Last 6 Months':
        return 'last6months';
      case 'Jan-Jun':
        return 'janjun';
      case 'Jul-Dec':
        return 'juldec';
      case 'This Year':
        return 'thisyear';
      case 'Last Year':
        return 'lastyear';
      default:
        return 'thismonth';
    }
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
    final normal = periodData['normal'] as int? ?? 0;
    final selfCertified = periodData['selfCertified'] as int? ?? 0;
    final forceMajeure = periodData['forceMajeure'] as int? ?? 0;
    
    // Calculate percentages
    final normalPercent = total > 0 ? (normal / total * 100).round() : 0;
    final selfCertPercent = total > 0 ? (selfCertified / total * 100).round() : 0;
    final forceMajeurePercent = total > 0 ? (forceMajeure / total * 100).round() : 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Total row
        _buildSickStatRow(
          'Total Sick Days', 
          '$total', 
          Theme.of(context).colorScheme.primary,
          isTotal: true,
        ),
        const Divider(height: 16),
        
        // Breakdown rows
        _buildSickStatRow(
          'Normal Sick', 
          '$normal${total > 0 ? ' ($normalPercent%)' : ''}', 
          Colors.blue,
        ),
        _buildSickStatRow(
          'Self-Certified', 
          '$selfCertified${total > 0 ? ' ($selfCertPercent%)' : ''}', 
          Colors.orange,
        ),
        _buildSickStatRow(
          'Force Majeure', 
          '$forceMajeure${total > 0 ? ' ($forceMajeurePercent%)' : ''}', 
          Colors.red,
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
                      if (normal > 0)
                        Expanded(
                          flex: normal,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(6),
                                bottomLeft: const Radius.circular(6),
                                topRight: selfCertified == 0 && forceMajeure == 0 
                                    ? const Radius.circular(6) 
                                    : Radius.zero,
                                bottomRight: selfCertified == 0 && forceMajeure == 0 
                                    ? const Radius.circular(6) 
                                    : Radius.zero,
                              ),
                            ),
                          ),
                        ),
                      if (selfCertified > 0)
                        Expanded(
                          flex: selfCertified,
                          child: Container(
                            color: Colors.orange,
                          ),
                        ),
                      if (forceMajeure > 0)
                        Expanded(
                          flex: forceMajeure,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.only(
                                topRight: const Radius.circular(6),
                                bottomRight: const Radius.circular(6),
                                topLeft: normal == 0 && selfCertified == 0 
                                    ? const Radius.circular(6) 
                                    : Radius.zero,
                                bottomLeft: normal == 0 && selfCertified == 0 
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
                    if (normal > 0)
                      _buildLegendItem('Normal', Colors.blue),
                    if (selfCertified > 0)
                      _buildLegendItem('Self-Cert', Colors.orange),
                    if (forceMajeure > 0)
                      _buildLegendItem('Force Majeure', Colors.red),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSickStatRow(String label, String value, Color color, {bool isTotal = false}) {
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

