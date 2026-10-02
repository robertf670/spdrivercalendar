import 'package:spdrivercalendar/features/ratings/duty_rating_vote.dart';

class DutyRatingAdminQuery {
  DutyRatingAdminQuery._();

  static List<DutyRatingVote> apply({
    required List<DutyRatingVote> votes,
    required String search,
  }) {
    final query = search.trim().toLowerCase();
    final next = votes.where((vote) {
      if (vote.dutyCode.isEmpty) return false;
      if (query.isEmpty) return true;
      return vote.dutyCode.toLowerCase().contains(query) ||
          vote.dayType.toLowerCase().contains(query) ||
          vote.era.toLowerCase().contains(query) ||
          vote.date.contains(query) ||
          vote.note.toLowerCase().contains(query) ||
          '${vote.score}'.contains(query);
    }).toList();

    next.sort((a, b) {
      final date = b.date.compareTo(a.date);
      if (date != 0) return date;
      final code = a.dutyCode.compareTo(b.dutyCode);
      if (code != 0) return code;
      return a.id.compareTo(b.id);
    });
    return next;
  }

  static String subtitle(DutyRatingVote vote) {
    return [
      vote.date,
      vote.dayType,
      '${vote.score}/10',
      if (vote.hasPublicNote)
        vote.note
      else if (vote.noteRemoved)
        'Note removed'
      else
        'No note',
    ].join(' · ');
  }
}
