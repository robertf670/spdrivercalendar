import 'package:flutter/material.dart';
import 'package:spdrivercalendar/features/calendar/utils/nights_roster.dart';
import 'package:spdrivercalendar/features/calendar/widgets/dialog_action_layout.dart';

class NightsRestDayDialog extends StatefulWidget {
  const NightsRestDayDialog({
    super.key,
    this.initialWeekIndex = 0,
  });

  final int initialWeekIndex;

  @override
  State<NightsRestDayDialog> createState() => _NightsRestDayDialogState();
}

class _NightsRestDayDialogState extends State<NightsRestDayDialog> {
  late int _selectedWeek;

  @override
  void initState() {
    super.initState();
    _selectedWeek = widget.initialWeekIndex % NightsRoster.weekCount;
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.sizeOf(context).width * 0.9;

    return AlertDialog(
      title: Text(
        'What are your rest days this week?',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
      content: SizedBox(
        width: maxWidth.clamp(0, 500),
        child: DropdownButtonFormField<int>(
          isExpanded: true,
          value: _selectedWeek,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          items: [
            for (var i = 0; i < NightsRoster.weekCount; i++)
              DropdownMenuItem<int>(
                value: i,
                child: Text(
                  NightsRoster.restDaysLabel(i),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() => _selectedWeek = value);
          },
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
              onPressed: () => Navigator.of(context).pop(_selectedWeek),
              child: const Text('Save'),
            ),
          ],
        ),
      ],
    );
  }
}
