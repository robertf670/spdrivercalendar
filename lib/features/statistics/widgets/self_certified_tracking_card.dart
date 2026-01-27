import 'package:flutter/material.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';
import '../../../services/self_certified_sick_days_service.dart';

class SelfCertifiedTrackingCard extends StatelessWidget {
  final int year;

  const SelfCertifiedTrackingCard({
    super.key,
    required this.year,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: SelfCertifiedSickDaysService.getStatistics(year),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Error loading self-certified tracking: ${snapshot.error}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          );
        }

        final stats = snapshot.data ?? {};
        final firstHalf = stats['firstHalf'] as Map<String, dynamic>? ?? {};
        final secondHalf = stats['secondHalf'] as Map<String, dynamic>? ?? {};
        final yearStats = stats['year'] as Map<String, dynamic>? ?? {};

        final firstHalfUsed = firstHalf['used'] as int? ?? 0;
        final firstHalfRemaining = firstHalf['remaining'] as int? ?? 0;
        final firstHalfLimit = firstHalf['limit'] as int? ?? 2;
        
        final secondHalfUsed = secondHalf['used'] as int? ?? 0;
        final secondHalfRemaining = secondHalf['remaining'] as int? ?? 0;
        final secondHalfLimit = secondHalf['limit'] as int? ?? 2;
        
        final yearUsed = yearStats['used'] as int? ?? 0;
        final yearRemaining = yearStats['remaining'] as int? ?? 0;
        final yearLimit = yearStats['limit'] as int? ?? 4;

        final primaryColor = Theme.of(context).colorScheme.primary;
        final warningColor = Colors.orange;

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
                      Icons.verified_user,
                      color: primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Self-Certified Sick Days Tracking',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Limit: 4 per year (2 per half-year)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 16),
                
                // First Half (Jan-Jun)
                _buildHalfYearSection(
                  context,
                  'First Half (Jan-Jun)',
                  firstHalfUsed,
                  firstHalfRemaining,
                  firstHalfLimit,
                  primaryColor,
                  warningColor,
                ),
                const SizedBox(height: 12),
                
                // Second Half (Jul-Dec)
                _buildHalfYearSection(
                  context,
                  'Second Half (Jul-Dec)',
                  secondHalfUsed,
                  secondHalfRemaining,
                  secondHalfLimit,
                  primaryColor,
                  warningColor,
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                
                // Year Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Year Total',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                      decoration: BoxDecoration(
                        color: (yearUsed >= yearLimit ? warningColor : primaryColor).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Text(
                        '$yearUsed/$yearLimit',
                        style: TextStyle(
                          color: yearUsed >= yearLimit ? warningColor : primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
                if (yearRemaining > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      '$yearRemaining remaining',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ),
                if (yearUsed >= yearLimit)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: warningColor,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Year limit reached',
                            style: TextStyle(
                              fontSize: 12,
                              color: warningColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHalfYearSection(
    BuildContext context,
    String label,
    int used,
    int remaining,
    int limit,
    Color primaryColor,
    Color warningColor,
  ) {
    final isAtLimit = used >= limit;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: (isAtLimit ? warningColor : primaryColor).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Text(
                '$used/$limit',
                style: TextStyle(
                  color: isAtLimit ? warningColor : primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        if (remaining > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4.0, left: 4.0),
            child: Text(
              '$remaining remaining',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ),
        if (isAtLimit)
          Padding(
            padding: const EdgeInsets.only(top: 4.0, left: 4.0),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: warningColor,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  'Limit reached',
                  style: TextStyle(
                    fontSize: 11,
                    color: warningColor,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
