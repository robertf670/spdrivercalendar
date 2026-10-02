import 'package:flutter/material.dart';
import 'package:spdrivercalendar/features/bus_reports/bus_report.dart';
import 'package:spdrivercalendar/features/bus_reports/bus_report_list_query.dart';
import 'package:spdrivercalendar/features/bus_reports/bus_report_service.dart';

class BusReportsAdminScreen extends StatefulWidget {
  const BusReportsAdminScreen({super.key});

  @override
  State<BusReportsAdminScreen> createState() => _BusReportsAdminScreenState();
}

class _BusReportsAdminScreenState extends State<BusReportsAdminScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _subtitle(BusReport report) {
    return [
      if (report.date.isNotEmpty) BusReportListQuery.displayDate(report.date),
      report.slot.label,
      report.categoryLabel,
      if (report.hasPublicNote)
        report.note
      else if (report.noteRemoved)
        'Note removed'
      else
        'No note',
    ].join(' · ');
  }

  Future<void> _removeNote(BusReport report) async {
    await BusReportService.removeNote(report.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Note removed')),
    );
  }

  Future<void> _deleteReport(BusReport report) async {
    await BusReportService.deleteReport(report);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bus Reports')),
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
              Expanded(
                child: StreamBuilder<List<BusReport>>(
                  stream: BusReportService.watchAllReports(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(child: Text('Could not load reports'));
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final rows = BusReportListQuery.apply(
                      reports: snapshot.data!,
                      search: _search.text,
                      filter: BusReportDateFilter.all,
                    );
                    if (rows.isEmpty) {
                      return Center(
                        child: Text(
                          snapshot.data!.isEmpty
                              ? 'No reports yet'
                              : 'No reports match this search',
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: rows.length,
                      itemBuilder: (context, index) {
                        final report = rows[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          isThreeLine: true,
                          title: Text(report.busNumber),
                          subtitle: Text(_subtitle(report)),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'note') {
                                _removeNote(report);
                              } else if (value == 'delete') {
                                _deleteReport(report);
                              }
                            },
                            itemBuilder: (context) => [
                              if (report.hasPublicNote)
                                const PopupMenuItem(
                                  value: 'note',
                                  child: Text('Remove note'),
                                ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete report'),
                              ),
                            ],
                          ),
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
