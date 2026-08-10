import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:spdrivercalendar/services/note_attachment_service.dart';

/// Uploads / deletes images attached to live updates (Firebase Storage).
class LiveUpdateImageService {
  LiveUpdateImageService._();

  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static const String _folder = 'live_updates';

  /// Compresses [bytes] and uploads to `live_updates/{updateId}.jpg`.
  /// Returns the download URL.
  static Future<String> uploadImage({
    required String updateId,
    required Uint8List bytes,
  }) async {
    // Keep JPEG encode off the UI isolate — large photos can ANR otherwise.
    final jpeg = await compute(NoteAttachmentService.compressToJpeg, bytes);
    final ref = _storage.ref('$_folder/$updateId.jpg');
    await ref.putData(
      jpeg,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return ref.getDownloadURL();
  }

  /// Best-effort delete of the image for [updateId] (and optional [imageUrl]).
  /// Missing objects are treated as already deleted (no error noise).
  static Future<void> deleteImage({
    required String updateId,
    String? imageUrl,
  }) async {
    try {
      if (imageUrl != null && imageUrl.isNotEmpty) {
        await _storage.refFromURL(imageUrl).delete();
      } else {
        await _storage.ref('$_folder/$updateId.jpg').delete();
      }
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') return;
      debugPrint('LiveUpdateImageService.deleteImage failed: $e');
    } catch (e) {
      debugPrint('LiveUpdateImageService.deleteImage failed: $e');
    }
  }
}
