/// Running totals for one duty + day type + era.
class DutyRatingSummaryData {
  const DutyRatingSummaryData({
    required this.dutyCode,
    required this.dayType,
    required this.era,
    required this.zone,
    this.ratingCount = 0,
    this.ratingSum = 0,
    this.histogram = const {},
  });

  final String dutyCode;
  final String dayType;
  final String era;
  final String zone;
  final int ratingCount;
  final int ratingSum;
  final Map<int, int> histogram;

  static const minRankCount = 5;

  double get average => ratingCount == 0 ? 0 : ratingSum / ratingCount;

  String get averageLabel => average.toStringAsFixed(1);

  bool get ranksInTopLists => ratingCount >= minRankCount;

  DutyRatingSummaryData applyVote({int? oldScore, required int newScore}) {
    var count = ratingCount;
    var sum = ratingSum;
    final next = Map<int, int>.from(histogram);

    if (oldScore == null) {
      count += 1;
      sum += newScore;
      next[newScore] = (next[newScore] ?? 0) + 1;
    } else if (oldScore != newScore) {
      sum += newScore - oldScore;
      next[oldScore] = (next[oldScore] ?? 1) - 1;
      if ((next[oldScore] ?? 0) <= 0) next.remove(oldScore);
      next[newScore] = (next[newScore] ?? 0) + 1;
    }

    return DutyRatingSummaryData(
      dutyCode: dutyCode,
      dayType: dayType,
      era: era,
      zone: zone,
      ratingCount: count,
      ratingSum: sum,
      histogram: next,
    );
  }

  DutyRatingSummaryData removeVote(int score) {
    if (ratingCount <= 0) return this;
    final next = Map<int, int>.from(histogram);
    next[score] = (next[score] ?? 1) - 1;
    if ((next[score] ?? 0) <= 0) next.remove(score);
    return DutyRatingSummaryData(
      dutyCode: dutyCode,
      dayType: dayType,
      era: era,
      zone: zone,
      ratingCount: ratingCount - 1,
      ratingSum: ratingSum - score,
      histogram: next,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dutyCode': dutyCode,
      'dayType': dayType,
      'era': era,
      'zone': zone,
      'ratingCount': ratingCount,
      'ratingSum': ratingSum,
      'average': average,
      'histogram': {
        for (var i = 1; i <= 10; i++) '$i': histogram[i] ?? 0,
      },
    };
  }

  factory DutyRatingSummaryData.fromMap(Map<String, dynamic> map) {
    final rawHistogram = map['histogram'];
    final histogram = <int, int>{};
    if (rawHistogram is Map) {
      rawHistogram.forEach((key, value) {
        final score = int.tryParse(key.toString());
        final count = _asInt(value);
        if (score != null && count > 0) histogram[score] = count;
      });
    }
    return DutyRatingSummaryData(
      dutyCode: map['dutyCode'] as String? ?? '',
      dayType: map['dayType'] as String? ?? 'MON-FRI',
      era: map['era'] as String? ?? 'current',
      zone: map['zone'] as String? ?? 'other',
      ratingCount: _asInt(map['ratingCount']),
      ratingSum: _asInt(map['ratingSum']),
      histogram: histogram,
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }
}

class DutyRatingLists {
  DutyRatingLists._();

  static List<DutyRatingSummaryData> rankable(
    Iterable<DutyRatingSummaryData> rows,
  ) {
    return rows.where((row) => row.ranksInTopLists).toList();
  }

  static List<DutyRatingSummaryData> top10(
    Iterable<DutyRatingSummaryData> rows,
  ) {
    final list = rankable(rows)
      ..sort((a, b) {
        final avg = b.average.compareTo(a.average);
        if (avg != 0) return avg;
        final count = b.ratingCount.compareTo(a.ratingCount);
        if (count != 0) return count;
        return a.dutyCode.compareTo(b.dutyCode);
      });
    return list.take(10).toList();
  }

  static List<DutyRatingSummaryData> lowest10(
    Iterable<DutyRatingSummaryData> rows,
  ) {
    final list = rankable(rows)
      ..sort((a, b) {
        final avg = a.average.compareTo(b.average);
        if (avg != 0) return avg;
        final count = b.ratingCount.compareTo(a.ratingCount);
        if (count != 0) return count;
        return a.dutyCode.compareTo(b.dutyCode);
      });
    return list.take(10).toList();
  }
}
