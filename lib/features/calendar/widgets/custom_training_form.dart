import 'package:flutter/material.dart';
import 'package:spdrivercalendar/core/constants/training_constants.dart';

/// User-entered values for a custom training duty.
class CustomTrainingFormData {
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String? description;
  final String? location;

  const CustomTrainingFormData({
    required this.startTime,
    required this.endTime,
    this.description,
    this.location,
  });
}

/// Responsive form for custom training times, description, and location.
class CustomTrainingForm extends StatefulWidget {
  final CustomTrainingFormData? initialData;

  const CustomTrainingForm({super.key, this.initialData});

  @override
  CustomTrainingFormState createState() => CustomTrainingFormState();
}

class CustomTrainingFormState extends State<CustomTrainingForm> {
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late final TextEditingController _descriptionController;
  late final TextEditingController _customLocationController;
  String? _locationSelection;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialData;
    _startTime = initial?.startTime ?? const TimeOfDay(hour: 9, minute: 0);
    _endTime = initial?.endTime ?? const TimeOfDay(hour: 15, minute: 0);
    _descriptionController = TextEditingController(text: initial?.description ?? '');

    final location = initial?.location;
    if (location != null &&
        TrainingConstants.presetLocations.contains(location)) {
      _locationSelection = location;
      _customLocationController = TextEditingController();
    } else if (location != null && location.isNotEmpty) {
      _locationSelection = TrainingConstants.customLocationOption;
      _customLocationController = TextEditingController(text: location);
    } else {
      _locationSelection = null;
      _customLocationController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _customLocationController.dispose();
    super.dispose();
  }

  CustomTrainingFormData buildData() {
    final description = _descriptionController.text.trim();
    return CustomTrainingFormData(
      startTime: _startTime,
      endTime: _endTime,
      description: description.isEmpty ? null : description,
      location: TrainingConstants.resolveLocation(
        _locationSelection,
        _customLocationController.text,
      ),
    );
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isStart) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
    });
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Map<String, double> _sizes(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    if (screenWidth < 350) {
      return {'fontSize': 12.0, 'spacing': 10.0};
    } else if (screenWidth < 450) {
      return {'fontSize': 13.0, 'spacing': 12.0};
    }
    return {'fontSize': 14.0, 'spacing': 14.0};
  }

  @override
  Widget build(BuildContext context) {
    final sizes = _sizes(context);
    final fontSize = sizes['fontSize']!;
    final spacing = sizes['spacing']!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Start and finish times',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: fontSize),
        ),
        SizedBox(height: spacing * 0.5),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _pickTime(isStart: true),
                child: Text('Start ${_formatTime(_startTime)}'),
              ),
            ),
            SizedBox(width: spacing * 0.75),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _pickTime(isStart: false),
                child: Text('Finish ${_formatTime(_endTime)}'),
              ),
            ),
          ],
        ),
        SizedBox(height: spacing),
        TextField(
          controller: _descriptionController,
          maxLength: TrainingConstants.maxDescriptionLength,
          decoration: InputDecoration(
            labelText: 'Description (optional)',
            hintText: 'e.g. Wheelchair refresher',
            border: const OutlineInputBorder(),
            counterText: '',
            labelStyle: TextStyle(fontSize: fontSize),
          ),
          style: TextStyle(fontSize: fontSize),
        ),
        SizedBox(height: spacing),
        Text(
          'Location (optional)',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: fontSize),
        ),
        SizedBox(height: spacing * 0.5),
        DropdownButtonFormField<String>(
          value: _locationSelection,
          isExpanded: true,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: 'Select location',
            labelStyle: TextStyle(fontSize: fontSize),
          ),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('No location'),
            ),
            ...TrainingConstants.presetLocations.map(
              (loc) => DropdownMenuItem(value: loc, child: Text(loc)),
            ),
            const DropdownMenuItem<String>(
              value: TrainingConstants.customLocationOption,
              child: Text('Other'),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _locationSelection = value;
            });
          },
        ),
        if (_locationSelection == TrainingConstants.customLocationOption) ...[
          SizedBox(height: spacing * 0.75),
          TextField(
            controller: _customLocationController,
            decoration: InputDecoration(
              labelText: 'Custom location',
              border: const OutlineInputBorder(),
              labelStyle: TextStyle(fontSize: fontSize),
            ),
            style: TextStyle(fontSize: fontSize),
          ),
        ],
      ],
    );
  }
}

/// Whether the finish time is on the next calendar day relative to start.
bool customTrainingEndsNextDay(TimeOfDay start, TimeOfDay end) {
  return end.hour < start.hour ||
      (end.hour == start.hour && end.minute < start.minute);
}

/// Builds shift time map for persisting a custom training event.
Map<String, dynamic> customTrainingShiftTimes(CustomTrainingFormData data) {
  return {
    'startTime': data.startTime,
    'endTime': data.endTime,
    'isNextDay': customTrainingEndsNextDay(data.startTime, data.endTime),
  };
}

Future<CustomTrainingFormData?> showCustomTrainingFormDialog(
  BuildContext context, {
  CustomTrainingFormData? initialData,
  String dialogTitle = 'Training details',
}) async {
  final formKey = GlobalKey<CustomTrainingFormState>();

  return showDialog<CustomTrainingFormData>(
    context: context,
    builder: (dialogContext) {
      final screenWidth = MediaQuery.sizeOf(dialogContext).width;
      return AlertDialog(
        title: Text(dialogTitle),
        content: SizedBox(
          width: screenWidth < 600 ? screenWidth * 0.9 : 500,
          child: SingleChildScrollView(
            child: CustomTrainingForm(
              key: formKey,
              initialData: initialData,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final data = formKey.currentState?.buildData();
              if (data != null) {
                Navigator.of(dialogContext).pop(data);
              }
            },
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
}
