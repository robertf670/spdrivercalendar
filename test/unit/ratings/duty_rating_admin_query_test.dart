import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/ratings/duty_rating_admin_query.dart';
import 'package:spdrivercalendar/features/ratings/duty_rating_vote.dart';

void main() {
  DutyRatingVote vote({
    required String id,
    required String code,
    required String date,
    int score = 7,
    String note = '',
    bool noteRemoved = false,
    String dayType = 'MON-FRI',
  }) {
    return DutyRatingVote(
      id: id,
      userId: 'user-$id',
      dutyCode: code,
      dayType: dayType,
      era: 'current',
      date: date,
      score: score,
      note: note,
      noteRemoved: noteRemoved,
    );
  }

  test('lists every vote newest first, including those with no note', () {
    final rows = DutyRatingAdminQuery.apply(
      votes: [
        vote(id: 'old', code: 'PZ1/10', date: '2026-09-20', note: 'mine'),
        vote(id: 'new', code: 'PZ2/13', date: '2026-10-02'),
        vote(id: 'mid', code: 'PZ1/11', date: '2026-09-24', score: 3),
      ],
      search: '',
    );

    expect(rows.map((row) => row.dutyCode), ['PZ2/13', 'PZ1/11', 'PZ1/10']);
    expect(DutyRatingAdminQuery.subtitle(rows.first), '2026-10-02 · MON-FRI · 7/10 · No note');
  });

  test('search matches duty code, score, and note', () {
    final votes = [
      vote(id: 'a', code: 'PZ1/10', date: '2026-10-02', note: 'slow'),
      vote(id: 'b', code: 'PZ2/13', date: '2026-10-02', score: 9),
    ];

    expect(
      DutyRatingAdminQuery.apply(votes: votes, search: 'pz2').single.dutyCode,
      'PZ2/13',
    );
    expect(
      DutyRatingAdminQuery.apply(votes: votes, search: 'slow').single.dutyCode,
      'PZ1/10',
    );
    expect(
      DutyRatingAdminQuery.apply(votes: votes, search: '9').single.dutyCode,
      'PZ2/13',
    );
  });
}
