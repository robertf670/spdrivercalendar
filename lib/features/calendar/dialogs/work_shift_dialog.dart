import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spdrivercalendar/core/constants/app_constants.dart';
import 'package:spdrivercalendar/core/constants/training_constants.dart';
import 'package:spdrivercalendar/features/calendar/services/roster_service.dart';
import 'package:spdrivercalendar/features/calendar/utils/work_shift_zone_options.dart';
import 'package:spdrivercalendar/features/calendar/widgets/custom_training_form.dart';
import 'package:spdrivercalendar/features/calendar/widgets/weekday_repeat_day_toggle.dart';
import 'package:spdrivercalendar/services/donnybrook_feature_service.dart';
import 'package:spdrivercalendar/services/jamestown_feature_service.dart';

/// Result handed to the caller when Add Shift is pressed.
class WorkShiftDialogSelection {
  const WorkShiftDialogSelection({
    required this.selectedZone,
    required this.selectedShiftNumber,
    required this.repeatUniEuroThisWeek,
    required this.uniEuroSelectedDays,
    required this.repeatDutyThisWeek,
    required this.selectedDays,
    required this.fillNext12Weeks,
    required this.fillNext15Weeks,
    required this.fillNext10Weeks,
    this.customTrainingData,
  });

  final String selectedZone;
  final String selectedShiftNumber;
  final bool repeatUniEuroThisWeek;
  final Map<int, bool> uniEuroSelectedDays;
  final bool repeatDutyThisWeek;
  final Map<int, bool> selectedDays;
  final bool fillNext12Weeks;
  final bool fillNext15Weeks;
  final bool fillNext10Weeks;
  final CustomTrainingFormData? customTrainingData;
}

/// Presentation dialog for choosing a work shift.
///
/// Persistence, time lookup, and roster auto-fill stay with the caller.
class WorkShiftDialog extends StatefulWidget {
  const WorkShiftDialog({
    super.key,
    required this.shiftDate,
    required this.isMFMarkedIn,
    required this.isShiftMarkedIn,
    required this.markedInZone,
    required this.jamestownEnabled,
    required this.donnybrook1Enabled,
    required this.loadShiftNumbers,
    required this.dayHasBlockingEvent,
    required this.onAddShift,
  });

  final DateTime shiftDate;
  final bool isMFMarkedIn;
  final bool isShiftMarkedIn;
  final String markedInZone;
  final bool jamestownEnabled;
  final bool donnybrook1Enabled;
  final Future<List<String>> Function(String selectedZone) loadShiftNumbers;
  final bool Function(DateTime date) dayHasBlockingEvent;
  final Future<void> Function(WorkShiftDialogSelection selection) onAddShift;

  @override
  State<WorkShiftDialog> createState() => _WorkShiftDialogState();
}

class _WorkShiftDialogState extends State<WorkShiftDialog> {
  late String _selectedZone;
  String _selectedShiftNumber = '';
  List<String> _shiftNumbers = const [];
  bool _isLoading = true;
  bool _isSaving = false;

  bool _repeatUniEuroThisWeek = false;
  Map<int, bool> _uniEuroSelectedDays = _emptyWeekMap();
  Map<int, bool> _uniEuroDisabledDays = _emptyWeekMap();

  bool _fillNext12Weeks = false;
  bool _fillNext15Weeks = false;
  bool _fillNext10Weeks = false;

  bool _repeatDutyThisWeek = false;
  Map<int, bool> _selectedDays = _emptyWeekMap();
  Map<int, bool> _disabledDays = _emptyWeekMap();

  final GlobalKey<CustomTrainingFormState> _customTrainingFormKey =
      GlobalKey<CustomTrainingFormState>();

  static Map<int, bool> _emptyWeekMap() => {
        0: false,
        1: false,
        2: false,
        3: false,
        4: false,
        5: false,
        6: false,
      };

  @override
  void initState() {
    super.initState();
    final zones = workShiftZoneOptions(
      shiftDate: widget.shiftDate,
      jamestownEnabled: widget.jamestownEnabled,
      donnybrook1Enabled: widget.donnybrook1Enabled,
    );
    _selectedZone = widget.donnybrook1Enabled
        ? DonnybrookFeatureService.zoneLabel
        : (widget.markedInZone.isNotEmpty ? widget.markedInZone : 'Zone 1');
    if (!zones.contains(_selectedZone)) {
      _selectedZone = zones.first;
    }
    _loadShiftNumbers();
  }

