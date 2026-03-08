import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for a toilet code entry
class ToiletCodeEntry {
  final String id;
  final String locationName;
  final Map<String, String> codes;
  final String? instruction;

  ToiletCodeEntry({
    required this.id,
    required this.locationName,
    required this.codes,
    this.instruction,
  });

  Map<String, dynamic> toFirestore() {
    final map = <String, dynamic>{
      'locationName': locationName,
      'codes': codes,
    };
    if (instruction != null) map['instruction'] = instruction;
    return map;
  }

  factory ToiletCodeEntry.fromFirestore(String docId, Map<String, dynamic> data) =>
      ToiletCodeEntry(
        id: docId,
        locationName: data['locationName'] as String? ?? '',
        codes: (data['codes'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k.toString(), v.toString())),
        instruction: data['instruction'] as String?,
      );

  ToiletCodeEntry copyWith({
    String? id,
    String? locationName,
    Map<String, String>? codes,
    String? instruction,
    bool clearInstruction = false,
  }) =>
      ToiletCodeEntry(
        id: id ?? this.id,
        locationName: locationName ?? this.locationName,
        codes: codes ?? Map.from(this.codes),
        instruction: clearInstruction ? null : (instruction ?? this.instruction),
      );
}

class ToiletCodesService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'toilet_codes';

  static List<ToiletCodeEntry> get _defaultEntries => [
        ToiletCodeEntry(
            id: '', locationName: 'Adamstown', codes: {'Code': '1570X'}),
        ToiletCodeEntry(
            id: '', locationName: 'Charlestown S.C.', codes: {'Code': '2512'}),
        ToiletCodeEntry(
          id: '',
          locationName: 'Grange Castle',
          codes: {'1st door': '6275', '2nd door': '5441'},
        ),
        ToiletCodeEntry(
            id: '', locationName: 'Hansfield', codes: {'Code': '1973'}),
        ToiletCodeEntry(
            id: '', locationName: 'Hazelhatch', codes: {'Code': 'C468OZ'}),
        ToiletCodeEntry(
          id: '',
          locationName: 'Heuston Station',
          codes: {'Gents': 'C1678Y', 'Ladies': '4570X'},
        ),
        ToiletCodeEntry(
            id: '', locationName: 'Maynooth', codes: {'Code': '7913'}),
        ToiletCodeEntry(
            id: '', locationName: 'Earl Place', codes: {'Code': '1964'}),
        ToiletCodeEntry(
          id: '',
          locationName: 'Damastown',
          codes: {'Code': '2+4 together then 3'},
          instruction: 'Turn handle to the right',
        ),
      ];

  /// Real-time stream of toilet codes from Firestore
  static Stream<List<ToiletCodeEntry>> getEntriesStream() {
    return _firestore
        .collection(_collection)
        .orderBy('locationName')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ToiletCodeEntry.fromFirestore(doc.id, doc.data());
      }).toList();
    });
  }

  /// One-time fetch (for when stream isn't used)
  static Future<List<ToiletCodeEntry>> loadEntries() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .orderBy('locationName')
          .get();
      if (snapshot.docs.isEmpty) return _defaultEntries;
      return snapshot.docs
          .map((doc) => ToiletCodeEntry.fromFirestore(doc.id, doc.data()))
          .toList();
    } catch (e) {
      return _defaultEntries;
    }
  }

  /// Add a new entry
  static Future<String> addEntry(ToiletCodeEntry entry) async {
    final docRef =
        await _firestore.collection(_collection).add(entry.toFirestore());
    return docRef.id;
  }

  /// Update an existing entry (full replace - ensures removed labels/codes are gone)
  static Future<void> updateEntry(ToiletCodeEntry entry) async {
    if (entry.id.isEmpty) {
      throw ArgumentError('Cannot update entry with empty id');
    }
    await _firestore
        .collection(_collection)
        .doc(entry.id)
        .set(entry.toFirestore());
  }

  /// Delete an entry
  static Future<void> deleteEntry(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  /// Seed Firestore with default entries (call when collection is empty)
  static Future<void> seedDefaults() async {
    final snapshot = await _firestore.collection(_collection).limit(1).get();
    if (snapshot.docs.isNotEmpty) return; // Already has data

    final batch = _firestore.batch();
    for (final entry in _defaultEntries) {
      final docRef = _firestore.collection(_collection).doc();
      batch.set(docRef, entry.toFirestore());
    }
    await batch.commit();
  }
}
