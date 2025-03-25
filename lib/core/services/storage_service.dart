import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static SharedPreferences? _prefs;
  
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
  }
  
  // Get a string value
  static Future<String?> getString(String key) async {
    final p = await prefs;
    return p.getString(key);
  }
  
  // Save a boolean value
  static Future<void> saveBool(String key, bool value) async {
    final p = await prefs;
    await p.setBool(key, value);
  }
  
  // Get a boolean value
  static Future<bool> getBool(String key, {bool defaultValue = false}) async {
    final p = await prefs;
    return p.getBool(key) ?? defaultValue;
  }
  
  // Save an integer value
  static Future<void> saveInt(String key, int value) async {
    final p = await prefs;
    await p.setInt(key, value);
  }
  
  // Get an integer value
  static Future<int> getInt(String key, {int defaultValue = 0}) async {
    final p = await prefs;
    return p.getInt(key) ?? defaultValue;
  }
  
  // Save a JSON object
  static Future<void> saveObject(String key, Map<String, dynamic> value) async {
    final p = await prefs;
    await p.setString(key, jsonEncode(value));
  }
  
  // Get a JSON object
  static Future<Map<String, dynamic>?> getObject(String key) async {
    final p = await prefs;
    final value = p.getString(key);
    if (value == null) return null;
    
    try {
      return jsonDecode(value) as Map<String, dynamic>;
    } catch (e) {
      print('Error parsing JSON from storage: $e');
      return null;
    }
  }
  
  // Remove a value
  static Future<void> remove(String key) async {
    final p = await prefs;
    await p.remove(key);
  }
  
  // Clear all data
  static Future<void> clear() async {
    final p = await prefs;
    await p.clear();
  }
}
