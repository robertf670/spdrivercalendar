import 'package:flutter/material.dart';
import 'package:spdrivercalendar/features/bus_reports/bus_report.dart';
import 'package:spdrivercalendar/features/bus_reports/bus_report_key.dart';
import 'package:spdrivercalendar/features/bus_reports/bus_report_list_query.dart';
import 'package:spdrivercalendar/features/bus_reports/bus_report_service.dart';

Future<void> showBusReportDialog(
  BuildContext context, {
  required String busNumber,
  DateTime? date,
  BusReportSlot slot = BusReportSlot.full,
  bool allowWrite = true,
}) {
  final target = BusReportKey.targetFor(
    rawBusNumber: busNumber,
    date: date ?? DateTime.now(),
    slot: slot,
  );
  if (target == null) return Future.value();
  return showDialog<void>(
    context: context,
    builder: (context) => BusReportDialog(
      target: target,
      allowWrite: allowWrite,
    ),
  );
}

class BusReportDialog extends StatefulWidget {
  const BusReportDialog({
    super.key,
    required this.target,
    this.allowWrite = true,
  });

  final BusReportTarget target;
  final bool allowWrite;

  @override
  State<BusReportDialog> createState() => _BusReportDialogState();
}

class _BusReportDialogState extends State<BusReportDialog> {
  late Future<_BusReportDialogData> _future;
  BusReportCategory? _category;
  late final TextEditingController _noteController;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
    _future = _load();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<_BusReportDialogData> _load() async {
    final enabled = await BusReportService.isEnabled();
    final own = await BusReportService.getOwnReport(widget.target);
    final reports = await BusReportService.fetchReportsForBus(widget.target.busNumber);
    _category = own?.category;
    _noteController.text = own?.note ?? '';
    return _BusReportDialogData(
      canWrite: enabled && widget.allowWrite,
      own: own,
      reports: reports,
    );
  }

  Future<void> _save() async {
    if (!BusReportKey.canSave(category: _category, note: _noteController.text)) {
      setState(() => _error = 'Choose a category or write a short note.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await BusReportService.saveReport(
        target: widget.target,
        category: _category,
        note: _noteController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Could not save report. Try again.';
      });
    }
  }

  Future<void> _remove() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove report?'),
        content: const Text('This takes your report off this bus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await BusReportService.deleteOwnReport(widget.target);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Could not remove report. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final dialogWidth = width * 0.9 < 500 ? width * 0.9 : 500.0;

    return FutureBuilder<_BusReportDialogData>(
      future: _future,
      builder: (context, snapshot) {
        final data = snapshot.data;
        final own = data?.own;
        final canWrite = data?.canWrite == true;

        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          title: Text(widget.target.busNumber),
          content: SizedBox(
            width: dialogWidth,
            child: data == null
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reports',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        if (data.reports.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text('No reports yet on this bus.'),
                          )
                        else
                          for (final report in BusReportListQuery.apply(
                            reports: data.reports,
                            search: '',
                            filter: BusReportDateFilter.all,
                          ))
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              title: Text(report.categoryLabel),
                              subtitle: Text(
                                [
                                  if (report.date.isNotEmpty)
                                    BusReportListQuery.displayDate(report.date),
                                  if (report.hasPublicNote) report.note,
                                ].join(' · '),
                              ),
                            ),
                        if (canWrite) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Your report',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final category in BusReportCategory.values)
                                ChoiceChip(
                                  label: Text(category.label),
                                  selected: _category == category,
                                  onSelected: _saving
                                      ? null
                                      : (_) => setState(() => _category = category),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _noteController,
                            enabled: !_saving,
                            maxLength: BusReport.maxNoteLength,
                            maxLines: 3,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              labelText: 'Note (optional)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                        if (_error != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: _saving ? null : () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            if (canWrite && own != null)
              TextButton(
                onPressed: _saving ? null : _remove,
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Remove'),
              ),
            if (canWrite)
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(own == null ? 'Save' : 'Update'),
              ),
          ],
        );
      },
    );
  }
}

class _BusReportDialogData {
  const _BusReportDialogData({
    required this.canWrite,
    required this.own,
    required this.reports,
  });

  final bool canWrite;
  final BusReport? own;
  final List<BusReport> reports;
}
