import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spdrivercalendar/core/constants/app_constants.dart';
import 'package:spdrivercalendar/core/constants/training_constants.dart';
import 'package:spdrivercalendar/features/calendar/services/roster_service.dart';
import 'package:spdrivercalendar/features/calendar/services/zone2_duties.dart';
import 'package:spdrivercalendar/features/calendar/utils/spare_time_options.dart';
import 'package:spdrivercalendar/features/calendar/utils/work_shift_duty_repeat.dart';
import 'package:spdrivercalendar/features/calendar/utils/work_shift_zone_options.dart';
import 'package:spdrivercalendar/features/calendar/widgets/custom_training_form.dart';
import 'package:spdrivercalendar/features/calendar/widgets/weekday_repeat_day_toggle.dart';
import 'package:spdrivercalendar/services/donnybrook_feature_service.dart';

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
    this.isNightsRoster = false,
    this.isNightsWorkDay,
  });

  final DateTime shiftDate;
  final bool isMFMarkedIn;
  final bool isShiftMarkedIn;
  final String markedInZone;
  final bool jamestownEnabled;
  final bool donnybrook1Enabled;
  final bool isNightsRoster;
  final bool Function(DateTime date)? isNightsWorkDay;
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
  TimeOfDay? _customSpareTime;

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

  Map<int, bool> _repeatDisabledDays({required bool includeWeekend}) {
    final weekday = widget.shiftDate.weekday;
    final daysToSunday = weekday == 7 ? 0 : weekday;
    final weekStart = widget.shiftDate.subtract(Duration(days: daysToSunday));
    final disabled = <int, bool>{};
    final first = includeWeekend ? 0 : 1;
    final last = includeWeekend ? 6 : 5;
    for (var dayIndex = first; dayIndex <= last; dayIndex++) {
      final targetDate = weekStart.add(Duration(days: dayIndex));
      final restDay = widget.isNightsRoster &&
          !(widget.isNightsWorkDay?.call(targetDate) ?? false);
      disabled[dayIndex] =
          restDay || widget.dayHasBlockingEvent(targetDate);
    }
    return disabled;
  }

  void _autoSelectCurrentDay(
    Map<int, bool> selected,
    Map<int, bool> disabled, {
    required bool includeWeekend,
  }) {
    final dayIndex = includeWeekend
        ? widget.shiftDate.weekday % 7
        : widget.shiftDate.weekday;
    if (!includeWeekend && (dayIndex < 1 || dayIndex > 5)) return;
    if (disabled[dayIndex] ?? false) return;
    selected[dayIndex] = true;
  }

  bool get _isFixedDutyZone =>
      _selectedZone == '22B/01' ||
      _selectedZone == 'Union' ||
      _selectedZone == 'Mentor';

  bool get _needsCustomSpareTime =>
      _selectedZone == 'Spare' &&
      isSpareCustomTimeOption(_selectedShiftNumber);

  String get _resolvedShiftNumber {
    final custom = _customSpareTime;
    if (_needsCustomSpareTime && custom != null) {
      return formatSpareClockTime(custom.hour, custom.minute);
    }
    return _selectedShiftNumber;
  }

  bool get _canSubmit =>
      !_isLoading &&
      !_isSaving &&
      (_isFixedDutyZone ||
          (_shiftNumbers.isNotEmpty &&
              _selectedShiftNumber.isNotEmpty &&
              (!_needsCustomSpareTime || _customSpareTime != null)));

  Future<void> _pickCustomSpareTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _customSpareTime ?? const TimeOfDay(hour: 19, minute: 0),
      helpText: 'Spare start time',
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked == null || !mounted) return;
    setState(() => _customSpareTime = picked);
  }

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
                          _customSpareTime = null;
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
                  _selectedZone == Zone2Duties.zoneLabel &&
                          !Zone2Duties.canAddShiftsOn(widget.shiftDate)
                      ? Zone2Duties.availableFromMessage
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
                            if (!isSpareCustomTimeOption(value)) {
                              _customSpareTime = null;
                            }
                          });
                          if (isSpareCustomTimeOption(value)) {
                            _pickCustomSpareTime();
                          }
                        },
                ),
              if (_needsCustomSpareTime) ...[
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.schedule),
                  title: Text(
                    _customSpareTime == null
                        ? 'Choose start time'
                        : formatSpareClockTime(
                            _customSpareTime!.hour,
                            _customSpareTime!.minute,
                          ),
                  ),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: _isSaving ? null : _pickCustomSpareTime,
                ),
              ],
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
                        selectedShiftNumber: _resolvedShiftNumber,
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
                          _uniEuroDisabledDays =
                              _repeatDisabledDays(includeWeekend: false);
                          _uniEuroSelectedDays = _emptyWeekMap();
                          _autoSelectCurrentDay(
                            _uniEuroSelectedDays,
                            _uniEuroDisabledDays,
                            includeWeekend: false,
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
    final includeWeekend = false;
    final shouldShow = WorkShiftDutyRepeat.shouldShow(
      selectedZone: _selectedZone,
      shiftDate: widget.shiftDate,
      isMFMarkedIn: widget.isMFMarkedIn,
      isShiftMarkedIn: widget.isShiftMarkedIn,
      isNightsRoster: widget.isNightsRoster,
      markedInZone: widget.markedInZone,
      jamestownEnabled: widget.jamestownEnabled,
      isNightsWorkDay: widget.isNightsWorkDay,
    );
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
                          _disabledDays = _repeatDisabledDays(
                            includeWeekend: includeWeekend,
                          );
                          _selectedDays = _emptyWeekMap();
                          _autoSelectCurrentDay(
                            _selectedDays,
                            _disabledDays,
                            includeWeekend: includeWeekend,
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
            includeWeekend: includeWeekend,
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
    bool includeWeekend = false,
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

    final days = includeWeekend
        ? [
            toggle(0, 'S'),
            toggle(1, 'M'),
            toggle(2, 'T'),
            toggle(3, 'W'),
            toggle(4, 'T'),
            toggle(5, 'F'),
            toggle(6, 'S'),
          ]
        : [
            toggle(1, 'M'),
            toggle(2, 'T'),
            toggle(3, 'W'),
            toggle(4, 'T'),
            toggle(5, 'F'),
          ];

    return Wrap(
      alignment: WrapAlignment.spaceEvenly,
      spacing: 4,
      runSpacing: 4,
      children: days,
    );
  }
}
