import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spdrivercalendar/features/calendar/services/roster_schedule_service.dart';
import 'package:spdrivercalendar/features/calendar/services/roster_service.dart';
import 'package:spdrivercalendar/features/calendar/widgets/dialog_action_layout.dart';

/// Result returned when the user saves a rest-day week selection.
class RestDaySetupResult {
  const RestDaySetupResult({
    required this.startWeek,
    this.effectiveDate,
  });

  final int startWeek;

  /// When null, apply immediately using the current week's Sunday.
  final DateTime? effectiveDate;
}

/// Chooses the rest-day week block (first-run or Settings reset).
class RestDaySetupDialog extends StatefulWidget {
  const RestDaySetupDialog({
    super.key,
    required this.initialStartWeek,
    this.allowEffectiveDate = false,
  });

  final int initialStartWeek;
  final bool allowEffectiveDate;

  @override
  State<RestDaySetupDialog> createState() => _RestDaySetupDialogState();
}

class _RestDaySetupDialogState extends State<RestDaySetupDialog> {
  late int _selectedWeek;
  DateTime? _effectiveDate;

  @override
  void initState() {
    super.initState();
    _selectedWeek = widget.initialStartWeek;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Choose rest days:',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Choose the new rest-day block',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              isExpanded: true,
              value: _selectedWeek,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              items: List.generate(5, (index) {
                return DropdownMenuItem<int>(
                  value: index,
                  child: Text(
                    'Rest: ${RosterService.getRestDaysForWeek(index)}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _selectedWeek = value;
                });
              },
            ),
            if (widget.allowEffectiveDate) ...[
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event),
                title: const Text('Apply from date'),
                subtitle: Text(
                  _effectiveDate == null
                      ? 'Not set — apply immediately as normal'
                      : 'Week beginning ${DateFormat('EEE, d MMM yyyy').format(_effectiveDate!)}',
                ),
                trailing: _effectiveDate == null
                    ? null
                    : IconButton(
                        tooltip: 'Clear date',
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _effectiveDate = null;
                          });
                        },
                      ),
                onTap: () async {
                  final selectedDate = await showDatePicker(
                    context: context,
                    initialDate: _effectiveDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                    helpText: 'Select when the new rest days begin',
                  );
                  if (selectedDate != null) {
                    setState(() {
                      _effectiveDate =
                          RosterScheduleService.sundayOfWeek(selectedDate);
                    });
                  }
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        dialogFooterActions(
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(
                  RestDaySetupResult(
                    startWeek: _selectedWeek,
                    effectiveDate: _effectiveDate,
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ],
    );
  }
}
