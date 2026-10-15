import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spdrivercalendar/features/calendar/services/event_service.dart';
import 'package:spdrivercalendar/features/calendar/utils/duties_in_date_range.dart';
import 'package:spdrivercalendar/models/event.dart';

/// Picks a date range and returns the work-shift duties in that range.
class RemoveDutiesRangeDialog extends StatefulWidget {
  const RemoveDutiesRangeDialog({
    super.key,
    this.initialFrom,
    this.initialTo,
    this.loadEvents,
  });

  final DateTime? initialFrom;
  final DateTime? initialTo;
  final Future<List<Event>> Function()? loadEvents;

  @override
  State<RemoveDutiesRangeDialog> createState() =>
      _RemoveDutiesRangeDialogState();
}

class _RemoveDutiesRangeDialogState extends State<RemoveDutiesRangeDialog> {
  late DateTime? _from = widget.initialFrom;
  late DateTime? _to = widget.initialTo;
  bool _isCounting = false;

  DateTime get _firstAllowed => DateTime(2024);

  DateTime get _lastAllowed => DateTime(2032, 12, 31);

  String _label(DateTime? date) {
    if (date == null) return 'Choose date';
    return DateFormat('d MMM yyyy').format(date);
  }

  Future<void> _pick({required bool isFrom}) async {
    final now = DateTime.now();
    final initial = (isFrom ? _from : _to) ?? DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(_firstAllowed)
          ? _firstAllowed
          : (initial.isAfter(_lastAllowed) ? _lastAllowed : initial),
      firstDate: _firstAllowed,
      lastDate: _lastAllowed,
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isFrom) {
        _from = picked;
      } else {
        _to = picked;
      }
    });
  }

  Future<void> _submit() async {
    final from = _from;
    final to = _to;
    if (from == null || to == null) return;

    setState(() => _isCounting = true);
    final loader = widget.loadEvents ?? EventService.getAllEvents;
    final events = dutiesInDateRange(
      events: await loader(),
      start: from,
      end: to,
    );
    if (!mounted) return;
    setState(() => _isCounting = false);

    if (events.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No duties in that date range.')),
      );
      return;
    }

    final first = from.isBefore(to) ? from : to;
    final last = from.isBefore(to) ? to : from;
    final rangeText =
        '${DateFormat('d MMM yyyy').format(first)} – ${DateFormat('d MMM yyyy').format(last)}';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final width = MediaQuery.sizeOf(dialogContext).width;
        return AlertDialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: width < 350 ? 16 : 40,
          ),
          title: const Text('Remove duties?'),
          content: Text(
            'This deletes ${events.length} ${events.length == 1 ? 'duty' : 'duties'} from $rangeText. Holidays are kept.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
    if (confirmed == true && mounted) {
      Navigator.pop(context, events);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final canSubmit = _from != null && _to != null && !_isCounting;

    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: width < 350 ? 16 : 40,
        vertical: 24,
      ),
      title: const Text('Remove duties'),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: width < 350 ? width : 500,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Choose the dates to clear. Only work duties in this range are removed.',
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('From'),
              subtitle: Text(_label(_from)),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: _isCounting ? null : () => _pick(isFrom: true),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('To'),
              subtitle: Text(_label(_to)),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: _isCounting ? null : () => _pick(isFrom: false),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isCounting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: canSubmit ? _submit : null,
          child: Text(_isCounting ? 'Checking…' : 'Remove'),
        ),
      ],
    );
  }
}
