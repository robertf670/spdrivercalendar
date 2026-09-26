import 'package:flutter/material.dart';
import 'package:spdrivercalendar/features/ratings/duty_rating_aggregate.dart';
import 'package:spdrivercalendar/features/ratings/duty_rating_row_tile.dart';
import 'package:spdrivercalendar/features/ratings/duty_rating_vote.dart';
import 'package:spdrivercalendar/features/ratings/duty_ratings_list_screen.dart';

class DutyRatingsSection extends StatelessWidget {
  const DutyRatingsSection({
    super.key,
    required this.summaries,
    required this.notes,
    this.onRefresh,
  });

  final List<DutyRatingSummaryData> summaries;
  final List<DutyRatingVote> notes;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final totalVotes = summaries.fold<int>(0, (sum, row) => sum + row.ratingCount);
    final rankableCount = summaries.where((row) => row.ranksInTopLists).length;
    final top = DutyRatingLists.top10(summaries);
    final lowest = DutyRatingLists.lowest10(summaries);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _StatChip(label: 'Votes', value: '$totalVotes'),
            _StatChip(label: 'Duties with 5+', value: '$rankableCount'),
          ],
        ),
        const SizedBox(height: 12),
        if (summaries.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('No ratings yet'),
          )
        else if (top.isEmpty && lowest.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Need 5 ratings before a duty can rank.'),
          )
        else ...[
          _RankList(title: 'Top 10', rows: top),
          const SizedBox(height: 12),
          _RankList(title: 'Lowest 10', rows: lowest),
        ],
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => DutyRatingsListScreen(
                    summaries: summaries,
                    notes: notes,
                  ),
                ),
              );
              onRefresh?.call();
            },
            child: const Text('View all'),
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label: $value'),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _RankList extends StatelessWidget {
  const _RankList({required this.title, required this.rows});

  final String title;
  final List<DutyRatingSummaryData> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Text(
        '$title\nNeed 5 ratings before a duty can rank.',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        for (final row in rows) DutyRatingRowTile(row: row),
      ],
    );
  }
}
