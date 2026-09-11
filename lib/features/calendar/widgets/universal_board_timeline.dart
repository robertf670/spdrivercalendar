import 'package:flutter/material.dart';
import 'package:spdrivercalendar/models/universal_board.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';

/// Shared running-board timeline used by the calendar dialog and Bills browser.
class UniversalBoardTimeline extends StatelessWidget {
  const UniversalBoardTimeline({
    super.key,
    required this.board,
    this.padding,
  });

  final UniversalBoard board;
  final EdgeInsetsGeometry? padding;

  Map<String, double> _sizes(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 350) {
      return {
        'timeWidth': 56.0,
        'padding': 12.0,
        'title': 15.0,
        'action': 14.0,
        'body': 13.0,
      };
    }
    if (width < 400) {
      return {
        'timeWidth': 62.0,
        'padding': 16.0,
        'title': 16.0,
        'action': 15.0,
        'body': 13.5,
      };
    }
    return {
      'timeWidth': 70.0,
      'padding': 20.0,
      'title': 17.0,
      'action': 16.0,
      'body': 14.0,
    };
  }

  @override
  Widget build(BuildContext context) {
    final sizes = _sizes(context);
    return SingleChildScrollView(
      padding: padding ?? EdgeInsets.all(sizes['padding']!),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: board.sections
            .map((section) => _BoardSectionView(section: section, sizes: sizes))
            .toList(),
      ),
    );
  }
}

class _BoardSectionView extends StatelessWidget {
  const _BoardSectionView({
    required this.section,
    required this.sizes,
  });

  final BoardSection section;
  final Map<String, double> sizes;

  bool get _isFirstHalf =>
      section.type == 'firstHalf' || section.type == 'morning';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _isFirstHalf ? AppTheme.warningColor : AppTheme.primaryColor;
    final accentText = isDark
        ? Color.lerp(accent, Colors.white, 0.45)!
        : Color.lerp(accent, Colors.black, 0.28)!;
    final title = _isFirstHalf ? 'First Half' : 'Second Half';

    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: isDark ? 0.18 : 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 22,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: sizes['title'],
                      color: accentText,
                      letterSpacing: 0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...section.entries.asMap().entries.map((entry) {
            final isLast = entry.key == section.entries.length - 1;
            return _BoardEntryRow(
              entry: entry.value,
              isLast: isLast,
              accent: accent,
              accentText: accentText,
              sizes: sizes,
              onSurface: scheme.onSurface,
              primaryContainer: scheme.primaryContainer,
              onPrimaryContainer: scheme.onPrimaryContainer,
            );
          }),
        ],
      ),
    );
  }
}

class _BoardEntryRow extends StatelessWidget {
  const _BoardEntryRow({
    required this.entry,
    required this.isLast,
    required this.accent,
    required this.accentText,
    required this.sizes,
    required this.onSurface,
    required this.primaryContainer,
    required this.onPrimaryContainer,
  });

  final BoardEntry entry;
  final bool isLast;
  final Color accent;
  final Color accentText;
  final Map<String, double> sizes;
  final Color onSurface;
  final Color primaryContainer;
  final Color onPrimaryContainer;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasDetails = entry.location != null ||
        entry.notes != null ||
        (entry.action.toLowerCase() != 'route' && entry.route != null);
    final isRouteAction =
        entry.action.toLowerCase() == 'route' && entry.route != null;
    final timeWidth = sizes['timeWidth']!;
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: timeWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (entry.time != null)
                  Container(
                    width: timeWidth,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: isDark ? 0.22 : 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      entry.time!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: accentText,
                        height: 1.2,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  )
                else
                  SizedBox(width: timeWidth, height: 30),
                if (!isLast) ...[
                  const SizedBox(height: 6),
                  Container(
                    width: 2,
                    height: hasDetails ? 35 : 15,
                    color: accent.withValues(alpha: 0.22),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: screenWidth < 350 ? 8 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: entry.time != null ? 30 : null,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: isRouteAction
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Route ',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: sizes['action'],
                                  color: onSurface,
                                ),
                              ),
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: primaryContainer,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    entry.route!,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: sizes['action'],
                                      color: onPrimaryContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Text(
                            entry.action,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: sizes['action'],
                              color: onSurface,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                  ),
                ),
                if (hasDetails) const SizedBox(height: 6),
                if (isRouteAction && entry.location != null) ...[
                  _metaRow(
                    icon: Icons.location_on,
                    text: 'From ${entry.location}',
                  ),
                  if (entry.notes != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: _metaRow(
                        icon: Icons.info_outline,
                        text: entry.notes!,
                        italic: true,
                      ),
                    ),
                ] else ...[
                  if (entry.route != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: primaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Route ${entry.route}',
                        style: TextStyle(
                          fontSize: 13,
                          color: onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (entry.location != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: _metaRow(
                        icon: Icons.location_on,
                        text: entry.location!,
                      ),
                    ),
                ],
                if (entry.notes != null && !isRouteAction)
                  Padding(
                    padding: EdgeInsets.only(
                      top: entry.location != null ? 4 : 2,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _metaRow(
                        icon: Icons.info_outline,
                        text: entry.notes!,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaRow({
    required IconData icon,
    required String text,
    bool italic = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: onSurface.withValues(alpha: 0.5)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: sizes['body'],
              fontStyle: italic ? FontStyle.italic : FontStyle.normal,
              color: onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
      ],
    );
  }
}
