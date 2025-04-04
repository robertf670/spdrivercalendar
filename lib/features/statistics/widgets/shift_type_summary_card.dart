import 'package:flutter/material.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';

class ShiftTypeSummaryCard extends StatelessWidget {
  final Map<String, dynamic> stats;

  const ShiftTypeSummaryCard({Key? key, required this.stats}) : super(key: key);

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
              'Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildStatRow('Total Shifts', '${stats['totalShifts']}'),
            _buildStatRow('Early Shifts', '${stats['earlyShifts']}'),
            _buildStatRow('Relief Shifts', '${stats['reliefShifts']}'),
            _buildStatRow('Late Shifts', '${stats['lateShifts']}'),
            _buildStatRow('Night Shifts', '${stats['nightShifts']}'),
            _buildStatRow('Spare Shifts', '${stats['spareShifts']}'),
            _buildStatRow('Bogey Shifts', '${stats['bogeyShifts']}'),
            _buildStatRow('Rest Days Worked', '${stats['restDaysWorked'] ?? 0}'),
            // Consider adding Bank Holiday shifts if needed: _buildStatRow('Bank Holiday Shifts', '${stats['bankHolidayShifts'] ?? 0}'),
            const Divider(height: 24),
            _buildStatRow('Date Range', stats['dateRange'] as String? ?? 'N/A'), // Add null check
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
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