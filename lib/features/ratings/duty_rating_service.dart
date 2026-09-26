import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:spdrivercalendar/core/constants/app_constants.dart';
import 'package:spdrivercalendar/core/services/storage_service.dart';
import 'package:spdrivercalendar/features/ratings/duty_rating_aggregate.dart';
import 'package:spdrivercalendar/features/ratings/duty_rating_key.dart';
import 'package:spdrivercalendar/features/ratings/duty_rating_vote.dart';

class DutyRatingService {
  DutyRatingService._();

  static const votesCollection = 'duty_rating_votes';
  static const summariesCollection = 'duty_rating_summaries';
  static const _userIdKey = 'anonymous_user_id';

  static FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get _votes =>
      _firestore.collection(votesCollection);

  static CollectionReference<Map<String, dynamic>> get _summaries =>
      _firestore.collection(summariesCollection);

  static bool get isAvailable => Firebase.apps.isNotEmpty;

  static Future<bool> isEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(AppConstants.dutyRatingsEnabledKey) ?? true;
    } catch (_) {
      return true;
    }
  }

  static Future<String> userId() async {
    String? id = await StorageService.getString(_userIdKey);
    if (id == null || id.isEmpty) {
      id = const Uuid().v4();
      await StorageService.saveString(_userIdKey, id);
    }
    return id;
  }

  static Future<DutyRatingVote?> getVote(DutyRatingTarget target) async {
    if (!isAvailable) return null;
    try {
      final id = await userId();
      final snap = await _votes.doc(target.voteDocId(id)).get();
      if (!snap.exists || snap.data() == null) return null;
      return DutyRatingVote.fromMap(snap.id, snap.data()!);
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, DutyRatingVote>> getVotesForTargets(
    Iterable<DutyRatingTarget> targets,
  ) async {
    final result = <String, DutyRatingVote>{};
    if (!isAvailable) return result;
    try {
      final id = await userId();
      for (final target in targets) {
        final snap = await _votes.doc(target.voteDocId(id)).get();
        if (snap.exists && snap.data() != null) {
          result[target.summaryId] = DutyRatingVote.fromMap(
            snap.id,
            snap.data()!,
          );
        }
      }
    } catch (_) {}
    return result;
  }

  static Future<DutyRatingVote> saveVote({
    required DutyRatingTarget target,
    required int score,
    required String note,
  }) async {
    if (score < 1 || score > 10) {
      throw ArgumentError('Score must be between 1 and 10');
    }
    final trimmed = note.trim();
    if (trimmed.length > DutyRatingVote.maxNoteLength) {
      throw ArgumentError('Note must be ${DutyRatingVote.maxNoteLength} characters or fewer');
    }

    final id = await userId();
    final voteRef = _votes.doc(target.voteDocId(id));
    final summaryRef = _summaries.doc(target.encodedSummaryId);

    return _firestore.runTransaction((transaction) async {
      final voteSnap = await transaction.get(voteRef);
      final summarySnap = await transaction.get(summaryRef);

      final existing = voteSnap.exists && voteSnap.data() != null
          ? DutyRatingVote.fromMap(voteSnap.id, voteSnap.data()!)
          : null;

      var summary = summarySnap.exists && summarySnap.data() != null
          ? DutyRatingSummaryData.fromMap(summarySnap.data()!)
          : DutyRatingSummaryData(
              dutyCode: target.dutyCode,
              dayType: target.dayType,
              era: target.era,
              zone: target.zone,
            );

      summary = summary.applyVote(oldScore: existing?.score, newScore: score);

      final hasNote = trimmed.isNotEmpty;
      final noteRemoved = existing?.noteRemoved == true && !hasNote;
      final now = FieldValue.serverTimestamp();

      transaction.set(voteRef, {
        'userId': id,
        'dutyCode': target.dutyCode,
        'dayType': target.dayType,
        'era': target.era,
        'date': target.date,
        'score': score,
        'note': trimmed,
        'noteRemoved': noteRemoved,
        'hasPublicNote': hasNote && !noteRemoved,
        if (existing == null) 'createdAt': now,
        'updatedAt': now,
      }, SetOptions(merge: true));

      transaction.set(summaryRef, {
        ...summary.toMap(),
        'updatedAt': now,
      }, SetOptions(merge: true));

      return DutyRatingVote(
        id: voteRef.id,
        userId: id,
        dutyCode: target.dutyCode,
        dayType: target.dayType,
        era: target.era,
        date: target.date,
        score: score,
        note: trimmed,
        noteRemoved: noteRemoved,
      );
    });
  }

  static Future<List<DutyRatingSummaryData>> fetchSummaries() async {
    if (!isAvailable) return const [];
    try {
      final snap = await _summaries.get();
      return snap.docs
          .map((doc) => DutyRatingSummaryData.fromMap(doc.data()))
          .where((row) => row.dutyCode.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<List<DutyRatingVote>> fetchPublicNotes() async {
    if (!isAvailable) return const [];
    try {
      final snap = await _votes.where('hasPublicNote', isEqualTo: true).get();
      final notes = snap.docs
          .map((doc) => DutyRatingVote.fromMap(doc.id, doc.data()))
          .where((vote) => vote.hasPublicNote)
          .toList();
      notes.sort((a, b) => b.date.compareTo(a.date));
      return notes;
    } catch (_) {
      return const [];
    }
  }

  static Stream<List<DutyRatingVote>> watchPublicNotes() {
    if (!isAvailable) {
      return Stream.value(const []);
    }
    return _votes.where('hasPublicNote', isEqualTo: true).snapshots().map((
      snap,
    ) {
      final notes = snap.docs
          .map((doc) => DutyRatingVote.fromMap(doc.id, doc.data()))
          .where((vote) => vote.hasPublicNote)
          .toList();
      notes.sort((a, b) => b.date.compareTo(a.date));
      return notes;
    });
  }

  static Future<void> removeNote(String voteId) async {
    await _votes.doc(voteId).update({
      'note': '',
      'noteRemoved': true,
      'hasPublicNote': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteOwnVote(DutyRatingTarget target) async {
    final id = await userId();
    await _deleteVoteRef(
      voteRef: _votes.doc(target.voteDocId(id)),
      summaryRef: _summaries.doc(target.encodedSummaryId),
    );
  }

  static Future<void> deleteVote(DutyRatingVote vote) async {
    final target = DutyRatingTarget(
      dutyCode: vote.dutyCode,
      dayType: vote.dayType,
      era: vote.era,
      date: vote.date,
    );
    await _deleteVoteRef(
      voteRef: _votes.doc(vote.id),
      summaryRef: _summaries.doc(target.encodedSummaryId),
    );
  }

  static Future<void> _deleteVoteRef({
    required DocumentReference<Map<String, dynamic>> voteRef,
    required DocumentReference<Map<String, dynamic>> summaryRef,
  }) async {

    await _firestore.runTransaction((transaction) async {
      final voteSnap = await transaction.get(voteRef);
      final summarySnap = await transaction.get(summaryRef);
      if (!voteSnap.exists) return;

      final current = DutyRatingVote.fromMap(voteSnap.id, voteSnap.data()!);
      transaction.delete(voteRef);

      if (summarySnap.exists && summarySnap.data() != null) {
        final next = DutyRatingSummaryData.fromMap(
          summarySnap.data()!,
        ).removeVote(current.score);
        transaction.set(summaryRef, {
          ...next.toMap(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    });
  }
}
