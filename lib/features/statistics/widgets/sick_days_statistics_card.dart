import 'package:flutter/material.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';
import 'time_range_selector.dart';
import '../../../services/self_certified_sick_days_service.dart';

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
        _buildSelfCertifiedRow(
          context,
          selfCertified,
          total > 0 ? selfCertPercent : 0,
          currentRange,
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

  Widget _buildSelfCertifiedRow(
    BuildContext context,
    int selfCertified,
    int selfCertPercent,
    String currentRange,
  ) {
    // Always show tracking info for current year
    final year = DateTime.now().year;

    return FutureBuilder<Map<String, dynamic>>(
      future: SelfCertifiedSickDaysService.getStatistics(year),
      builder: (context, snapshot) {
        // Get all tracking data
        final firstHalf = snapshot.hasData 
            ? (snapshot.data!['firstHalf'] as Map<String, dynamic>? ?? {})
            : {'used': 0, 'remaining': 2, 'limit': 2};
        final secondHalf = snapshot.hasData
            ? (snapshot.data!['secondHalf'] as Map<String, dynamic>? ?? {})
            : {'used': 0, 'remaining': 2, 'limit': 2};
        final yearStats = snapshot.hasData
            ? (snapshot.data!['year'] as Map<String, dynamic>? ?? {})
            : {'used': 0, 'remaining': 4, 'limit': 4};

        final firstHalfUsed = firstHalf['used'] as int? ?? 0;
        final firstHalfLimit = firstHalf['limit'] as int? ?? 2;
        final firstHalfRemaining = firstHalf['remaining'] as int? ?? 2;
        
        final secondHalfUsed = secondHalf['used'] as int? ?? 0;
        final secondHalfLimit = secondHalf['limit'] as int? ?? 2;
        final secondHalfRemaining = secondHalf['remaining'] as int? ?? 2;
        
        final yearUsed = yearStats['used'] as int? ?? 0;
        final yearLimit = yearStats['limit'] as int? ?? 4;
        final yearRemaining = yearStats['remaining'] as int? ?? 4;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main row with count
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Self-Certified',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Text(
                      '$selfCertified${selfCertPercent > 0 ? ' ($selfCertPercent%)' : ''}',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              // Breakdown section
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Limits:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Responsive layout - stack on small screens, row on larger screens
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isSmallScreen = constraints.maxWidth < 300;
                        
                        if (isSmallScreen) {
                          // Stack vertically on small screens
                          return Column(
                            children: [
                              _buildLimitItem(
                                context,
                                'Jan-Jun',
                                firstHalfUsed,
                                firstHalfLimit,
                                firstHalfRemaining,
                              ),
                              const SizedBox(height: 6),
                              _buildLimitItem(
                                context,
                                'Jul-Dec',
                                secondHalfUsed,
                                secondHalfLimit,
                                secondHalfRemaining,
                              ),
                              const SizedBox(height: 6),
                              _buildLimitItem(
                                context,
                                'Year Total',
                                yearUsed,
                                yearLimit,
                                yearRemaining,
                                isTotal: true,
                              ),
                            ],
                          );
                        } else {
                          // Row layout on larger screens
                          return Row(
                            children: [
                              Expanded(
                                child: _buildLimitItem(
                                  context,
                                  'Jan-Jun',
                                  firstHalfUsed,
                                  firstHalfLimit,
                                  firstHalfRemaining,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildLimitItem(
                                  context,
                                  'Jul-Dec',
                                  secondHalfUsed,
                                  secondHalfLimit,
                                  secondHalfRemaining,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildLimitItem(
                                  context,
                                  'Year Total',
                                  yearUsed,
                                  yearLimit,
                                  yearRemaining,
                                  isTotal: true,
                                ),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLimitItem(
    BuildContext context,
    String label,
    int used,
    int limit,
    int remaining, {
    bool isTotal = false,
  }) {
    final isAtLimit = used >= limit;
    final color = isAtLimit ? Colors.orange.shade700 : Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;
    
    return Container(
      padding: const EdgeInsets.all(6.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8.0),
        border: isAtLimit 
            ? Border.all(color: Colors.orange.withValues(alpha: 0.5), width: 1)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$used/$limit',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (remaining > 0 && !isAtLimit)
            Text(
              '$remaining left',
              style: TextStyle(
                fontSize: 9,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
        ],
      ),
    );
  }
}

