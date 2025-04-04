import 'package:flutter/material.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';

class FrequencyChart extends StatelessWidget {
  final Map<String, int> frequencyData;
  final String emptyDataMessage;

  const FrequencyChart({
    Key? key,
    required this.frequencyData,
    this.emptyDataMessage = 'No data available',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (frequencyData.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(emptyDataMessage),
        ),
      );
    }

    // Find the maximum value for scaling the bars
    final maxValue = frequencyData.values.reduce((a, b) => a > b ? a : b);
    if (maxValue == 0) {
       return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(emptyDataMessage), // Handle case where all counts are 0
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: frequencyData.entries
              .toList()
              .map((entry) {
                final percentage = entry.value / maxValue;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 80, // Consider making this adaptive
                            child: Text(
                              '${entry.key}:',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            child: Stack(
                              children: [
                                Container(
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                FractionallySizedBox(
                                  widthFactor: percentage,
                                  child: Container(
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor, // Use theme color
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                                Positioned.fill(
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 8.0),
                                      child: Text(
                                        '${entry.value}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black54, // Adjust for contrast
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              })
              .toList(),
        ),
      ],
    );
  }
} 