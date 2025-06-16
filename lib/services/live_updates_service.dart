import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/live_update.dart';

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

  /// Get only currently active updates (between start and end time)
  static Stream<List<LiveUpdate>> getActiveUpdatesStream() {
    final now = DateTime.now();
    return _firestore
        .collection(_collection)
        .where('endTime', isGreaterThan: Timestamp.fromDate(now))
        .orderBy('endTime')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return LiveUpdate.fromFirestore(doc.id, data);
      }).where((update) {
        // Filter in memory for active updates
        return update.isActive;
      }).toList();
    });
  }

  /// Add a new live update
  static Future<String> addUpdate(LiveUpdate update) async {
    try {
      final docRef = await _firestore.collection(_collection).add({
        'title': update.title,
        'description': update.description,
        'priority': update.priority,
        'startTime': Timestamp.fromDate(update.startTime),
        'endTime': Timestamp.fromDate(update.endTime),
        'routesAffected': update.routesAffected,
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add update: $e');
    }
  }

  /// Update an existing live update
  static Future<void> updateUpdate(LiveUpdate update) async {
    try {
      await _firestore.collection(_collection).doc(update.id).update({
        'title': update.title,
        'description': update.description,
        'priority': update.priority,
        'startTime': Timestamp.fromDate(update.startTime),
        'endTime': Timestamp.fromDate(update.endTime),
        'routesAffected': update.routesAffected,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
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