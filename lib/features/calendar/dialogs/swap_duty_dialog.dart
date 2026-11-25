import 'package:flutter/material.dart';
import 'package:spdrivercalendar/core/widgets/dialog_insets.dart';

class SwapDutyChoice {
  const SwapDutyChoice({
    required this.duty,
    required this.applyToWeek,
  });

  final String duty;
  final bool applyToWeek;
}

/// Picks a replacement duty for the day already open.
class SwapDutyDialog extends StatefulWidget {
  const SwapDutyDialog({
    super.key,
    required this.currentDuty,
    required this.loadDuties,
    required this.showWeekCheckbox,
  });

  final String currentDuty;
  final Future<List<String>> Function() loadDuties;
  final bool showWeekCheckbox;

  @override
  State<SwapDutyDialog> createState() => _SwapDutyDialogState();
}

class _SwapDutyDialogState extends State<SwapDutyDialog> {
  List<String> _duties = const [];
  String? _selected;
  bool _applyToWeek = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final duties = await widget.loadDuties();
    if (!mounted) return;
    setState(() {
      _duties = duties.where((duty) => duty != widget.currentDuty).toList();
      _selected = _duties.isEmpty ? null : _duties.first;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: dialogHorizontalInset(context),
        vertical: screenWidth < 350 ? 16 : 24,
      ),
      title: const Text('Swap duty'),
      content: _loading
          ? const SizedBox(
              width: 48,
              height: 48,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_duties.isEmpty)
                    const Text('No other duties for this day.')
                  else
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _selected,
                      decoration: const InputDecoration(
                        labelText: 'New duty',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (final duty in _duties)
                          DropdownMenuItem(
                            value: duty,
                            child: Text(
                              duty,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (duty) => setState(() => _selected = duty),
                    ),
                  if (widget.showWeekCheckbox) ...[
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _applyToWeek,
                      onChanged: _duties.isEmpty
                          ? null
                          : (value) => setState(() {
                                _applyToWeek = value ?? false;
                              }),
                      title: const Text(
                        'Change every matching weekday this week',
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ],
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _selected == null
              ? null
              : () => Navigator.of(context).pop(
                    SwapDutyChoice(
                      duty: _selected!,
                      applyToWeek: _applyToWeek,
                    ),
                  ),
          child: const Text('Swap'),
        ),
      ],
    );
  }
}
