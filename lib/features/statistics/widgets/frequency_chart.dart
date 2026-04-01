import 'package:flutter/material.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';

/// "Your Top Picks" — a celebratory, story-driven frequency display.
/// Hero treatment for #1, featured cards for #2–3, elegant list for the rest.
class FrequencyChart extends StatelessWidget {
  final Map<String, int> frequencyData;
  final String emptyDataMessage;

  const FrequencyChart({
    super.key,
    required this.frequencyData,
    this.emptyDataMessage = 'No data available',
  });

  Map<String, double> _getSizes(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    // Breakpoints per responsive design rules: 350, 400, 450, 600, 900
    if (w < 350) {
      return {'heroPadding': 14.0, 'heroCountSize': 44.0, 'cardPadding': 10.0, 'fontSize': 11.0};
    } else if (w < 400) {
      return {'heroPadding': 18.0, 'heroCountSize': 50.0, 'cardPadding': 12.0, 'fontSize': 12.0};
    } else if (w < 450) {
      return {'heroPadding': 22.0, 'heroCountSize': 54.0, 'cardPadding': 14.0, 'fontSize': 13.0};
    } else if (w < 600) {
      return {'heroPadding': 26.0, 'heroCountSize': 60.0, 'cardPadding': 16.0, 'fontSize': 14.0};
    } else {
      return {'heroPadding': 28.0, 'heroCountSize': 68.0, 'cardPadding': 18.0, 'fontSize': 14.0};
    }
  }

  @override
  Widget build(BuildContext context) {
    final sizes = _getSizes(context);
    final theme = Theme.of(context);

    if (frequencyData.isEmpty) {
      return _buildEmpty(context, sizes);
    }

    final maxVal = frequencyData.values.reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) {
      return _buildEmpty(context, sizes);
    }

    final total = frequencyData.values.reduce((a, b) => a + b);
    final entries = frequencyData.entries.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Hero: #1
        if (entries.isNotEmpty) _buildHero(context, entries[0], total, sizes),
        // Podium: #2 and #3
        if (entries.length >= 2)
          Padding(
            padding: EdgeInsets.only(top: sizes['cardPadding']! * 0.8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildFeaturedCard(context, entries[1], total, 2, sizes)),
                if (entries.length >= 3) ...[
                  SizedBox(width: sizes['cardPadding']! * 0.8),
                  Expanded(child: _buildFeaturedCard(context, entries[2], total, 3, sizes)),
                ],
              ],
            ),
          ),
        // The rest
        if (entries.length > 3) ...[
          Padding(
            padding: EdgeInsets.only(top: sizes['cardPadding']! * 1.5, bottom: sizes['cardPadding']! * 0.5),
            child: Text(
              'The rest',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
          ),
          ...entries.skip(3).map((e) => _buildRotationRow(context, e, total, sizes)),
        ],
      ],
    );
  }

  Widget _buildHero(BuildContext context, MapEntry<String, int> entry, int total, Map<String, double> sizes) {
    final theme = Theme.of(context);
    final percent = total > 0 ? (entry.value / total * 100) : 0.0;
    final heroPadding = sizes['heroPadding']!;
    final countSize = sizes['heroCountSize']!;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppTheme.primaryColor.withValues(alpha: 0.35),
                  AppTheme.primaryColor.withValues(alpha: 0.15),
                ]
              : [
                  AppTheme.primaryColor.withValues(alpha: 0.2),
                  AppTheme.primaryColor.withValues(alpha: 0.08),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: isDark ? 0.15 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Icon(
                Icons.auto_awesome,
                size: heroPadding * 3,
                color: AppTheme.primaryColor.withValues(alpha: 0.12),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(heroPadding),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: heroPadding * 0.4, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'MOST FREQUENT',
                            style: TextStyle(
                              fontSize: (sizes['fontSize']! - 1).clamp(9.0, 11.0),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          entry.key,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                            letterSpacing: -0.3,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${entry.value} times · ${percent.toStringAsFixed(0)}%',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: heroPadding * 0.6),
                  Container(
                    width: (countSize + 24).clamp(52.0, 100.0),
                    height: (countSize + 24).clamp(52.0, 100.0),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${entry.value}',
                      style: TextStyle(
                        fontSize: countSize * 0.5,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                        height: 1,
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
  }

  Widget _buildFeaturedCard(BuildContext context, MapEntry<String, int> entry, int total, int rank, Map<String, double> sizes) {
    final theme = Theme.of(context);
    final percent = total > 0 ? (entry.value / total * 100) : 0.0;
    final padding = sizes['cardPadding']!;
    final isDark = theme.brightness == Brightness.dark;
    final rankColor = rank == 2 ? AppTheme.secondaryColor : const Color(0xFF7B1FA2);

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: rankColor.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: rankColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '#$rank',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: rankColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${entry.value}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            entry.key,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
          const SizedBox(height: 2),
          Text(
            '${percent.toStringAsFixed(0)}%',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRotationRow(BuildContext context, MapEntry<String, int> entry, int total, Map<String, double> sizes) {
    final theme = Theme.of(context);
    final percent = total > 0 ? (entry.value / total * 100) : 0.0;
    final fontSize = sizes['fontSize']!;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              entry.key,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${entry.value}',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '(${percent.toStringAsFixed(0)}%)',
            style: TextStyle(
              fontSize: fontSize - 1,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, Map<String, double> sizes) {
    final theme = Theme.of(context);
    final padding = sizes['heroPadding']!;

    return Container(
      padding: EdgeInsets.symmetric(vertical: padding * 2, horizontal: padding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.radar_rounded,
            size: 48,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 16),
          Text(
            emptyDataMessage,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
