import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

/// Web: small JPEGs stored as base64 under prefs keys (local-only; backup JSON does not include binary).
class NoteAttachmentStore {
  static String _key(String eventId, String fileName) => 'note_att_${eventId}_$fileName';

  static Future<void> deleteAllForEvent(String eventId) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('note_att_${eventId}_')).toList();
    for (final k in keys) {
      await prefs.remove(k);
    }
  }

  static Future<Uint8List?> readFile(String eventId, String fileName) async {
    final prefs = await SharedPreferences.getInstance();
    final b64 = prefs.getString(_key(eventId, fileName));
    if (b64 == null || b64.isEmpty) return null;
    try {
      return base64Decode(b64);
    } catch (_) {
      return null;
    }
  }

  static Future<String> saveJpeg(String eventId, Uint8List bytes, int slotIndex) async {
    final name = '$slotIndex.jpg';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(eventId, name), base64Encode(bytes));
    return name;
  }

  static Future<void> deleteFile(String eventId, String fileName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(eventId, fileName));
  }
}
