import 'package:flutter/material.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';
import 'package:spdrivercalendar/core/constants/app_constants.dart';
import 'package:spdrivercalendar/core/services/storage_service.dart';
import 'package:spdrivercalendar/services/pay_scale_service.dart';

class SpreadStatisticsCard extends StatelessWidget {
  final Future<Map<String, Duration>> spreadStatsFuture;
  
  const SpreadStatisticsCard({
    super.key,
    required this.spreadStatsFuture,
  });

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

        return FutureBuilder<Map<String, double?>>(
          future: _loadPayRates(),
          builder: (context, paySnapshot) {
            final thisWeekDuration = stats['thisWeek'] ?? Duration.zero;
            final lastWeekDuration = stats['lastWeek'] ?? Duration.zero;
            
            double? thisWeekPay;
            double? lastWeekPay;
            
            if (paySnapshot.hasData) {
              final hourlyRate = paySnapshot.data!['hourlyRate'];
              if (hourlyRate != null) {
                if (thisWeekDuration > Duration.zero) {
                  thisWeekPay = (thisWeekDuration.inMinutes / 60.0) * hourlyRate;
                }
                if (lastWeekDuration > Duration.zero) {
                  lastWeekPay = (lastWeekDuration.inMinutes / 60.0) * hourlyRate;
                }
              }
            }

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
                    _formatDuration(thisWeekDuration),
                    Icons.schedule,
                    Colors.indigo,
                    thisWeekPay,
                    context,
                  ),
                  const Divider(height: 1),
                  _buildSpreadStatItem(
                    'Last Week',
                    _formatDuration(lastWeekDuration),
                    Icons.arrow_back,
                    Colors.deepPurple,
                    lastWeekPay,
                    context,
                  ),
                  const Divider(height: 1),
                  _buildSpreadStatItem(
                    'This Month',
                    _formatDuration(stats['thisMonth'] ?? Duration.zero),
                    Icons.calendar_month,
                    Colors.blueGrey,
                    null, // No pay estimate for This Month
                    context,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<Map<String, double?>> _loadPayRates() async {
    try {
      final payRate = await StorageService.getString(AppConstants.spreadPayRateKey) ?? 'year1+2';
      final hourlyRate = await PayScaleService.getSpreadRate(payRate);
      return {'hourlyRate': hourlyRate};
    } catch (e) {
      return {'hourlyRate': null};
    }
  }

  Widget _buildSpreadStatItem(
    String title,
    String time,
    IconData icon,
    Color color,
    double? payAmount,
    BuildContext context,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Responsive sizing based on screen width
    final isSmallScreen = screenWidth < 400;
    final horizontalPadding = isSmallScreen ? 8.0 : 12.0;
    final verticalPadding = isSmallScreen ? 6.0 : 8.0;
    final iconSize = isSmallScreen ? 18.0 : 20.0;
    final iconPadding = isSmallScreen ? 5.0 : 6.0;
    final titleFontSize = isSmallScreen ? 14.0 : 15.0;
    final timeFontSize = isSmallScreen ? 13.0 : 14.0;
    final payFontSize = isSmallScreen ? 10.0 : 11.0;
    final badgeHorizontalPadding = isSmallScreen ? 8.0 : 10.0;
    final badgeVerticalPadding = isSmallScreen ? 3.0 : 4.0;
    final spacing = isSmallScreen ? 8.0 : 12.0;
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(iconPadding),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6.0),
            ),
            child: Icon(
              icon,
              color: color,
              size: iconSize,
            ),
          ),
          SizedBox(width: spacing),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Right side: Time badge with optional pay estimate below
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: badgeHorizontalPadding,
                  vertical: badgeVerticalPadding,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      time,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: timeFontSize,
                      ),
                    ),
                    // Pay estimate as subtle text below time (if available and > 0)
                    if (payAmount != null && payAmount > 0) ...[
                      SizedBox(height: isSmallScreen ? 1.5 : 2.0),
                      Text(
                        '~€${payAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.green.shade600,
                          fontWeight: FontWeight.w500,
                          fontSize: payFontSize,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
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
