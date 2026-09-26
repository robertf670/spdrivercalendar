import 'package:flutter/material.dart';
import 'package:spdrivercalendar/features/bus_reports/bus_report.dart';
import 'package:spdrivercalendar/features/bus_reports/bus_report_dialog.dart';
import 'package:spdrivercalendar/features/bus_reports/bus_report_key.dart';
import 'package:spdrivercalendar/features/bus_reports/bus_report_list_query.dart';
import 'package:spdrivercalendar/features/bus_reports/bus_report_service.dart';

Future<void> openBusReportsList(
  BuildContext context, {
  String? busNumber,
}) {
  return Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute(
      builder: (_) => BusReportsListScreen(initialBusNumber: busNumber),
    ),
  );
}

class BusReportsListScreen extends StatefulWidget {
  const BusReportsListScreen({super.key, this.initialBusNumber});

  final String? initialBusNumber;

  @override
  State<BusReportsListScreen> createState() => _BusReportsListScreenState();
}

class _BusReportsListScreenState extends State<BusReportsListScreen> {
  late final TextEditingController _search;
  BusReportDateFilter _filter = BusReportDateFilter.all;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  late Future<List<BusReport>> _future;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(text: widget.initialBusNumber ?? '');
    _future = BusReportService.fetchAllReports();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _future = BusReportService.fetchAllReports());
  }

  void _setPreset(BusReportDateFilter filter) {
    setState(() {
      _filter = filter;
      _rangeStart = null;
      _rangeEnd = null;
    });
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: _rangeStart != null && _rangeEnd != null
          ? DateTimeRange(start: _rangeStart!, end: _rangeEnd!)
          : null,
      helpText: 'Select dates',
      saveText: 'Apply',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _filter = BusReportDateFilter.range;
      _rangeStart = picked.start;
      _rangeEnd = picked.end;
    });
  }

  Future<void> _reportTypedBus() async {
    final controller = TextEditingController();
    final raw = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Report a bus'),
          content: TextField(
            controller: controller,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Bus number',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (raw == null || !mounted) return;
    final bus = BusReportKey.normalizeBusNumber(raw);
    if (bus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid bus number')),
      );
      return;
    }
    await showBusReportDialog(context, busNumber: bus);
    if (!mounted) return;
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bus Reports'),
        actions: [
          IconButton(
            tooltip: 'Report a bus',
            onPressed: _reportTypedBus,
            icon: const Icon(Icons.add),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _search,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  labelText: 'Search bus number',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDateRange,
                      icon: const Icon(Icons.date_range, size: 18),
                      label: Text(
                        _rangeStart != null && _rangeEnd != null
                            ? BusReportListQuery.displayRange(
                                _rangeStart!,
                                _rangeEnd!,
                              )
                            : 'Date range',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  if (_rangeStart != null)
                    IconButton(
                      tooltip: 'Clear dates',
                      onPressed: () => _setPreset(BusReportDateFilter.all),
                      icon: const Icon(Icons.close),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: _filter == BusReportDateFilter.all,
                      onSelected: (_) => _setPreset(BusReportDateFilter.all),
                    ),
                    ChoiceChip(
                      label: const Text('7 days'),
                      selected: _filter == BusReportDateFilter.days7,
                      onSelected: (_) => _setPreset(BusReportDateFilter.days7),
                    ),
                    ChoiceChip(
                      label: const Text('30 days'),
                      selected: _filter == BusReportDateFilter.days30,
                      onSelected: (_) => _setPreset(BusReportDateFilter.days30),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: FutureBuilder<List<BusReport>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text('Unable to load bus reports'),
                      );
                    }
                    final rows = BusReportListQuery.apply(
                      reports: snapshot.data ?? const [],
                      search: _search.text,
                      filter: _filter,
                      rangeStart: _rangeStart,
                      rangeEnd: _rangeEnd,
                    );
                    if (rows.isEmpty) {
                      return Center(
                        child: Text(
                          (snapshot.data ?? const []).isEmpty
                              ? 'No bus reports yet'
                              : 'No reports in this date range',
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: rows.length,
                      itemBuilder: (context, index) {
                        final report = rows[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(report.busNumber),
                          subtitle: Text(
                            [
                              if (report.date.isNotEmpty)
                                BusReportListQuery.displayDate(report.date),
                              report.categoryLabel,
                              if (report.hasPublicNote) report.note,
                            ].join(' · '),
                          ),
                          onTap: () async {
                            await showBusReportDialog(
                              context,
                              busNumber: report.busNumber,
                              date: BusReportListQuery.parseDate(report.date),
                              slot: report.slot,
                            );
                            if (!mounted) return;
                            await _refresh();
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
