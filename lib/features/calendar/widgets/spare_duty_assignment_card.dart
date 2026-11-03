import 'package:flutter/material.dart';
import 'package:spdrivercalendar/features/bus_reports/bus_report_key.dart';
import 'package:spdrivercalendar/features/bus_reports/bus_report_row_actions.dart';
import 'package:spdrivercalendar/features/calendar/widgets/assigned_duty_board_button.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';

/// One assigned spare duty: the duty, its bus, and the report action.
class SpareDutyAssignmentCard extends StatelessWidget {
  const SpareDutyAssignmentCard({
    super.key,
    required this.dutyCode,
    required this.timeLabel,
    required this.date,
    required this.busNumber,
    required this.tracking,
    required this.onTrack,
    required this.onEditBus,
    required this.onRemoveDuty,
  });

  final String dutyCode;
  final String timeLabel;
  final DateTime date;
  final String? busNumber;
  final bool tracking;
  final VoidCallback onTrack;
  final VoidCallback onEditBus;
  final VoidCallback onRemoveDuty;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bus = busNumber;
    final hasBus = bus != null && bus.isNotEmpty;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dutyCode,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        timeLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                AssignedDutyBoardButton(
                  dutyCode: dutyCode,
                  date: date,
                  compact: true,
                ),
                IconButton(
                  tooltip: 'Remove duty',
                  onPressed: onRemoveDuty,
                  icon: Icon(Icons.delete_outline, color: scheme.error),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: scheme.outlineVariant),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
            child: hasBus
                ? _AssignedBus(
                    busNumber: bus,
                    tracking: tracking,
                    onTrack: onTrack,
                    onEditBus: onEditBus,
                    date: date,
                    dutyCode: dutyCode,
                  )
                : _NoBus(onAdd: onEditBus),
          ),
        ],
      ),
    );
  }
}

class _AssignedBus extends StatelessWidget {
  const _AssignedBus({
    required this.busNumber,
    required this.tracking,
    required this.onTrack,
    required this.onEditBus,
    required this.date,
    required this.dutyCode,
  });

  final String busNumber;
  final bool tracking;
  final VoidCallback onTrack;
  final VoidCallback onEditBus;
  final DateTime date;
  final String dutyCode;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.directions_bus, size: 22, color: AppTheme.successColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                busNumber,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              tooltip: 'Track $busNumber',
              onPressed: tracking ? null : onTrack,
              visualDensity: VisualDensity.compact,
              icon: tracking
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.location_on, color: scheme.primary),
            ),
            TextButton(
              onPressed: onEditBus,
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('Edit'),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 30),
          child: BusReportRowActions(
            busNumber: busNumber,
            date: date,
            slot: BusReportSlot.forDutyCode(dutyCode),
            compact: true,
          ),
        ),
      ],
    );
  }
}

class _NoBus extends StatelessWidget {
  const _NoBus({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(Icons.directions_bus_outlined, size: 22, color: scheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'No bus',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ),
        TextButton(
          onPressed: onAdd,
          style: TextButton.styleFrom(
            minimumSize: const Size(48, 48),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text('Add'),
        ),
      ],
    );
  }
}
