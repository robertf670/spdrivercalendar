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
    final screenWidth = MediaQuery.of(context).size.width;

    if (shiftCounts.isEmpty || shiftCounts.values.every((v) => v == 0)) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(screenWidth < 350 ? 12.0 : 16.0),
          child: Text(
            'No shift data available',
            style: TextStyle(fontSize: screenWidth < 350 ? 12.0 : 14.0),
          ),
        ),
      );
    }

    // Filter out zero values and prepare data
    final filteredData = shiftCounts.entries
        .where((e) => e.value > 0)
        .toList();

    if (filteredData.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(screenWidth < 350 ? 12.0 : 16.0),
          child: Text(
            'No shift data available',
            style: TextStyle(fontSize: screenWidth < 350 ? 12.0 : 14.0),
          ),
        ),
      );
    }

    final total = filteredData.map((e) => e.value).reduce((a, b) => a + b);

    // Responsive sizes
    final chartHeight = screenWidth < 350 ? 180.0 : screenWidth < 450 ? 220.0 : 250.0;
    final legendFontSize = screenWidth < 350 ? 10.0 : screenWidth < 450 ? 11.0 : 12.0;
    final detailFontSize = screenWidth < 350 ? 9.0 : 10.0;
    final padding = screenWidth < 350 ? 12.0 : 16.0;

    // Define colors for each shift type
    final colorMap = {
      'Early': Colors.blue,
      'Relief': Colors.green,
      'Late': Colors.orange,
      'Night': Colors.purple,
      'Spare': Colors.teal,
      'Bogey': Colors.red,
      'Universal/Euro': Colors.deepOrange,
      'Overtime': Colors.amber,
    };

    // Generate pie chart sections
    const int touchedIndex = -1; // Unused, kept for future touch handling

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: screenWidth < 350 ? 16.0 : null,
                  ),
            ),
            SizedBox(height: screenWidth < 350 ? 12.0 : 16.0),
            LayoutBuilder(
              builder: (context, constraints) {
                return SizedBox(
                  height: chartHeight,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 2,
                        child: PieChart(
                          PieChartData(
                            pieTouchData: PieTouchData(
                              touchCallback: (FlTouchEvent event, pieTouchResponse) {},
                            ),
                            sectionsSpace: 2,
                            centerSpaceRadius: screenWidth < 350 ? 30.0 : 40,
                            sections: filteredData.asMap().entries.map((entry) {
                              final index = entry.key;
                              final data = entry.value;
                              final percentage = (data.value / total * 100);
                              final color = colorMap[data.key] ?? Colors.grey.shade300;

                              return PieChartSectionData(
                                value: data.value.toDouble(),
                                title: '${percentage.toStringAsFixed(1)}%',
                                color: color,
                                radius: touchedIndex == index ? 60 : 50,
                                titleStyle: TextStyle(
                                  fontSize: screenWidth < 350 ? 10.0 : 12,
                                  fontWeight: FontWeight.bold,
                                  color: _getContrastColor(color),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      SizedBox(width: screenWidth < 350 ? 6.0 : 8),
                      Expanded(
                        flex: 1,
                        child: Scrollbar(
                          thumbVisibility: true,
                          thickness: 4,
                          radius: const Radius.circular(2),
                          child: SingleChildScrollView(
                            child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: filteredData.map((data) {
                              final color = colorMap[data.key] ?? Colors.grey.shade300;
                              final percentage = (data.value / total * 100);
                              return Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: screenWidth < 350 ? 2.0 : 4.0,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: screenWidth < 350 ? 10.0 : 12,
                                      height: screenWidth < 350 ? 10.0 : 12,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    SizedBox(width: screenWidth < 350 ? 6.0 : 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            data.key,
                                            style: TextStyle(
                                              fontSize: legendFontSize,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Text(
                                            '${data.value} (${percentage.toStringAsFixed(1)}%)',
                                            style: TextStyle(
                                              fontSize: detailFontSize,
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
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            SizedBox(height: screenWidth < 350 ? 6.0 : 8),
            Center(
              child: Text(
                'Total: $total shifts',
                style: TextStyle(
                  fontSize: screenWidth < 350 ? 11.0 : 12,
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

