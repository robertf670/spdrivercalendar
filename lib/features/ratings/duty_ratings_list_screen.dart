import 'package:flutter/material.dart';
import 'package:spdrivercalendar/features/ratings/duty_rating_aggregate.dart';
import 'package:spdrivercalendar/features/ratings/duty_rating_row_tile.dart';
import 'package:spdrivercalendar/features/ratings/duty_rating_vote.dart';

enum DutyRatingSort { average, count, code }

class DutyRatingsListScreen extends StatefulWidget {
  const DutyRatingsListScreen({
    super.key,
    required this.summaries,
    required this.notes,
  });

  final List<DutyRatingSummaryData> summaries;
  final List<DutyRatingVote> notes;

  @override
  State<DutyRatingsListScreen> createState() => _DutyRatingsListScreenState();
}

class _DutyRatingsListScreenState extends State<DutyRatingsListScreen> {
  final _search = TextEditingController();
  DutyRatingSort _sort = DutyRatingSort.average;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<DutyRatingSummaryData> get _filtered {
    final query = _search.text.trim().toLowerCase();
    final rows = widget.summaries.where((row) {
      if (query.isEmpty) return true;
      return row.dutyCode.toLowerCase().contains(query) ||
          row.dayType.toLowerCase().contains(query);
    }).toList();

    rows.sort((a, b) {
      switch (_sort) {
        case DutyRatingSort.average:
          final avg = b.average.compareTo(a.average);
          if (avg != 0) return avg;
          return b.ratingCount.compareTo(a.ratingCount);
        case DutyRatingSort.count:
          final count = b.ratingCount.compareTo(a.ratingCount);
          if (count != 0) return count;
          return b.average.compareTo(a.average);
        case DutyRatingSort.code:
          return a.dutyCode.compareTo(b.dutyCode);
      }
    });
    return rows;
  }

  List<DutyRatingVote> _notesFor(DutyRatingSummaryData row) {
    final key = '${row.dutyCode}|${row.dayType}|${row.era}';
    return widget.notes.where((note) => note.summaryKey == key).toList();
  }

  Future<void> _showDetails(DutyRatingSummaryData row) {
    final notes = _notesFor(row);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DutyRatingRowTile(row: row),
                  const SizedBox(height: 8),
                  Text(
                    'Score mix',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  _Histogram(row: row),
                  const SizedBox(height: 12),
                  Text(
                    'Notes',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (notes.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('No public notes for this duty.'),
                    )
                  else
                    for (final note in notes)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(note.note),
                        subtitle: Text('${note.date} · score ${note.score}'),
                      ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = _filtered;

    return Scaffold(
      appBar: AppBar(title: const Text('Duty ratings')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _search,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  labelText: 'Search duty code',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Average'),
                      selected: _sort == DutyRatingSort.average,
                      onSelected: (_) =>
                          setState(() => _sort = DutyRatingSort.average),
                    ),
                    ChoiceChip(
                      label: const Text('Count'),
                      selected: _sort == DutyRatingSort.count,
                      onSelected: (_) =>
                          setState(() => _sort = DutyRatingSort.count),
                    ),
                    ChoiceChip(
                      label: const Text('Code'),
                      selected: _sort == DutyRatingSort.code,
                      onSelected: (_) =>
                          setState(() => _sort = DutyRatingSort.code),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: rows.isEmpty
                    ? const Center(child: Text('No ratings yet'))
                    : ListView.builder(
                        itemCount: rows.length,
                        itemBuilder: (context, index) {
                          final row = rows[index];
                          return DutyRatingRowTile(
                            row: row,
                            onTap: () => _showDetails(row),
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

class _Histogram extends StatelessWidget {
  const _Histogram({required this.row});

  final DutyRatingSummaryData row;

  @override
  Widget build(BuildContext context) {
    final maxCount = [
      1,
      for (var i = 1; i <= 10; i++) row.histogram[i] ?? 0,
    ].reduce((a, b) => a > b ? a : b);

    return Column(
      children: [
        for (var score = 10; score >= 1; score--)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                SizedBox(width: 24, child: Text('$score')),
                Expanded(
                  child: LinearProgressIndicator(
                    value: (row.histogram[score] ?? 0) / maxCount,
                    minHeight: 10,
                  ),
                ),
                const SizedBox(width: 8),
                Text('${row.histogram[score] ?? 0}'),
              ],
            ),
          ),
      ],
    );
  }
}
