import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spdrivercalendar/features/calendar/services/work_for_others_shift_loader.dart';

/// Presentation dialog for choosing a Work For Others duty.
///
/// Persistence and shift-time lookup stay with the caller.
class WorkForOthersDialog extends StatefulWidget {
  const WorkForOthersDialog({
    super.key,
    required this.shiftDate,
    required this.loadShiftNumbers,
    required this.onAddShift,
  });

  final DateTime shiftDate;
  final Future<List<String>> Function(String selectedZone) loadShiftNumbers;
  final Future<void> Function({
    required String selectedZone,
    required String selectedShiftNumber,
  }) onAddShift;

  @override
  State<WorkForOthersDialog> createState() => _WorkForOthersDialogState();
}

class _WorkForOthersDialogState extends State<WorkForOthersDialog> {
  String _selectedZone = WorkForOthersShiftLoader.zoneOptions.first;
  String _selectedShiftNumber = '';
  List<String> _shiftNumbers = const [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadShiftNumbers();
  }

  Future<void> _loadShiftNumbers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final shifts = await widget.loadShiftNumbers(_selectedZone);
      if (!mounted) return;
      setState(() {
        _shiftNumbers = shifts;
        if (_selectedShiftNumber.isEmpty && shifts.isNotEmpty) {
          _selectedShiftNumber = shifts.first;
        } else if (!shifts.contains(_selectedShiftNumber)) {
          _selectedShiftNumber = shifts.isNotEmpty ? shifts.first : '';
        }
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _shiftNumbers = const [];
        _selectedShiftNumber = '';
        _isLoading = false;
      });
    }
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
    final dropdownValue = _selectedShiftNumber.isEmpty &&
            _shiftNumbers.isNotEmpty
        ? _shiftNumbers.first
        : _selectedShiftNumber;

    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: screenWidth < 350 ? 16.0 : 40.0,
        vertical: screenWidth < 350 ? 16.0 : 24.0,
      ),
      title: Text(
        'Add Work For Others for ${DateFormat('EEE, MMM d').format(widget.shiftDate)}',
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Zone:', style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              value: _selectedZone,
              isExpanded: true,
              items: WorkForOthersShiftLoader.zoneOptions.map((zone) {
                return DropdownMenuItem(
                  value: zone,
                  child: Text(zone),
                );
              }).toList(),
              onChanged: _isSaving
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedZone = value;
                        _selectedShiftNumber = '';
                      });
                      _loadShiftNumbers();
                    },
            ),
            SizedBox(height: sizes['spacing']),
            const Text(
              'Shift Number:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_shiftNumbers.isEmpty)
              const Text('No shifts available for selected zone and date.')
            else
              DropdownButton<String>(
                value: dropdownValue,
                isExpanded: true,
                items: _shiftNumbers.map((shift) {
                  return DropdownMenuItem(
                    value: shift,
                    child: Text(shift),
                  );
                }).toList(),
                onChanged: _isSaving
                    ? null
                    : (value) {
                        if (value == null) return;
                        setState(() {
                          _selectedShiftNumber = value;
                        });
                      },
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _shiftNumbers.isEmpty ||
                  _isLoading ||
                  _isSaving ||
                  _selectedShiftNumber.isEmpty
              ? null
              : () async {
                  setState(() {
                    _isSaving = true;
                  });
                  try {
                    await widget.onAddShift(
                      selectedZone: _selectedZone,
                      selectedShiftNumber: _selectedShiftNumber,
                    );
                  } finally {
                    if (mounted) {
                      setState(() {
                        _isSaving = false;
                      });
                    }
                  }
                },
          child: const Text('Add Shift'),
        ),
      ],
    );
  }
}
