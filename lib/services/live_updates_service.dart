import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/live_update.dart';
import 'user_preferences_service.dart';
import 'poll_service.dart';

class LiveUpdatesService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'live_updates';

  /// Get all live updates as a real-time stream
  /// This automatically updates when data changes in Firebase
  static Stream<List<LiveUpdate>> getUpdatesStream() {
    return _firestore
        .collection(_collection)
        .orderBy('startTime', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return LiveUpdate.fromFirestore(doc.id, data);
      }).toList();
    });
  }

  /// Get only live updates (excludes polls)
  static Stream<List<LiveUpdate>> getUpdatesOnlyStream() {
    return getUpdatesStream().map((items) {
      return items.where((item) => item.isUpdate).toList();
    });
  }

  /// Get only polls (excludes live updates)
  static Stream<List<LiveUpdate>> getPollsStream() {
    return getUpdatesStream().map((items) {
      return items.where((item) => item.isPoll).toList();
    });
  }

  /// Get only currently active updates (between start and end time)
  /// Also includes active polls and ended polls within results window
  static Stream<List<LiveUpdate>> getActiveUpdatesStream() {
    final now = DateTime.now();
    return _firestore
        .collection(_collection)
        .where('endTime', isGreaterThan: Timestamp.fromDate(now))
        .orderBy('endTime')
        .snapshots()
        .asyncMap((snapshot) async {
      final allItems = snapshot.docs.map((doc) {
        final data = doc.data();
        return LiveUpdate.fromFirestore(doc.id, data);
      }).toList();
      
      // Separate updates and polls
      final updates = allItems.where((item) => item.isUpdate && item.isActive).toList();
      final activePolls = allItems.where((item) => item.isPoll && item.isActive).toList();
      
      // Filter updates by user preferences
      final filteredUpdates = await UserPreferencesService.filterUpdatesByPreference<LiveUpdate>(
        updates,
        (update) => update.routesAffected,
      );
      
      // Get ended polls within results window
      final endedPolls = await _getEndedPollsInResultsWindow();
      
      // Filter out dismissed polls
      final dismissedIds = await PollService.getDismissedPollIds();
      final visibleEndedPolls = endedPolls
          .where((poll) => !dismissedIds.contains(poll.id))
          .toList();
      
      // Combine: filtered updates + active polls + visible ended polls
      return [...filteredUpdates, ...activePolls, ...visibleEndedPolls];
    });
  }
  
  /// Get ended polls that are still within results window
  static Future<List<LiveUpdate>> _getEndedPollsInResultsWindow() async {
    try {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection(_collection)
          .where('type', isEqualTo: 'poll')
          .where('resultsVisibleUntil', isGreaterThan: Timestamp.fromDate(now))
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return LiveUpdate.fromFirestore(doc.id, data);
      }).where((poll) => poll.shouldShowPoll && !poll.isActive).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get filtered updates based on user preferences for relevance
  /// Also includes active polls and ended polls within results window
  static Stream<List<LiveUpdate>> getRelevantUpdatesStream() {
    return _firestore
        .collection(_collection)
        .orderBy('startTime', descending: false)
        .snapshots()
        .asyncMap((snapshot) async {
      final allItems = snapshot.docs.map((doc) {
        final data = doc.data();
        return LiveUpdate.fromFirestore(doc.id, data);
      }).toList();
      
      // Separate updates and polls
      final updates = allItems.where((item) => item.isUpdate).toList();
      final polls = allItems.where((item) => item.isPoll).toList();
      
      // Filter updates by user preferences
      final filteredUpdates = await UserPreferencesService.filterUpdatesByPreference<LiveUpdate>(
        updates,
        (update) => update.routesAffected,
      );
      
      // Filter polls: active polls + ended polls within results window (not dismissed)
      final dismissedIds = await PollService.getDismissedPollIds();
      final visiblePolls = polls.where((poll) {
        if (dismissedIds.contains(poll.id)) return false;
        return poll.shouldShowPoll;
      }).toList();
      
      // Combine filtered updates and visible polls
      return [...filteredUpdates, ...visiblePolls];
    });
  }

  /// Add a new live update or poll
  static Future<String> addUpdate(LiveUpdate update) async {
    try {
      final data = update.toFirestore();
      final docRef = await _firestore.collection(_collection).add(data);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add update: $e');
    }
  }

  /// Update an existing live update or poll
  static Future<void> updateUpdate(LiveUpdate update) async {
    try {
      final data = update.toFirestore();
      data['updatedAt'] = Timestamp.fromDate(DateTime.now());
      await _firestore.collection(_collection).doc(update.id).update(data);
    } catch (e) {
      throw Exception('Failed to update: $e');
    }
  }

  /// Delete a live update
  static Future<void> deleteUpdate(String updateId) async {
    try {
      await _firestore.collection(_collection).doc(updateId).delete();
    } catch (e) {
      throw Exception('Failed to delete update: $e');
    }
  }

  /// End an update immediately by setting end time to now
  static Future<void> endUpdateNow(String updateId) async {
    try {
      await _firestore.collection(_collection).doc(updateId).update({
        'endTime': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to end update: $e');
    }
  }

  /// Get a single update by ID
  static Future<LiveUpdate?> getUpdateById(String updateId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(updateId).get();
      if (doc.exists) {
        return LiveUpdate.fromFirestore(doc.id, doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get update: $e');
    }
  }
} 