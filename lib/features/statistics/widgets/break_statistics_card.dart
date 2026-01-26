import 'package:flutter/material.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';
import 'time_range_selector.dart';

class BreakStatisticsCard extends StatelessWidget {
  final Map<String, dynamic> breakStats;
  final String currentRange;
  final List<String> availableRanges;
  final ValueChanged<String?> onChanged;

  const BreakStatisticsCard({
    super.key, 
    required this.breakStats,
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
            const Text(
              'Break & Finish Statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Statistics for shifts with late break or late finish status',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),
            TimeRangeSelector(
              currentRange: currentRange,
              availableRanges: availableRanges,
              onChanged: onChanged,
            ),
            const SizedBox(height: 16),
            
            // Get data for the selected time range
            if (_hasPeriodData(breakStats, currentRange.toLowerCase().replaceAll(' ', '')))
              _buildTimeRangeSection(
                context, 
                breakStats[currentRange.toLowerCase().replaceAll(' ', '')]
              ),
            
            // No Data Message
            if (!_hasPeriodData(breakStats, currentRange.toLowerCase().replaceAll(' ', '')))
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: Text(
                    'No break or finish data recorded for this period',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _hasPeriodData(Map<String, dynamic> stats, String period) {
    if (!stats.containsKey(period)) return false;
    final periodData = stats[period] as Map<String, dynamic>?;
    if (periodData == null) return false;
    
    final total = periodData['total'] as int? ?? 0;
    final totalFinishes = periodData['totalFinishes'] as int? ?? 0;
    return total > 0 || totalFinishes > 0;
  }

  Widget _buildTimeRangeSection(BuildContext context, Map<String, dynamic> periodData) {
    final total = periodData['total'] as int? ?? 0;
    final fullBreak = periodData['fullBreak'] as int? ?? 0;
    final overtime = periodData['overtime'] as int? ?? 0;
    final totalOvertimeMinutes = periodData['totalOvertimeMinutes'] as int? ?? 0;
    final totalFinishes = periodData['totalFinishes'] as int? ?? 0;
    final totalLateFinishMinutes = periodData['totalLateFinishMinutes'] as int? ?? 0;
    
    // Calculate percentages
    final fullBreakPercent = total > 0 ? (fullBreak / total * 100).round() : 0;
    final overtimePercent = total > 0 ? (overtime / total * 100).round() : 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Late Break Section
        if (total > 0) ...[
          const Text(
            'Late Breaks',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildBreakStatRow(
            'Total Late Breaks', 
            '$total', 
          ),
          _buildBreakStatRow(
            'Full Break Taken', 
            '$fullBreak ($fullBreakPercent%)', 
          ),
          _buildBreakStatRow(
            'Overtime Taken', 
            '$overtime ($overtimePercent%)', 
          ),
          if (totalOvertimeMinutes > 0)
            _buildBreakStatRow(
              'Total Overtime Minutes', 
              '$totalOvertimeMinutes mins', 
            ),
          
          // Progress indicator
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: SizedBox(
              height: 10,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(
                  value: overtime / total,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Colors.orange,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                flex: fullBreakPercent,
                child: Text(
                  'Full Break',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: overtimePercent,
                child: Text(
                  'Overtime',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ],
        
        // Late Finish Section
        if (totalFinishes > 0) ...[
          if (total > 0) ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
          ],
          const Text(
            'Late Finishes',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildBreakStatRow(
            'Total Late Finishes', 
            '$totalFinishes', 
          ),
          if (totalLateFinishMinutes > 0)
            _buildBreakStatRow(
              'Total Late Finish Minutes', 
              '$totalLateFinishMinutes mins', 
            ),
        ],
      ],
    );
  }

  Widget _buildBreakStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
} 
