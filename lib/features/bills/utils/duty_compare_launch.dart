import 'package:flutter/material.dart';
import 'package:spdrivercalendar/features/bills/models/bill_duty.dart';
import 'package:spdrivercalendar/features/bills/screens/duty_compare_screen.dart';
import 'package:spdrivercalendar/features/bills/services/bills_csv_service.dart';
import 'package:spdrivercalendar/features/calendar/services/roster_service.dart';
import 'package:spdrivercalendar/features/calendar/services/zone2_duties.dart';
import 'package:spdrivercalendar/features/calendar/utils/assigned_duty_board_lookup.dart';

/// Opens Compare with a calendar duty already on your side.
class DutyCompareLaunch {
  DutyCompareLaunch._();

  static bool canCompare(String raw) => zoneFor(raw) != null;

  /// Bills zone for a duty code, or null when it is not on a bill.
  static String? zoneFor(String raw) {
    final code = AssignedDutyBoardLookup.lookupCode(raw);
    if (Zone2Duties.isRoute13Code(code)) return Zone2Duties.zoneLabel;
    if (Zone2Duties.isUniEuroCode(code)) return 'Uni/Euro';
    if (code.startsWith('PZ1/')) return 'Zone 1';
    if (code.startsWith('PZ3/')) return 'Zone 3';
    if (code.startsWith('PZ4/')) return 'Zone 4';
    return null;
  }

  static String dayTypeFor(DateTime date) {
    if (RosterService.runsSaturdayDuties(date)) {
      return 'Sat';
    }
    if (RosterService.isStStephensSaturday(date)) return 'Sun';
    if (date.weekday == DateTime.sunday) return 'Sun';
    return 'M-F';
  }

  static BillDuty? findDuty(List<BillDuty> duties, String raw) {
    final code = AssignedDutyBoardLookup.lookupCode(raw);
    for (final duty in duties) {
      if (duty.shift == code || Zone2Duties.codesMatch(duty.shift, code)) {
        return duty;
      }
    }
    return null;
  }

  /// Loads the bill and pushes Compare. Returns false when the duty is missing.
  static Future<bool> open(
    BuildContext context, {
    required String dutyCode,
    required DateTime date,
  }) async {
    final zone = zoneFor(dutyCode);
    if (zone == null) return false;
    final dayType = dayTypeFor(date);
    final result = await BillsCsvService.load(
      zone: zone,
      dayType: dayType,
      eraDate: date,
    );
    if (!context.mounted) return false;
    final match = findDuty(result.duties, dutyCode);
    if (result.error != null || match == null) return false;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => DutyCompareScreen(
          duties: result.duties,
          zone: zone,
          dayType: dayType,
          date: date,
          initialYoursShift: match.shift,
        ),
      ),
    );
    return true;
  }
}

/// Compare icon for a duty already on a card. Hidden when it is not a bill duty.
class CompareDutyButton extends StatefulWidget {
  const CompareDutyButton({
    super.key,
    required this.dutyCode,
    required this.date,
  });

  final String dutyCode;
  final DateTime date;

  @override
  State<CompareDutyButton> createState() => _CompareDutyButtonState();
}

class _CompareDutyButtonState extends State<CompareDutyButton> {
  bool _loading = false;

  Future<void> _open() async {
    if (_loading) return;
    setState(() => _loading = true);
    final opened = await DutyCompareLaunch.open(
      context,
      dutyCode: widget.dutyCode,
      date: widget.date,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No bill for this duty on this day.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!DutyCompareLaunch.canCompare(widget.dutyCode)) {
      return const SizedBox.shrink();
    }
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: 'Compare duty',
      onPressed: _loading ? null : _open,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      iconSize: 18,
      icon: _loading
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: scheme.primary,
              ),
            )
          : Icon(Icons.compare_arrows, color: scheme.primary),
    );
  }
}