  Future<void> _loadShiftNumbers() async {
    if (_selectedZone == '22B/01' ||
        _selectedZone == 'Union' ||
        _selectedZone == 'Mentor') {
      setState(() {
        _shiftNumbers = const [];
        _selectedShiftNumber = '';
        _isLoading = false;
      });
      return;
    }

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

  Map<int, bool> _weekdayBlockingMap() {
    final weekday = widget.shiftDate.weekday;
    final daysToSunday = weekday == 7 ? 0 : weekday;
    final weekStart = widget.shiftDate.subtract(Duration(days: daysToSunday));
    final disabled = <int, bool>{};
    for (var dayIndex = 1; dayIndex <= 5; dayIndex++) {
      final targetDate = weekStart.add(Duration(days: dayIndex));
      disabled[dayIndex] = widget.dayHasBlockingEvent(targetDate);
    }
    return disabled;
  }

  void _autoSelectCurrentWeekday(Map<int, bool> selected, Map<int, bool> disabled) {
    final weekday = widget.shiftDate.weekday;
    if (weekday >= 1 && weekday <= 5 && !(disabled[weekday] ?? false)) {
      selected[weekday] = true;
    }
  }

  bool get _isFixedDutyZone =>
      _selectedZone == '22B/01' ||
      _selectedZone == 'Union' ||
      _selectedZone == 'Mentor';

  bool get _canSubmit =>
      !_isLoading &&
      !_isSaving &&
      (_isFixedDutyZone ||
          (_shiftNumbers.isNotEmpty && _selectedShiftNumber.isNotEmpty));

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenH = MediaQuery.sizeOf(context).height;
    final zones = workShiftZoneOptions(
      shiftDate: widget.shiftDate,
      jamestownEnabled: widget.jamestownEnabled,
      donnybrook1Enabled: widget.donnybrook1Enabled,
    );
    final zoneValue =
        zones.contains(_selectedZone) ? _selectedZone : zones.first;
    final dropdownValue = _selectedShiftNumber.isEmpty && _shiftNumbers.isNotEmpty
        ? _shiftNumbers.first
        : _selectedShiftNumber;

    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: screenWidth < 350 ? 16.0 : 40.0,
        vertical: screenWidth < 350 ? 16.0 : 24.0,
      ),
      title: null,
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: double.maxFinite,
          maxHeight: screenH * 0.72,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Work Shift for ${DateFormat('EEE, MMM d').format(widget.shiftDate)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: screenWidth < 350 ? 18.0 : null,
                    ),
              ),
              const SizedBox(height: 16),
              const Text('Zone:', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButton<String>(
                value: zoneValue,
                isExpanded: true,
                items: zones
                    .map(
                      (zone) => DropdownMenuItem(
                        value: zone,
                        child: Text(zone),
                      ),
                    )
                    .toList(),
                onChanged: _isSaving
                    ? null
                    : (value) {
                        if (value == null || value == _selectedZone) return;
                        setState(() {
                          _selectedZone = value;
                          _selectedShiftNumber = '';
                        });
                        _loadShiftNumbers();
                      },
              ),
              const SizedBox(height: 16),
              const Text('Shift:', style: TextStyle(fontWeight: FontWeight.bold)),
              if (_isFixedDutyZone)
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.grey.withValues(alpha: 0.1),
                  ),
                  child: Text(
                    _selectedZone == 'Union'
                        ? 'Union Duties'
                        : _selectedZone == 'Mentor'
                            ? 'Mentor Duties'
                            : 'Fixed Duty - No shift selection required',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              else if (_isLoading)
                const SizedBox(
                  height: 50,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (_shiftNumbers.isEmpty)
                Text(
                  _selectedZone == 'Zone 2'
                      ? 'Coming soon'
                      : 'No shifts available for selected zone and date',
                )
              else
                DropdownButton<String>(
                  value: dropdownValue,
                  isExpanded: true,
                  items: _shiftNumbers
                      .map(
                        (shift) => DropdownMenuItem(
                          value: shift,
                          child: Text(shift),
                        ),
                      )
                      .toList(),
                  onChanged: _isSaving
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() {
                            _selectedShiftNumber = value;
                          });
                        },
                ),
              if (_selectedZone == 'Training' &&
                  _selectedShiftNumber ==
                      TrainingConstants.customTrainingShiftOption) ...[
                const SizedBox(height: 16),
                CustomTrainingForm(key: _customTrainingFormKey),
              ],
              _buildUniEuroRepeatSection(),
              _buildDutyRepeatSection(),
              _buildZone1MfRosterSection(),
              _buildZone1ShiftRosterSection(),
              _buildZone3ShiftRosterSection(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: !_canSubmit
              ? null
              : () async {
                  setState(() {
                    _isSaving = true;
                  });
                  try {
                    await widget.onAddShift(
                      WorkShiftDialogSelection(
                        selectedZone: _selectedZone,
                        selectedShiftNumber: _selectedShiftNumber,
                        repeatUniEuroThisWeek: _repeatUniEuroThisWeek,
                        uniEuroSelectedDays: Map<int, bool>.from(
                          _uniEuroSelectedDays,
                        ),
                        repeatDutyThisWeek: _repeatDutyThisWeek,
                        selectedDays: Map<int, bool>.from(_selectedDays),
                        fillNext12Weeks: _fillNext12Weeks,
                        fillNext15Weeks: _fillNext15Weeks,
                        fillNext10Weeks: _fillNext10Weeks,
                        customTrainingData: _selectedZone == 'Training' &&
                                _selectedShiftNumber ==
                                    TrainingConstants.customTrainingShiftOption
                            ? _customTrainingFormKey.currentState?.buildData()
                            : null,
                      ),
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

  Widget _buildUniEuroRepeatSection() {
    final dayOfWeek = RosterService.getDayOfWeek(widget.shiftDate);
    final isWeekend = dayOfWeek == 'Saturday' || dayOfWeek == 'Sunday';
    final shouldShow =
        widget.isMFMarkedIn && _selectedZone == 'Uni/Euro' && !isWeekend;
    if (!shouldShow) return const SizedBox.shrink();

    return Column(
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Checkbox(
              value: _repeatUniEuroThisWeek,
              onChanged: _isSaving
                  ? null
                  : (value) {
                      final enabled = value ?? false;
                      setState(() {
                        _repeatUniEuroThisWeek = enabled;
                        if (enabled) {
                          _uniEuroDisabledDays = _weekdayBlockingMap();
                          _uniEuroSelectedDays = _emptyWeekMap();
                          _autoSelectCurrentWeekday(
                            _uniEuroSelectedDays,
                            _uniEuroDisabledDays,
                          );
                        } else {
                          _uniEuroSelectedDays = _emptyWeekMap();
                          _uniEuroDisabledDays = _emptyWeekMap();
                        }
                      });
                    },
            ),
            const Expanded(
              child: Text(
                'Would you like to repeat this shift this week?',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        if (_repeatUniEuroThisWeek) ...[
          const SizedBox(height: 12),
          _weekdayToggleRow(
            selected: _uniEuroSelectedDays,
            disabled: _uniEuroDisabledDays,
          ),
        ],
      ],
    );
  }

  Widget _buildDutyRepeatSection() {
    final dayOfWeek = RosterService.getDayOfWeek(widget.shiftDate);
    final isWeekend = dayOfWeek == 'Saturday' || dayOfWeek == 'Sunday';
    final isJamestownZone =
        _selectedZone == JamestownFeatureService.zoneLabel;
    final isRepeatableDutyZone = _selectedZone == 'Zone 1' ||
        _selectedZone == 'Zone 2' ||
        _selectedZone == 'Zone 3' ||
        _selectedZone == 'Zone 4' ||
        _selectedZone == DonnybrookFeatureService.zoneLabel ||
        (isJamestownZone && widget.jamestownEnabled);
    final zoneMatch =
        widget.isShiftMarkedIn ? (_selectedZone == widget.markedInZone) : true;
    final shouldShow = (widget.isShiftMarkedIn || widget.isMFMarkedIn) &&
        isRepeatableDutyZone &&
        zoneMatch &&
        !isWeekend;
    if (!shouldShow) return const SizedBox.shrink();

    return Column(
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Checkbox(
              value: _repeatDutyThisWeek,
              onChanged: _isSaving
                  ? null
                  : (value) {
                      final enabled = value ?? false;
                      setState(() {
                        _repeatDutyThisWeek = enabled;
                        if (enabled) {
                          _disabledDays = _weekdayBlockingMap();
                          _selectedDays = _emptyWeekMap();
                          _autoSelectCurrentWeekday(
                            _selectedDays,
                            _disabledDays,
                          );
                        } else {
                          _selectedDays = _emptyWeekMap();
                          _disabledDays = _emptyWeekMap();
                        }
                      });
                    },
            ),
            const Expanded(
              child: Text(
                'Would you like to repeat this duty this week?',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        if (_repeatDutyThisWeek) ...[
          const SizedBox(height: 12),
          _weekdayToggleRow(
            selected: _selectedDays,
            disabled: _disabledDays,
          ),
        ],
      ],
    );
  }

  Widget _buildZone1MfRosterSection() {
    final dayOfWeek = RosterService.getDayOfWeek(widget.shiftDate);
    final isWeekend = dayOfWeek == 'Saturday' || dayOfWeek == 'Sunday';
    final dutyInRoster =
        RosterService.isZone1MFDutyInRoster(_selectedShiftNumber);
    final shouldShow = widget.isMFMarkedIn &&
        _selectedZone == 'Zone 1' &&
        !isWeekend &&
        dutyInRoster;
    if (!shouldShow) return const SizedBox.shrink();

    return Column(
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Checkbox(
              value: _fillNext12Weeks,
              onChanged: _isSaving
                  ? null
                  : (value) {
                      setState(() {
                        _fillNext12Weeks = value ?? false;
                      });
                    },
            ),
            const Expanded(
              child: Text(
                'Auto-fill the next 12 weeks from my roster?',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildZone1ShiftRosterSection() {
    final dayIndex = widget.shiftDate.weekday % 7;
    final shiftWeekIndex =
        RosterService.getZone1ShiftWeekIndex(dayIndex, _selectedShiftNumber);
    final shouldShow = AppConstants.enableZone1ShiftDutyRosterAutoFill &&
        widget.isShiftMarkedIn &&
        _selectedZone == 'Zone 1' &&
        shiftWeekIndex != null;
    if (!shouldShow) return const SizedBox.shrink();

    return Column(
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Checkbox(
              value: _fillNext15Weeks,
              onChanged: _isSaving
                  ? null
                  : (value) {
                      setState(() {
                        _fillNext15Weeks = value ?? false;
                      });
                    },
            ),
            const Expanded(
              child: Text(
                'Auto-fill the next 15 weeks from my roster?',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildZone3ShiftRosterSection() {
    final dayIndex = widget.shiftDate.weekday % 7;
    final zone3WeekIndex =
        RosterService.getZone3ShiftWeekIndex(dayIndex, _selectedShiftNumber);
    final shouldShow = widget.isShiftMarkedIn &&
        _selectedZone == 'Zone 3' &&
        zone3WeekIndex != null;
    if (!shouldShow) return const SizedBox.shrink();

    return Column(
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Checkbox(
              value: _fillNext10Weeks,
              onChanged: _isSaving
                  ? null
                  : (value) {
                      setState(() {
                        _fillNext10Weeks = value ?? false;
                      });
                    },
            ),
            const Expanded(
              child: Text(
                'Auto-fill the next 10 weeks from my roster?',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _weekdayToggleRow({
    required Map<int, bool> selected,
    required Map<int, bool> disabled,
  }) {
    Widget toggle(int dayIndex, String label) {
      final isSelected = selected[dayIndex] ?? false;
      final isDisabled = disabled[dayIndex] ?? false;
      return WeekdayRepeatDayToggle(
        label: label,
        isSelected: isSelected,
        isDisabled: isDisabled,
        onTap: () {
          setState(() {
            selected[dayIndex] = !isSelected;
          });
        },
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        toggle(1, 'M'),
        toggle(2, 'T'),
        toggle(3, 'W'),
        toggle(4, 'T'),
        toggle(5, 'F'),
      ],
    );
  }
}
