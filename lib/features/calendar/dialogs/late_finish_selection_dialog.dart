import 'package:flutter/material.dart';

/// Presentation-only late-finish duration picker.
///
/// Persistence and UI refresh stay with the caller.
class LateFinishSelectionDialog extends StatefulWidget {
  const LateFinishSelectionDialog({
    super.key,
    required this.initialDurationMinutes,
    required this.onSave,
    this.onInvalidDuration,
  });

  final int? initialDurationMinutes;
  final Future<void> Function(int durationMinutes) onSave;
  final VoidCallback? onInvalidDuration;

  static const List<int> durationOptions = [5, 10, 15, 20, 30, 45, 60, 90, 120];

  @override
  State<LateFinishSelectionDialog> createState() =>
      _LateFinishSelectionDialogState();
}

class _LateFinishSelectionDialogState extends State<LateFinishSelectionDialog> {
  late int _selectedDuration;
  late final TextEditingController _customMinutesController;
  bool _useCustom = false;

  @override
  void initState() {
    super.initState();
    _selectedDuration = widget.initialDurationMinutes ?? 15;
    _customMinutesController = TextEditingController(
      text: widget.initialDurationMinutes?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _customMinutesController.dispose();
    super.dispose();
  }

  Map<String, double> _getResponsiveSizes(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    if (screenWidth < 350) {
      return {
        'spacing': 12.0,
        'fontSize': 13.0,
      };
    } else if (screenWidth < 400) {
      return {
        'spacing': 14.0,
        'fontSize': 13.5,
      };
    }
    return {
      'spacing': 16.0,
      'fontSize': 14.0,
    };
  }

  int? _resolveDuration() {
    if (_useCustom && _customMinutesController.text.isNotEmpty) {
      final parsed = int.tryParse(_customMinutesController.text);
      if (parsed != null && parsed > 0) {
        return parsed;
      }
      return null;
    }
    if (!_useCustom) {
      return _selectedDuration;
    }
    return null;
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
          Icon(Icons.schedule, color: Colors.orange),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Select Late Finish',
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
              'Select or enter how many minutes late you finished:',
              style: TextStyle(fontSize: sizes['fontSize']),
            ),
            SizedBox(height: sizes['spacing']),
            DropdownButtonFormField<int?>(
              value: _useCustom ? null : _selectedDuration,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Duration (Select)',
                border: OutlineInputBorder(),
              ),
              items: LateFinishSelectionDialog.durationOptions.map((int value) {
                return DropdownMenuItem<int?>(
                  value: value,
                  child: Text('$value mins'),
                );
              }).toList(),
              onChanged: (int? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedDuration = newValue;
                    _useCustom = false;
                    _customMinutesController.text = '';
                  });
                }
              },
            ),
            SizedBox(height: sizes['spacing']),
            Text(
              'Or enter custom minutes:',
              style: TextStyle(fontSize: sizes['fontSize']),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _customMinutesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Minutes',
                hintText: 'Enter minutes',
                border: OutlineInputBorder(),
                suffixText: 'mins',
              ),
              onChanged: (String value) {
                if (value.isNotEmpty) {
                  final parsed = int.tryParse(value);
                  if (parsed != null && parsed > 0) {
                    setState(() {
                      _selectedDuration = parsed;
                      _useCustom = true;
                    });
                  } else {
                    setState(() {
                      _useCustom = true;
                    });
                  }
                } else {
                  setState(() {
                    _useCustom = false;
                  });
                }
              },
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
          onPressed: () async {
            final finalDuration = _resolveDuration();
            if (finalDuration == null || finalDuration <= 0) {
              widget.onInvalidDuration?.call();
              return;
            }
            await widget.onSave(finalDuration);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
