import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// File-based storage under app documents / [subDir] / [eventId] / [n].jpg
class NoteAttachmentStore {
  static const String subDir = 'note_attachments';

  static Future<String> get _documentsPath async {
    final d = await getApplicationDocumentsDirectory();
    return d.path;
  }

  static Future<void> deleteAllForEvent(String eventId) async {
    final dir = Directory(p.join(await _documentsPath, subDir, eventId));
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  static Future<Uint8List?> readFile(String eventId, String fileName) async {
    final file = File(p.join(await _documentsPath, subDir, eventId, fileName));
    if (!await file.exists()) return null;
    return file.readAsBytes();
  }

  /// Writes [bytes] to [slotIndex].jpg and returns the filename (e.g. "0.jpg").
  static Future<String> saveJpeg(String eventId, Uint8List bytes, int slotIndex) async {
    final folder = Directory(p.join(await _documentsPath, subDir, eventId));
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    final name = '$slotIndex.jpg';
    final file = File(p.join(folder.path, name));
    await file.writeAsBytes(bytes, flush: true);
    return name;
  }

  static Future<void> deleteFile(String eventId, String fileName) async {
    final file = File(p.join(await _documentsPath, subDir, eventId, fileName));
    if (await file.exists()) {
      await file.delete();
    }
  }
}
