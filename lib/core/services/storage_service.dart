import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spdrivercalendar/core/services/cache_service.dart';

class StorageService {
  static SharedPreferences? _prefs;
  static final CacheService _cache = CacheService();
  static const Duration _cacheDuration = Duration(minutes: 5);
  
  // Initialize the storage service
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  // Get SharedPreferences instance
  static Future<SharedPreferences> get prefs async {
    if (_prefs == null) {
      await init();
    }
    return _prefs!;
  }
  
  // Save a string value
  static Future<void> saveString(String key, String value) async {
    final p = await prefs;
    await p.setString(key, value);
    _cache.set(key, value, expiration: _cacheDuration);
  }
  
  // Get a string value
  static Future<String?> getString(String key) async {
    // Try cache first
    final cached = _cache.get<String>(key);
    if (cached != null) return cached;
    
    final p = await prefs;
    final value = p.getString(key);
    if (value != null) {
      _cache.set(key, value, expiration: _cacheDuration);
    }
    return value;
  }
  
  // Save a boolean value
  static Future<void> saveBool(String key, bool value) async {
    final p = await prefs;
    await p.setBool(key, value);
    _cache.set(key, value, expiration: _cacheDuration);
  }
  
  // Get a boolean value
  static Future<bool> getBool(String key, {bool defaultValue = false}) async {
    // Try cache first
    final cached = _cache.get<bool>(key);
    if (cached != null) return cached;
    
    final p = await prefs;
    final value = p.getBool(key) ?? defaultValue;
    _cache.set(key, value, expiration: _cacheDuration);
    return value;
  }
  
  // Save an integer value
  static Future<void> saveInt(String key, int value) async {
    final p = await prefs;
    await p.setInt(key, value);
    _cache.set(key, value, expiration: _cacheDuration);
  }
  
  // Get an integer value
  static Future<int> getInt(String key, {int defaultValue = 0}) async {
    // Try cache first
    final cached = _cache.get<int>(key);
    if (cached != null) return cached;
    
    final p = await prefs;
    final value = p.getInt(key) ?? defaultValue;
    _cache.set(key, value, expiration: _cacheDuration);
    return value;
  }
  
  // Save a JSON object
  static Future<void> saveObject(String key, Map<String, dynamic> value) async {
    final p = await prefs;
    final jsonString = jsonEncode(value);
    await p.setString(key, jsonString);
    _cache.set(key, value, expiration: _cacheDuration);
  }
  
  // Get a JSON object
  static Future<Map<String, dynamic>?> getObject(String key) async {
    // Try cache first
    final cached = _cache.get<Map<String, dynamic>>(key);
    if (cached != null) return cached;
    
    final p = await prefs;
    final value = p.getString(key);
    if (value == null) return null;
    
    try {
      final decoded = jsonDecode(value) as Map<String, dynamic>;
      _cache.set(key, decoded, expiration: _cacheDuration);
      return decoded;
    } catch (e) {

      return null;
    }
  }
  
  // Remove a value
  static Future<void> remove(String key) async {
    final p = await prefs;
    await p.remove(key);
    _cache.remove(key);
  }
  
  // Clear all data
  static Future<void> clear() async {
    final p = await prefs;
    await p.clear();
    _cache.clear();
  }

  // Batch save multiple values
  static Future<void> batchSave(Map<String, dynamic> values) async {
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
  }
}
