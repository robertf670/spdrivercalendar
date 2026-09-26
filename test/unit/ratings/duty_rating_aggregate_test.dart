import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/ratings/duty_rating_aggregate.dart';

DutyRatingSummaryData _empty() {
  return const DutyRatingSummaryData(
    dutyCode: 'PZ1/39',
    dayType: 'MON-FRI',
    era: 'current',
    zone: '1',
  );
}

void main() {
  group('DutyRatingSummaryData.applyVote', () {
    test('adds, changes score, and ignores note-only updates', () {
      final added = _empty().applyVote(newScore: 8);
      expect(added.ratingCount, 1);
      expect(added.ratingSum, 8);
      expect(added.average, 8);

      final changed = added.applyVote(oldScore: 8, newScore: 4);
      expect(changed.ratingCount, 1);
      expect(changed.ratingSum, 4);
      expect(changed.histogram[8], isNull);
      expect(changed.histogram[4], 1);

      final sameScore = changed.applyVote(oldScore: 4, newScore: 4);
      expect(sameScore.ratingCount, 1);
      expect(sameScore.ratingSum, 4);

      final removed = sameScore.removeVote(4);
      expect(removed.ratingCount, 0);
      expect(removed.ratingSum, 0);
      expect(removed.average, 0);
      expect(removed.histogram, isEmpty);
    });
  });

  group('DutyRatingLists', () {
    test('top and lowest ignore counts below 5', () {
      final rows = [
        _empty().applyVote(newScore: 10).applyVote(newScore: 10),
        const DutyRatingSummaryData(
          dutyCode: 'PZ1/01',
          dayType: 'MON-FRI',
          era: 'current',
          zone: '1',
          ratingCount: 5,
          ratingSum: 40,
          histogram: {8: 5},
        ),
        const DutyRatingSummaryData(
          dutyCode: 'PZ1/02',
          dayType: 'MON-FRI',
          era: 'current',
          zone: '1',
          ratingCount: 5,
          ratingSum: 10,
          histogram: {2: 5},
        ),
      ];

      expect(
        DutyRatingLists.top10(rows).map((r) => r.dutyCode).toList(),
        ['PZ1/01', 'PZ1/02'],
      );
      expect(
        DutyRatingLists.lowest10(rows).map((r) => r.dutyCode).toList(),
        ['PZ1/02', 'PZ1/01'],
      );
    });
  });
}
