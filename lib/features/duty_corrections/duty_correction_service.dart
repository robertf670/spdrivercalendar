import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:spdrivercalendar/features/duty_corrections/duty_correction.dart';

/// Bill and board corrections for Zone 1, Route 13, Zone 3, and Zone 4.
/// The bundled files remain the fallback.
class DutyCorrectionService {
  DutyCorrectionService._();

  static const collection = 'duty_corrections';

  static Map<String, DutyCorrection>? _cache;

  static Future<DutyCorrection?> forDuty(
    String duty,
    String dayKey, {
    String? era,
  }) async {
    if (!DutyCorrection.supports(duty)) return null;
    final all = await _load();
    return all[DutyCorrection.documentId(duty, dayKey, era: era)];
  }

  static Future<void> save(DutyCorrection correction) async {
    if (!DutyCorrection.supports(correction.duty)) {
      throw ArgumentError('This duty cannot be corrected remotely');
    }
    final id = DutyCorrection.documentId(
      correction.duty,
      correction.dayKey,
      era: correction.era,
    );
    final ref = FirebaseFirestore.instance.collection(collection).doc(id);
    final cache = await _load();
    if (correction.isEmpty) {
      await ref.delete();
      cache.remove(id);
      return;
    }
    await ref.set({
      ...correction.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    cache[id] = correction;
  }

  static Future<void> refresh() async {
    _cache = null;
    await _load();
  }

  static void clearCache() {
    _cache = null;
  }

  static Future<Map<String, DutyCorrection>> _load() async {
    final cached = _cache;
    if (cached != null) return cached;
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection(collection).get();
      final loaded = <String, DutyCorrection>{};
      for (final doc in snapshot.docs) {
        final correction = DutyCorrection.fromFirestore(doc.data());
        if (!DutyCorrection.supports(correction.duty)) continue;
        if (correction.dayKey.isEmpty) continue;
        loaded[DutyCorrection.documentId(
          correction.duty,
          correction.dayKey,
          era: correction.era,
        )] = correction;
      }
      _cache = loaded;
      return loaded;
    } catch (_) {
      _cache = {};
      return _cache!;
    }
  }
}
