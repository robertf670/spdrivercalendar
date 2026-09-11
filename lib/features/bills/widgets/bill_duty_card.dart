import 'package:flutter/material.dart';
import 'package:spdrivercalendar/features/bills/models/bill_duty.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';

class BillDutyCard extends StatelessWidget {
  const BillDutyCard({
    super.key,
    required this.duty,
    this.hasBoard = false,
    this.highlighted = false,
    this.compact = false,
    this.onTap,
  });

  final BillDuty duty;
  final bool hasBoard;
  final bool highlighted;
  final bool compact;
  final VoidCallback? onTap;

  Map<String, double> _sizes(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 350) {
      return {
        'padding': 12.0,
        'title': 16.0,
        'hero': 20.0,
        'body': 13.0,
        'meta': 11.0,
        'icon': 16.0,
      };
    }
    if (width < 400) {
      return {
        'padding': 13.0,
        'title': 17.0,
        'hero': 22.0,
        'body': 13.5,
        'meta': 12.0,
        'icon': 17.0,
      };
    }
    return {
      'padding': 16.0,
      'title': 18.0,
      'hero': 24.0,
      'body': 14.0,
      'meta': 12.5,
      'icon': 18.0,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sizes = _sizes(context);
    final scheme = theme.colorScheme;
    final borderColor = highlighted
        ? scheme.outline.withValues(alpha: 0.5)
        : scheme.outlineVariant.withValues(alpha: 0.6);

    return Card(
      elevation: 0,
      color: highlighted ? scheme.surfaceContainerLow : scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(sizes['padding']!),
          child: compact
              ? _buildCompact(context, sizes)
              : _buildFull(context, sizes),
        ),
      ),
    );
  }

  Widget _buildCompact(BuildContext context, Map<String, double> sizes) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                duty.shift,
                style: TextStyle(
                  fontSize: sizes['title'],
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                duty.timeRange,
                style: TextStyle(
                  fontSize: sizes['body'],
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: scheme.onSurface.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
        if (duty.takeUpLocation.isNotEmpty)
          Flexible(
            child: Text(
              duty.takeUpLocation,
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: sizes['meta'],
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        if (hasBoard) ...[
          const SizedBox(width: 8),
          Icon(
            Icons.chevron_right,
            color: scheme.primary,
          ),
        ],
      ],
    );
  }

  Widget _buildFull(BuildContext context, Map<String, double> sizes) {
    final scheme = Theme.of(context).colorScheme;
    final meta = <String>[
      if (duty.displayWork.isNotEmpty) 'Work ${duty.displayWork}',
      if (duty.displayRelief.isNotEmpty) 'Relief ${duty.displayRelief}',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              duty.shift,
              style: TextStyle(
                fontSize: sizes['title'],
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
            if (duty.isWorkout)
              _chip(context, 'Workout', AppTheme.warningColor)
            else if (duty.displaySpread.isNotEmpty)
              _chip(
                context,
                'Spread ${duty.displaySpread}',
                scheme.onSurfaceVariant,
              ),
            if (hasBoard)
              Text(
                'View board',
                style: TextStyle(
                  fontSize: sizes['meta'],
                  fontWeight: FontWeight.w700,
                  color: scheme.primary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          duty.timeRange,
          style: TextStyle(
            fontSize: sizes['hero'],
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
            letterSpacing: 0.4,
            color: scheme.onSurface,
          ),
        ),
        if (duty.routesLabel.isNotEmpty) ...[
          const SizedBox(height: 8),
          _chip(context, duty.routesLabel, scheme.secondary),
        ],
        const SizedBox(height: 14),
        _fact(
          context,
          sizes,
          icon: Icons.login_rounded,
          label: 'Report',
          value: duty.displayReport,
        ),
        if (duty.displayDepart.isNotEmpty)
          _fact(
            context,
            sizes,
            icon: Icons.directions_bus_filled_outlined,
            label: 'Take up',
            value: duty.displayDepart,
            detail: duty.takeUpLocation,
          ),
        if (duty.isWorkout)
          _fact(
            context,
            sizes,
            icon: Icons.fitness_center,
            label: 'Break',
            value: 'Workout',
          )
        else if (duty.hasMealBreak)
          _fact(
            context,
            sizes,
            icon: Icons.free_breakfast_outlined,
            label: 'Break',
            value: _breakTimes,
            detail: _breakLocations,
          ),
        if (duty.displayFinish.isNotEmpty)
          _fact(
            context,
            sizes,
            icon: Icons.flag_outlined,
            label: 'Finish',
            value: duty.displayFinish,
            detail: duty.endLocation,
          ),
        if (duty.hasDistinctSignOff)
          _fact(
            context,
            sizes,
            icon: Icons.logout_rounded,
            label: 'Sign off',
            value: duty.displaySignOff,
          ),
        if (meta.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            meta.join('  ·  '),
            style: TextStyle(
              fontSize: sizes['meta'],
              color: scheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ],
      ],
    );
  }

  String get _breakTimes {
    final start = duty.displayStartBreak;
    final end = duty.displayFinishBreak.isNotEmpty
        ? duty.displayFinishBreak
        : duty.displayBreakReport;
    if (start.isEmpty) return end;
    if (end.isEmpty || end == start) return start;
    return '$start–$end';
  }

  String get _breakLocations {
    final start = duty.breakStartLocation;
    final end = duty.breakEndLocation;
    if (start.isEmpty) return end;
    if (end.isEmpty || end == start) return start;
    return '$start → $end';
  }

  Widget _chip(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _fact(
    BuildContext context,
    Map<String, double> sizes, {
    required IconData icon,
    required String label,
    required String value,
    String? detail,
  }) {
    if (value.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: sizes['icon'],
            color: scheme.onSurface.withValues(alpha: 0.45),
          ),
          const SizedBox(width: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 52, maxWidth: 72),
            child: Text(
              label,
              style: TextStyle(
                fontSize: sizes['meta'],
                fontWeight: FontWeight.w600,
                color: scheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: sizes['body'],
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (detail != null && detail.isNotEmpty)
                  Text(
                    detail,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: sizes['meta'],
                      color: scheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One-line bill row for scanning a long duty list.
class BillDutyListRow extends StatelessWidget {
  const BillDutyListRow({
    super.key,
    required this.duty,
    required this.label,
    this.selected = false,
    this.hasBoard = false,
    this.onTap,
  });

  final BillDuty duty;
  final String label;
  final bool selected;
  final bool hasBoard;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final codeSize = width < 350 ? 15.0 : 16.0;
    final timeSize = width < 350 ? 13.0 : 14.0;
    final metaSize = width < 350 ? 11.0 : 12.0;
    final codeWidth = width < 350 ? 52.0 : 64.0;

    return Material(
      color: selected
          ? scheme.surfaceContainerHighest.withValues(alpha: 0.7)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: width < 350 ? 10 : 12,
            vertical: width < 350 ? 8 : 10,
          ),
          child: Row(
            children: [
              SizedBox(
                width: codeWidth,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: codeSize,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  duty.timeRange,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: timeSize,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              if (duty.isWorkout)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Text(
                    'W/O',
                    style: TextStyle(
                      fontSize: metaSize,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.warningColor,
                    ),
                  ),
                )
              else if (duty.takeUpLocation.isNotEmpty)
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      duty.takeUpLocation,
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: metaSize,
                        color: scheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
              Icon(
                hasBoard ? Icons.chevron_right : Icons.expand_more,
                size: 20,
                color: scheme.onSurface.withValues(alpha: 0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
