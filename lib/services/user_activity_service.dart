import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:uuid/uuid.dart';
import '../core/services/storage_service.dart';

class UserActivityService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _dailyActivityCollection = 'daily_activity';
  static const String _userActivityCollection = 'user_activity';
  static const String _userIdKey = 'anonymous_user_id';

  static bool get _isWeb => kIsWeb;

  /// Track user activity (call this on app startup)
  static Future<void> trackUserActivity() async {
    try {
      final userId = await _getOrCreateUserId();
      final today = _getTodayString();

      // Check if user was already active today
      final userDoc = await _firestore
          .collection(_userActivityCollection)
          .doc(userId)
          .get();

      String? lastActiveDate;
      if (userDoc.exists) {
        lastActiveDate = userDoc.data()?['last_active_date'];
      }

      // If user wasn't active today, increment the daily counter
      if (lastActiveDate != today) {
        await _incrementDailyCounter(today, isWeb: _isWeb);

        // Update user's last active date and platform
        await _firestore
            .collection(_userActivityCollection)
            .doc(userId)
            .set({
          'last_active_date': today,
          'last_activity_timestamp': FieldValue.serverTimestamp(),
          'platform': _isWeb ? 'web' : 'mobile',
        }, SetOptions(merge: true));
      }
    } catch (e) {
      // Fail silently - analytics tracking shouldn't break the app
    }
  }

  /// Get analytics stats for admin panel
  static Future<Map<String, int>> getAnalyticsStats() async {
    try {
      final today = _getTodayString();
      final activeTodayWeb = await _getDailyCount(today, platform: 'web');
      final activeThisWeekWeb = await _getWeeklyCount(platform: 'web');
      final activeTodayMobile = await _getDailyCount(today, platform: 'mobile');
      final activeThisWeekMobile = await _getWeeklyCount(platform: 'mobile');
      final activeTodayLegacy = await _getDailyCount(today);
      final activeThisWeekLegacy = await _getWeeklyCount();

      final todayCombined = activeTodayWeb + activeTodayMobile;
      final weekCombined = activeThisWeekWeb + activeThisWeekMobile;

      // Legacy data (pre-platform tracking) only has 'count' - attribute to mobile for display
      final effectiveTodayMobile = todayCombined > 0 ? activeTodayMobile : activeTodayLegacy;
      final effectiveWeekMobile = weekCombined > 0 ? activeThisWeekMobile : activeThisWeekLegacy;
      final effectiveTodayTotal = todayCombined > 0 ? todayCombined : activeTodayLegacy;
      final effectiveWeekTotal = weekCombined > 0 ? weekCombined : activeThisWeekLegacy;

      return {
        'activeTodayWeb': activeTodayWeb,
        'activeThisWeekWeb': activeThisWeekWeb,
        'activeTodayMobile': effectiveTodayMobile,
        'activeThisWeekMobile': effectiveWeekMobile,
        'activeTodayTotal': effectiveTodayTotal,
        'activeThisWeekTotal': effectiveWeekTotal,
      };
    } catch (e) {
      return {
        'activeTodayWeb': 0,
        'activeThisWeekWeb': 0,
        'activeTodayMobile': 0,
        'activeThisWeekMobile': 0,
        'activeTodayTotal': 0,
        'activeThisWeekTotal': 0,
      };
    }
  }

  /// Get or create anonymous user ID
  static Future<String> _getOrCreateUserId() async {
    String? userId = await StorageService.getString(_userIdKey);
    if (userId == null) {
      userId = const Uuid().v4();
      await StorageService.saveString(_userIdKey, userId);
    }
    return userId;
  }

  /// Get today's date as string (YYYY-MM-DD)
  static String _getTodayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Increment daily activity counter
  static Future<void> _incrementDailyCounter(String date, {bool isWeb = false}) async {
    final docRef = _firestore.collection(_dailyActivityCollection).doc(date);
    final platformKey = isWeb ? 'web_count' : 'mobile_count';

    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);

      if (doc.exists) {
        final data = doc.data() ?? {};
        final currentCount = data['count'] ?? 0;
        final currentPlatformCount = data[platformKey] ?? 0;
        transaction.update(docRef, {
          'count': currentCount + 1,
          platformKey: currentPlatformCount + 1,
        });
      } else {
        transaction.set(docRef, {
          'count': 1,
          platformKey: 1,
        });
      }
    });
  }

  /// Get daily count for a specific date
  static Future<int> _getDailyCount(String date, {String? platform}) async {
    final doc = await _firestore.collection(_dailyActivityCollection).doc(date).get();
    if (doc.exists) {
      final data = doc.data() ?? {};
      if (platform == 'web') return data['web_count'] ?? 0;
      if (platform == 'mobile') return data['mobile_count'] ?? 0;
      // Legacy: no platform breakdown, use total count
      return data['count'] ?? 0;
    }
    return 0;
  }

  /// Get weekly count (sum of last 7 days). Pass null for legacy total count.
  static Future<int> _getWeeklyCount({String? platform}) async {
    final now = DateTime.now();
    int total = 0;

    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final dateString = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final count = await _getDailyCount(dateString, platform: platform);
      total += count;
    }

    return total;
  }

  /// Clear all analytics data (for testing/admin purposes)
  static Future<void> clearAllData() async {
    try {
      // Clear user activity data
      final userId = await _getOrCreateUserId();
      await _firestore
          .collection(_userActivityCollection)
          .doc(userId)
          .delete();
      
      // Clear today's daily activity
      final today = _getTodayString();
      await _firestore
          .collection(_dailyActivityCollection)
          .doc(today)
          .delete();
    } catch (e) {
      // Fail silently
    }
  }
} 