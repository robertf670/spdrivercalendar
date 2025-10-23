import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spdrivercalendar/core/services/cache_service.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  static SharedPreferences? _prefs;
  static final CacheService _cache = CacheService();
  static const Duration _cacheDuration = Duration(minutes: 5);
  
  // Enhanced error logging
  static void _logError(String operation, dynamic error, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('StorageService Error [$operation]: $error');
      if (stackTrace != null) {
        print('Stack trace: $stackTrace');
      }
    }
  }
  
  // Initialize the storage service
  static Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      _logError('init', e);
      rethrow;
    }
  }
  
  // Get SharedPreferences instance
  static Future<SharedPreferences> get prefs async {
    if (_prefs == null) {
      await init();
    }
    return _prefs!;
  }
  
  // Save a string value with validation
  static Future<void> saveString(String key, String value) async {
    try {
      final p = await prefs;
      final success = await p.setString(key, value);
      
      if (!success) {
        _logError('saveString', 'SharedPreferences.setString returned false for key $key');
        throw Exception('Failed to save string to SharedPreferences for key $key');
      }
      
      // Force commit to disk (ensures data is persisted even if app is force stopped)
      await p.reload();
      
      // Validate save by reading back
      final savedValue = p.getString(key);
      if (savedValue != value) {
        _logError('saveString', 'Validation failed: saved value does not match input for key $key');
        throw Exception('Save validation failed for key $key');
      }
      
      // Only cache after successful validation
      _cache.set(key, value, expiration: _cacheDuration);
    } catch (e) {
      _logError('saveString', 'Failed to save string for key $key: $e');
      rethrow;
    }
  }
  
  // Get a string value with cache validation
  static Future<String?> getString(String key) async {
    try {
      // Try cache first
      final cached = _cache.get<String>(key);
      if (cached != null) return cached;
      
      final p = await prefs;
      final value = p.getString(key);
      if (value != null) {
        _cache.set(key, value, expiration: _cacheDuration);
      }
      return value;
    } catch (e) {
      _logError('getString', 'Failed to get string for key $key: $e');
      return null;
    }
  }
  
  // Save a boolean value
  static Future<void> saveBool(String key, bool value) async {
    try {
      final p = await prefs;
      await p.setBool(key, value);
      _cache.set(key, value, expiration: _cacheDuration);
    } catch (e) {
      _logError('saveBool', 'Failed to save bool for key $key: $e');
      rethrow;
    }
  }
  
  // Get a boolean value
  static Future<bool> getBool(String key, {bool defaultValue = false}) async {
    try {
      // Try cache first
      final cached = _cache.get<bool>(key);
      if (cached != null) return cached;
      
      final p = await prefs;
      final value = p.getBool(key) ?? defaultValue;
      _cache.set(key, value, expiration: _cacheDuration);
      return value;
    } catch (e) {
      _logError('getBool', 'Failed to get bool for key $key: $e');
      return defaultValue;
    }
  }
  
  // Save an integer value
  static Future<void> saveInt(String key, int value) async {
    try {
      final p = await prefs;
      await p.setInt(key, value);
      _cache.set(key, value, expiration: _cacheDuration);
    } catch (e) {
      _logError('saveInt', 'Failed to save int for key $key: $e');
      rethrow;
    }
  }
  
  // Get an integer value
  static Future<int> getInt(String key, {int defaultValue = 0}) async {
    try {
      // Try cache first
      final cached = _cache.get<int>(key);
      if (cached != null) return cached;
      
      final p = await prefs;
      final value = p.getInt(key) ?? defaultValue;
      _cache.set(key, value, expiration: _cacheDuration);
      return value;
    } catch (e) {
      _logError('getInt', 'Failed to get int for key $key: $e');
      return defaultValue;
    }
  }
  
  // Save a JSON object with validation
  static Future<void> saveObject(String key, Map<String, dynamic> value) async {
    try {
      final p = await prefs;
      final jsonString = jsonEncode(value);
      await p.setString(key, jsonString);
      _cache.set(key, value, expiration: _cacheDuration);
      
      // Validate JSON was saved correctly
      final savedJson = p.getString(key);
      if (savedJson != jsonString) {
        _logError('saveObject', 'JSON validation failed for key $key');
      }
    } catch (e) {
      _logError('saveObject', 'Failed to save object for key $key: $e');
      rethrow;
    }
  }
  
  // Get a JSON object with validation
  static Future<Map<String, dynamic>?> getObject(String key) async {
    try {
      // Try cache first
      final cached = _cache.get<Map<String, dynamic>>(key);
      if (cached != null) return cached;
      
      final p = await prefs;
      final value = p.getString(key);
      if (value == null) return null;
      
      final decoded = jsonDecode(value) as Map<String, dynamic>;
      _cache.set(key, decoded, expiration: _cacheDuration);
      return decoded;
    } catch (e) {
      _logError('getObject', 'Failed to get/decode object for key $key: $e');
      return null;
    }
  }
  
  // Remove a value with cache cleanup
  static Future<void> remove(String key) async {
    try {
      final p = await prefs;
      await p.remove(key);
      _cache.remove(key);
    } catch (e) {
      _logError('remove', 'Failed to remove key $key: $e');
      rethrow;
    }
  }
  
  // Clear all data with cache cleanup
  static Future<void> clear() async {
    try {
      final p = await prefs;
      await p.clear();
      _cache.clear();
    } catch (e) {
      _logError('clear', 'Failed to clear storage: $e');
      rethrow;
    }
  }

  // Clear only the cache (not the stored data) - useful for forcing a fresh read
  static void clearCache() {
    _cache.clear();
  }

  // Clear cache for a specific key - useful when you know data has changed
  static void clearCacheForKey(String key) {
    _cache.remove(key);
  }

  // Batch save multiple values with validation
  static Future<void> batchSave(Map<String, dynamic> values) async {
    try {
      final p = await prefs;
      
      for (var entry in values.entries) {
        final key = entry.key;
        final value = entry.value;
        
        if (value is String) {
          await p.setString(key, value);
        } else if (value is bool) {
          await p.setBool(key, value);
        } else if (value is int) {
          await p.setInt(key, value);
        } else if (value is Map<String, dynamic>) {
          await p.setString(key, jsonEncode(value));
        }
        
        // Update cache
        _cache.set(key, value, expiration: _cacheDuration);
      }
    } catch (e) {
      _logError('batchSave', 'Failed to batch save: $e');
      rethrow;
    }
  }
}
