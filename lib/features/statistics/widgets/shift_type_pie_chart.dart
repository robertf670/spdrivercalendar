import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';

/// Widget that displays shift type distribution as a pie chart
class ShiftTypePieChart extends StatelessWidget {
  final Map<String, int> shiftCounts;
  final String title;

  const ShiftTypePieChart({
    super.key,
    required this.shiftCounts,
    this.title = 'Shift Type Distribution',
  });

  @override
  Widget build(BuildContext context) {
    if (shiftCounts.isEmpty || shiftCounts.values.every((v) => v == 0)) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No shift data available'),
        ),
      );
    }

    // Filter out zero values and prepare data
    final filteredData = shiftCounts.entries
        .where((e) => e.value > 0)
        .toList();

    if (filteredData.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No shift data available'),
        ),
      );
    }

    final total = filteredData.map((e) => e.value).reduce((a, b) => a + b);

    // Define colors for each shift type
    final colorMap = {
      'Early': Colors.blue,
      'Relief': Colors.green,
      'Late': Colors.orange,
      'Night': Colors.purple,
      'Spare': Colors.teal,
      'Bogey': Colors.red,
      'Overtime': Colors.amber,
    };

    // Generate pie chart sections
    int touchedIndex = -1;

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
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback: (FlTouchEvent event, pieTouchResponse) {
                            // Handle touch if needed
                          },
                        ),
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: filteredData.asMap().entries.map((entry) {
                          final index = entry.key;
                          final data = entry.value;
                          final percentage = (data.value / total * 100);
                          final color = colorMap[data.key] ?? 
                              Colors.grey.shade300;

                          return PieChartSectionData(
                            value: data.value.toDouble(),
                            title: '${percentage.toStringAsFixed(1)}%',
                            color: color,
                            radius: touchedIndex == index ? 60 : 50,
                            titleStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _getContrastColor(color),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: filteredData.map((data) {
                        final color = colorMap[data.key] ?? Colors.grey.shade300;
                        final percentage = (data.value / total * 100);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data.key,
                                      style: const TextStyle(fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${data.value} (${percentage.toStringAsFixed(1)}%)',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Total: $total shifts',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getContrastColor(Color color) {
    // Calculate luminance to determine if we need light or dark text
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}

