import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/live_update.dart';
import '../core/services/storage_service.dart';

class PollService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'live_updates';
  static const String _dismissedPollsKey = 'dismissed_polls';
  static const String _userIdKey = 'anonymous_user_id';

  /// Get user ID for vote tracking (reuses existing user ID system)
  static Future<String> _getUserId() async {
    // Reuse the user ID from UserActivityService
    String? userId = await StorageService.getString(_userIdKey);
    if (userId == null) {
      // Create new UUID if doesn't exist
      userId = const Uuid().v4();
      await StorageService.saveString(_userIdKey, userId);
    }
    return userId;
  }

  /// Vote in a poll
  /// Returns true if vote was successful, false if user already voted
  static Future<bool> vote(String pollId, int optionIndex) async {
    try {
      final userId = await _getUserId();
      final voteRef = _firestore
          .collection(_collection)
          .doc(pollId)
          .collection('votes')
          .doc(userId);

      // Use transaction to ensure atomicity
      return await _firestore.runTransaction<bool>((transaction) async {
        // Check if user already voted
        final voteDoc = await transaction.get(voteRef);
        if (voteDoc.exists) {
          return false; // User already voted
        }

        // Get poll document
        final pollRef = _firestore.collection(_collection).doc(pollId);
        final pollDoc = await transaction.get(pollRef);
        
        if (!pollDoc.exists) {
          throw Exception('Poll not found');
        }

        final pollData = pollDoc.data()!;
        final poll = LiveUpdate.fromFirestore(pollId, pollData);

        // Validate poll is active
        if (!poll.isActive) {
          throw Exception('Poll is not active');
        }

        // Validate option index
        if (poll.pollOptions == null || 
            optionIndex < 0 || 
            optionIndex >= poll.pollOptions!.length) {
          throw Exception('Invalid option index');
        }

        // Create vote document
        transaction.set(voteRef, {
          'optionIndex': optionIndex,
          'votedAt': FieldValue.serverTimestamp(),
        });

        // Update vote counts atomically
        final currentCounts = List<int>.from(poll.voteCounts ?? []);
        if (currentCounts.length != poll.pollOptions!.length) {
          currentCounts.clear();
          currentCounts.addAll(List.filled(poll.pollOptions!.length, 0));
        }
        currentCounts[optionIndex] = currentCounts[optionIndex] + 1;
        final newTotalVotes = (poll.totalVotes ?? 0) + 1;

        transaction.update(pollRef, {
          'voteCounts': currentCounts,
          'totalVotes': newTotalVotes,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return true;
      });
    } catch (e) {
      throw Exception('Failed to vote: $e');
    }
  }

  /// Check if user has voted in a poll
  static Future<bool> hasUserVoted(String pollId) async {
    try {
      final userId = await _getUserId();
      final voteDoc = await _firestore
          .collection(_collection)
          .doc(pollId)
          .collection('votes')
          .doc(userId)
          .get();
      return voteDoc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Get user's vote for a poll (returns option index or null)
  static Future<int?> getUserVote(String pollId) async {
    try {
      final userId = await _getUserId();
      final voteDoc = await _firestore
          .collection(_collection)
          .doc(pollId)
          .collection('votes')
          .doc(userId)
          .get();
      
      if (voteDoc.exists) {
        return voteDoc.data()?['optionIndex'] as int?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Dismiss a poll (hide it from user's view)
  static Future<void> dismissPoll(String pollId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dismissed = prefs.getStringList(_dismissedPollsKey) ?? [];
      if (!dismissed.contains(pollId)) {
        dismissed.add(pollId);
        await prefs.setStringList(_dismissedPollsKey, dismissed);
      }
    } catch (e) {
      // Fail silently
    }
  }

  /// Check if poll is dismissed
  static Future<bool> isPollDismissed(String pollId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dismissed = prefs.getStringList(_dismissedPollsKey) ?? [];
      return dismissed.contains(pollId);
    } catch (e) {
      return false;
    }
  }

  /// Get all dismissed poll IDs
  static Future<Set<String>> getDismissedPollIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dismissed = prefs.getStringList(_dismissedPollsKey) ?? [];
      return dismissed.toSet();
    } catch (e) {
      return {};
    }
  }

  /// Clear dismissed polls (for testing/admin)
  static Future<void> clearDismissedPolls() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_dismissedPollsKey);
    } catch (e) {
      // Fail silently
    }
  }

  /// Check if vote counts should be shown based on visibility setting
  static bool shouldShowVoteCounts(LiveUpdate poll, bool hasUserVoted, bool isPollEnded) {
    if (!poll.isPoll || poll.voteVisibility == null) return false;

    switch (poll.voteVisibility) {
      case 'always':
        return true;
      case 'after_vote':
        return hasUserVoted;
      case 'after_end':
        return isPollEnded;
      case 'never':
        return false;
      default:
        return false;
    }
  }

  /// Reset all votes for a poll (admin only)
  /// Deletes all vote documents and resets vote counts to zero
  static Future<void> resetPollVotes(String pollId, int optionCount) async {
    try {
      final votesRef = _firestore
          .collection(_collection)
          .doc(pollId)
          .collection('votes');

      // Get all vote documents
      final votesSnapshot = await votesRef.get();

      // Delete all vote documents in batches (Firestore batch limit is 500)
      if (votesSnapshot.docs.isNotEmpty) {
        final docs = votesSnapshot.docs;
        const batchLimit = 500;
        
        // Process in batches of 500
        for (int i = 0; i < docs.length; i += batchLimit) {
          final batch = _firestore.batch();
          final endIndex = (i + batchLimit < docs.length) ? i + batchLimit : docs.length;
          
          for (int j = i; j < endIndex; j++) {
            batch.delete(docs[j].reference);
          }
          
          await batch.commit();
        }
      }

      // Reset vote counts in poll document
      await _firestore.collection(_collection).doc(pollId).update({
        'voteCounts': List.filled(optionCount, 0),
        'totalVotes': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to reset votes: $e');
    }
  }
}

