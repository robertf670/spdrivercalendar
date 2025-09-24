import 'package:flutter/material.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';

class SpreadStatisticsCard extends StatelessWidget {
  final Future<Map<String, Duration>> spreadStatsFuture;
  
  const SpreadStatisticsCard({
    Key? key,
    required this.spreadStatsFuture,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, Duration>>(
      future: spreadStatsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40.0),
              child: Text('Error calculating spread statistics: ${snapshot.error}'),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40.0),
              child: Text('No spread data available for calculation.'),
            ),
          );
        }

        final stats = snapshot.data!;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          ),
          child: Column(
            children: [
              _buildSpreadStatItem(
                'This Week',
                _formatDuration(stats['thisWeek'] ?? Duration.zero),
                Icons.schedule,
                Colors.indigo,
              ),
              const Divider(height: 1),
              _buildSpreadStatItem(
                'Last Week',
                _formatDuration(stats['lastWeek'] ?? Duration.zero),
                Icons.arrow_back,
                Colors.deepPurple,
              ),
              const Divider(height: 1),
              _buildSpreadStatItem(
                'This Month',
                _formatDuration(stats['thisMonth'] ?? Duration.zero),
                Icons.calendar_month,
                Colors.blueGrey,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSpreadStatItem(String title, String time, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6.0),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6.0),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20.0,
            ),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15.0,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Text(
              time,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to format duration
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
  }
}
