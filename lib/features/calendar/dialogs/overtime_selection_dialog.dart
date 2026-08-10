import 'package:flutter/material.dart';

/// Presentation-only overtime duration picker.
///
/// Persistence and UI refresh stay with the caller.
class OvertimeSelectionDialog extends StatefulWidget {
  const OvertimeSelectionDialog({
    super.key,
    required this.initialDurationMinutes,
    required this.onSave,
    required this.onSaveOneHour,
  });

  final int initialDurationMinutes;
  final Future<void> Function(int durationMinutes) onSave;
  final Future<void> Function() onSaveOneHour;

  static const List<int> durationOptions = [10, 20, 30, 40, 50, 60];

  @override
  State<OvertimeSelectionDialog> createState() =>
      _OvertimeSelectionDialogState();
}

class _OvertimeSelectionDialogState extends State<OvertimeSelectionDialog> {
  late int _selectedDuration;

  @override
  void initState() {
    super.initState();
    _selectedDuration = widget.initialDurationMinutes;
  }

  Map<String, double> _getResponsiveSizes(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    if (screenWidth < 350) {
      return {'spacing': 12.0};
    } else if (screenWidth < 400) {
      return {'spacing': 14.0};
    }
    return {'spacing': 16.0};
  }

  @override
  Widget build(BuildContext context) {
    final sizes = _getResponsiveSizes(context);
    final screenWidth = MediaQuery.sizeOf(context).width;

    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: screenWidth < 350 ? 16.0 : 40.0,
        vertical: screenWidth < 350 ? 16.0 : 24.0,
      ),
      title: const Row(
        children: [
          Icon(Icons.monetization_on, color: Colors.orange),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Select Overtime',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select overtime duration:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: sizes['spacing']),
            DropdownButtonFormField<int>(
              value: _selectedDuration,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Duration',
                border: OutlineInputBorder(),
              ),
              items: OvertimeSelectionDialog.durationOptions.map((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text('$value mins'),
                );
              }).toList(),
              onChanged: (int? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedDuration = newValue;
                  });
                }
              },
            ),
            SizedBox(height: sizes['spacing']),
            Center(
              child: TextButton(
                onPressed: () async => widget.onSaveOneHour(),
                child: const Text('1 Hour (Common)'),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async => widget.onSave(_selectedDuration),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
