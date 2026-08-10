import 'package:flutter/material.dart';

/// Year grid for winter/summer holiday booking.
///
/// Loads counts via [loadHolidayCounts]; selecting a year pops then calls
/// [onYearSelected].
class HolidayYearPickerDialog extends StatelessWidget {
  const HolidayYearPickerDialog({
    super.key,
    required this.title,
    required this.infoText,
    required this.icon,
    required this.accent,
    required this.startYear,
    required this.loadHolidayCounts,
    required this.onYearSelected,
  });

  final String title;
  final String infoText;
  final IconData icon;
  final MaterialColor accent;
  final int startYear;
  final Future<Map<int, int>> Function() loadHolidayCounts;
  final ValueChanged<int> onYearSelected;

  Map<String, double> _getResponsiveSizes(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    if (screenWidth < 350) {
      return {
        'titleFontSize': 14.0,
        'yearFontSize': 16.0,
        'contentMaxHeightFactor': 0.5,
      };
    } else if (screenWidth < 400) {
      return {
        'titleFontSize': 15.0,
        'yearFontSize': 17.0,
        'contentMaxHeightFactor': 0.52,
      };
    }
    return {
      'titleFontSize': 16.0,
      'yearFontSize': 18.0,
      'contentMaxHeightFactor': 0.55,
    };
  }

  @override
  Widget build(BuildContext context) {
    final sizes = _getResponsiveSizes(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final yearGridAspectRatio =
        (1.2 / textScale.clamp(1.0, 3.0)).clamp(0.38, 1.2);
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: screenWidth < 350 ? 12 : 24,
        vertical: 24,
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? accent.shade900.withValues(alpha: 0.3)
                  : accent.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: sizes['titleFontSize'],
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
          ),
        ],
      ),
      contentPadding: const EdgeInsets.all(16),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: screenHeight * sizes['contentMaxHeightFactor']!,
          maxWidth: screenWidth < 600 ? screenWidth : 500,
        ),
        child: FutureBuilder<Map<int, int>>(
          future: loadHolidayCounts(),
          builder: (context, snapshot) {
            final holidayCounts = snapshot.data ?? {};

            return SingleChildScrollView(
              child: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: yearGridAspectRatio,
                      ),
                      itemCount: 5,
                      itemBuilder: (context, index) {
                        final year = startYear + index;
                        final count = holidayCounts[year] ?? 0;
                        final hasHolidays = count > 0;

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              if (Navigator.of(context).canPop()) {
                                Navigator.of(context).pop();
                              }
                              onYearSelected(year);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isDark
                                    ? (hasHolidays
                                        ? accent.shade900.withValues(alpha: 0.3)
                                        : Theme.of(context).cardColor)
                                    : (hasHolidays
                                        ? accent.shade50
                                        : Colors.grey.shade50),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark
                                      ? (hasHolidays
                                          ? accent.shade700
                                          : Theme.of(context).dividerColor)
                                      : (hasHolidays
                                          ? accent.shade200
                                          : Colors.grey.shade300),
                                  width: hasHolidays ? 2 : 1,
                                ),
                                boxShadow: hasHolidays
                                    ? [
                                        BoxShadow(
                                          color: accent.withValues(alpha: 0.1),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        year.toString(),
                                        style: TextStyle(
                                          fontSize: sizes['yearFontSize'],
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge
                                                  ?.color
                                              : (hasHolidays
                                                  ? accent.shade700
                                                  : Colors.grey.shade700),
                                        ),
                                      ),
                                      if (hasHolidays) ...[
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? accent.shade800
                                                    .withValues(alpha: 0.5)
                                                : accent.shade100,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '$count ${count == 1 ? 'holiday' : 'holidays'}',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: isDark
                                                  ? accent.shade300
                                                  : accent.shade700,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? accent.shade900.withValues(alpha: 0.3)
                            : accent.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: isDark ? accent.shade300 : accent.shade700,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              infoText,
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    isDark ? accent.shade300 : accent.shade700,
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
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
          icon: const Icon(Icons.close),
          label: const Text('Cancel'),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
      ],
    );
  }
}
