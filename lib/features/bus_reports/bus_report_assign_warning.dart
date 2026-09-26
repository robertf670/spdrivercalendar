import 'package:flutter/material.dart';
import 'package:spdrivercalendar/features/bus_reports/bus_report_key.dart';
import 'package:spdrivercalendar/features/bus_reports/bus_report_service.dart';
import 'package:spdrivercalendar/features/bus_reports/bus_reports_list_screen.dart';
import 'package:spdrivercalendar/models/event.dart';

Set<String> primaryAssignedBuses(Event event) {
  final buses = <String>{};
  void add(String? raw) {
    final bus = BusReportKey.normalizeBusNumber(raw ?? '');
    if (bus != null) buses.add(bus);
  }

  add(event.firstHalfBus);
  add(event.secondHalfBus);
  event.busAssignments?.values.forEach(add);
  return buses;
}

Future<String?> warnIfRecentBusReportsForAssignment({
  required BuildContext context,
  required Event oldEvent,
  required Event updatedEvent,
}) async {
  final added = primaryAssignedBuses(updatedEvent).difference(
    primaryAssignedBuses(oldEvent),
  );
  for (final bus in added) {
    if (!context.mounted) return null;
    if (await warnIfRecentBusReport(context, bus, openList: false)) {
      return bus;
    }
  }
  return null;
}

Future<bool> warnIfRecentBusReport(
  BuildContext context,
  String rawBusNumber, {
  bool openList = true,
}) async {
  final busNumber = BusReportKey.normalizeBusNumber(rawBusNumber);
  if (busNumber == null) return false;

  final summary = await BusReportService.getSummary(busNumber);
  if (summary == null || !summary.shouldWarnOnAssign()) return false;

  final reports = await BusReportService.fetchReportsForBus(busNumber);
  final recent = reports.where((report) {
    return BusReportKey.isRecent(report.updatedAt);
  }).toList();
  if (recent.isEmpty || !context.mounted) return false;

  final viewReports = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text('Recent report on $busNumber'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Someone wrote about this bus in the last 7 days.',
              ),
              const SizedBox(height: 12),
              for (final report in recent)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(report.categoryLabel),
                  subtitle: report.hasPublicNote ? Text(report.note) : null,
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('View reports'),
          ),
        ],
      );
    },
  );

  if (viewReports == true && openList && context.mounted) {
    await openBusReportsList(context, busNumber: busNumber);
  }
  return viewReports == true;
}
