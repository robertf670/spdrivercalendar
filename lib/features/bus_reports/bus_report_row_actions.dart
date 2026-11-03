import 'package:flutter/material.dart';
import 'package:spdrivercalendar/features/bus_reports/bus_report.dart';
import 'package:spdrivercalendar/features/bus_reports/bus_report_dialog.dart';
import 'package:spdrivercalendar/features/bus_reports/bus_report_key.dart';
import 'package:spdrivercalendar/features/bus_reports/bus_report_service.dart';

class BusReportRowActions extends StatefulWidget {
  const BusReportRowActions({
    super.key,
    required this.busNumber,
    required this.date,
    required this.slot,
    this.compact = false,
  });

  final String busNumber;
  final DateTime date;
  final BusReportSlot slot;

  /// Sits under a bus number that is already shown, so the label stays short.
  final bool compact;

  @override
  State<BusReportRowActions> createState() => _BusReportRowActionsState();
}

class _BusReportRowActionsState extends State<BusReportRowActions> {
  late Future<_BusReportRowData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant BusReportRowActions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.busNumber != widget.busNumber ||
        oldWidget.date != widget.date ||
        oldWidget.slot != widget.slot) {
      _future = _load();
    }
  }

  BusReportTarget? get _target => BusReportKey.targetFor(
        rawBusNumber: widget.busNumber,
        date: widget.date,
        slot: widget.slot,
      );

  Future<_BusReportRowData> _load() async {
    final target = _target;
    if (target == null) {
      return const _BusReportRowData(
        canWrite: false,
        own: null,
        reportCount: 0,
      );
    }
    final enabled = await BusReportService.isEnabled();
    final own = await BusReportService.getOwnReport(target);
    final summary = await BusReportService.getSummary(target.busNumber);
    return _BusReportRowData(
      canWrite: BusReportKey.canShowWriteAction(settingsEnabled: enabled),
      own: own,
      reportCount: summary?.reportCount ?? 0,
    );
  }

  Future<void> _open() async {
    await showBusReportDialog(
      context,
      busNumber: widget.busNumber,
      date: widget.date,
      slot: widget.slot,
    );
    if (!mounted) return;
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_BusReportRowData>(
      future: _future,
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (data == null || _target == null) return const SizedBox.shrink();

        final bus = _target!.busNumber;
        final label = widget.compact
            ? _compactLabel(data)
            : _fullLabel(data, bus);

        return Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: _open,
            style: widget.compact
                ? TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(48, 48),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    alignment: Alignment.centerLeft,
                    visualDensity: VisualDensity.compact,
                  )
                : null,
            child: Text(label),
          ),
        );
      },
    );
  }
}

String _compactLabel(_BusReportRowData data) {
  if (data.own != null) return 'Your report: ${data.own!.categoryLabel}';
  if (data.reportCount == 0) return data.canWrite ? 'Report' : 'Reports';
  return 'Reports (${data.reportCount})';
}

String _fullLabel(_BusReportRowData data, String bus) {
  if (data.own != null) return 'Your report: ${data.own!.categoryLabel} · $bus';
  if (data.canWrite) {
    return data.reportCount == 0 ? 'Report $bus' : 'Reports (${data.reportCount}) · $bus';
  }
  return data.reportCount == 0 ? 'Reports · $bus' : 'Reports (${data.reportCount}) · $bus';
}

class _BusReportRowData {
  const _BusReportRowData({
    required this.canWrite,
    required this.own,
    required this.reportCount,
  });

  final bool canWrite;
  final BusReport? own;
  final int reportCount;
}
