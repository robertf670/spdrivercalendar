import 'package:flutter/material.dart';
import 'package:spdrivercalendar/features/ratings/duty_rating_aggregate.dart';
import 'package:spdrivercalendar/features/ratings/duty_rating_key.dart';

class DutyRatingRowTile extends StatelessWidget {
  const DutyRatingRowTile({
    super.key,
    required this.row,
    this.onTap,
    this.selected = false,
  });

  final DutyRatingSummaryData row;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final era = DutyRatingKey.eraLabel(row.era);
    final subtitle = [
      DutyRatingKey.dayTypeLabel(row.dayType),
      if (era.isNotEmpty) era,
      '${row.ratingCount} rating${row.ratingCount == 1 ? '' : 's'}',
      if (!row.ranksInTopLists) 'few ratings',
    ].join(' · ');

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      selected: selected,
      title: Text(row.dutyCode),
      subtitle: Text(subtitle),
      trailing: Text(
        row.averageLabel,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      onTap: onTap,
    );
  }
}
