class DutyRatingVote {
  const DutyRatingVote({
    required this.id,
    required this.userId,
    required this.dutyCode,
    required this.dayType,
    required this.era,
    required this.date,
    required this.score,
    this.note = '',
    this.noteRemoved = false,
  });

  static const maxNoteLength = 140;

  final String id;
  final String userId;
  final String dutyCode;
  final String dayType;
  final String era;
  final String date;
  final int score;
  final String note;
  final bool noteRemoved;

  bool get hasPublicNote => !noteRemoved && note.trim().isNotEmpty;

  String get summaryKey => '$dutyCode|$dayType|$era';

  factory DutyRatingVote.fromMap(String id, Map<String, dynamic> map) {
    return DutyRatingVote(
      id: id,
      userId: map['userId'] as String? ?? '',
      dutyCode: map['dutyCode'] as String? ?? '',
      dayType: map['dayType'] as String? ?? 'MON-FRI',
      era: map['era'] as String? ?? 'current',
      date: map['date'] as String? ?? '',
      score: _asInt(map['score']),
      note: map['note'] as String? ?? '',
      noteRemoved: map['noteRemoved'] == true,
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }
}
