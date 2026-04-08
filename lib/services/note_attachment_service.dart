import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import 'package:spdrivercalendar/services/note_attachments/note_attachment_store_io.dart'
    if (dart.library.html) 'package:spdrivercalendar/services/note_attachments/note_attachment_store_web.dart';

/// Local gallery images attached to a duty note (max [maxImagesPerEvent]).
class NoteAttachmentService {
  NoteAttachmentService._();

  static const int maxImagesPerEvent = 3;
  static const int maxEdgePx = 1600;
  static const int jpegQuality = 85;

  static Uint8List compressToJpeg(Uint8List input) {
    final decoded = img.decodeImage(input);
    if (decoded == null) return input;
    var work = decoded;
    final w = work.width;
    final h = work.height;
    if (w > maxEdgePx || h > maxEdgePx) {
      if (w >= h) {
        final nh = (h * maxEdgePx / w).round();
        work = img.copyResize(work, width: maxEdgePx, height: nh);
      } else {
        final nw = (w * maxEdgePx / h).round();
        work = img.copyResize(work, width: nw, height: maxEdgePx);
      }
    }
    return Uint8List.fromList(img.encodeJpg(work, quality: jpegQuality));
  }

  static Future<void> deleteAllForEvent(String eventId) {
    return NoteAttachmentStore.deleteAllForEvent(eventId);
  }

  /// Ordered filenames as stored on the event (e.g. 0.jpg, 1.jpg).
  static Future<List<String>> replaceAllImages(String eventId, List<Uint8List> images) async {
    assert(images.length <= maxImagesPerEvent);
    await NoteAttachmentStore.deleteAllForEvent(eventId);
    final out = <String>[];
    for (var i = 0; i < images.length; i++) {
      final name = await NoteAttachmentStore.saveJpeg(eventId, images[i], i);
      out.add(name);
    }
    return out;
  }

  static Future<Uint8List?> readImage(String eventId, String fileName) {
    return NoteAttachmentStore.readFile(eventId, fileName);
  }

  /// Picks a single image from gallery, compresses to JPEG. Returns null if cancelled.
  static Future<Uint8List?> pickFromGallery() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: maxEdgePx.toDouble(),
      maxHeight: maxEdgePx.toDouble(),
      imageQuality: 90,
    );
    if (x == null) return null;
    final raw = await x.readAsBytes();
    try {
      return compressToJpeg(raw);
    } catch (e, st) {
      debugPrint('NoteAttachmentService.compress failed: $e $st');
      return raw;
    }
  }
}
