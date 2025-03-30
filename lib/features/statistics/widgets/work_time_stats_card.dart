import 'package:flutter/material.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';

class WorkTimeStatisticsCard extends StatelessWidget {
  // Option 1: Pass the Future directly
  final Future<Map<String, Duration>> workTimeStatsFuture;

  // Option 2: Pass the calculated data (requires FutureBuilder outside)
  // final Map<String, Duration> stats;

  const WorkTimeStatisticsCard({
    Key? key,
    required this.workTimeStatsFuture, // Use this if FutureBuilder is inside
    // required this.stats, // Use this if FutureBuilder is outside
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // FutureBuilder remains inside this widget for self-containment
    return FutureBuilder<Map<String, Duration>>(
      future: workTimeStatsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Consistent loading indicator
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          // Consistent error message
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40.0),
              child: Text('Error calculating work times: ${snapshot.error}'),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          // Consistent empty state message
           return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40.0),
              child: Text('No work time data available for calculation.'),
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
              _buildWorkTimeStatItem(
                'This Week',
                _formatDuration(stats['thisWeek'] ?? Duration.zero),
                Icons.calendar_today,
                Colors.blue,
              ),
              const Divider(height: 1),
              _buildWorkTimeStatItem(
                'Last Week',
                _formatDuration(stats['lastWeek'] ?? Duration.zero),
                Icons.arrow_back,
                Colors.green,
              ),
              const Divider(height: 1),
              _buildWorkTimeStatItem(
                'This Month',
                _formatDuration(stats['thisMonth'] ?? Duration.zero),
                Icons.calendar_month,
                Colors.orange,
              ),
              const Divider(height: 1),
              _buildWorkTimeStatItem(
                'Last Month',
                _formatDuration(stats['lastMonth'] ?? Duration.zero),
                Icons.arrow_back_ios, // Different icon for variety
                Colors.purple,
              ),
              const Divider(height: 1),
              _buildWorkTimeStatItem(
                'Average Weekly',
                _formatDuration(stats['averageWeekly'] ?? Duration.zero),
                Icons.analytics,
                Colors.teal,
              ),
              const Divider(height: 1),
              _buildWorkTimeStatItem(
                'Total (All Time)',
                _formatDuration(stats['total'] ?? Duration.zero),
                Icons.history,
                Colors.red,
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper moved from the original screen
  Widget _buildWorkTimeStatItem(String title, String time, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6.0),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
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
              color: color.withOpacity(0.1),
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

  // Helper moved from the original screen
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes.toString().padLeft(2, '0')}m'; // Pad minutes
  }
} 