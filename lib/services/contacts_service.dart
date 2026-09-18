import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:spdrivercalendar/features/contacts/contact_models.dart';

class ContactsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String sectionsCollection = 'contact_sections';
  static const String entriesCollection = 'contacts';

  static Stream<ContactsCatalog> watchCatalog({
    bool fallbackToDefaults = true,
  }) {
    return _firestore
        .collection(sectionsCollection)
        .snapshots()
        .asyncExpand((sectionSnap) {
      return _firestore.collection(entriesCollection).snapshots().map(
        (entrySnap) {
          if (sectionSnap.docs.isEmpty && entrySnap.docs.isEmpty) {
            return fallbackToDefaults
                ? ContactsCatalog.defaults()
                : const ContactsCatalog();
          }
          return ContactsCatalog(
            sections: sectionSnap.docs
                .map((doc) => ContactSection.fromFirestore(doc.id, doc.data()))
                .toList(),
            entries: entrySnap.docs
                .map((doc) => ContactEntry.fromFirestore(doc.id, doc.data()))
                .toList(),
          );
        },
      );
    });
  }

  static Future<String> addSection(ContactSection section) async {
    final docRef =
        await _firestore.collection(sectionsCollection).add(section.toFirestore());
    return docRef.id;
  }

  static Future<void> updateSection(ContactSection section) async {
    if (section.id.isEmpty) {
      throw ArgumentError('Cannot update section with empty id');
    }
    await _firestore
        .collection(sectionsCollection)
        .doc(section.id)
        .set(section.toFirestore());
  }

  static Future<void> deleteSection(String id) async {
    final contacts = await _firestore
        .collection(entriesCollection)
        .where('sectionId', isEqualTo: id)
        .get();
    final batch = _firestore.batch();
    for (final doc in contacts.docs) {
      batch.update(doc.reference, {'sectionId': ''});
    }
    batch.delete(_firestore.collection(sectionsCollection).doc(id));
    await batch.commit();
  }

  static Future<String> addEntry(ContactEntry entry) async {
    final docRef =
        await _firestore.collection(entriesCollection).add(entry.toFirestore());
    return docRef.id;
  }

  static Future<void> updateEntry(ContactEntry entry) async {
    if (entry.id.isEmpty) {
      throw ArgumentError('Cannot update entry with empty id');
    }
    await _firestore
        .collection(entriesCollection)
        .doc(entry.id)
        .set(entry.toFirestore());
  }

  static Future<void> deleteEntry(String id) async {
    await _firestore.collection(entriesCollection).doc(id).delete();
  }

  static Future<void> seedDefaults() async {
    try {
      final existingEntries =
          await _firestore.collection(entriesCollection).limit(1).get();
      if (existingEntries.docs.isNotEmpty) return;
      final existingSections =
          await _firestore.collection(sectionsCollection).limit(1).get();
      if (existingSections.docs.isNotEmpty) return;

      final catalog = ContactsCatalog.defaults();
      final batch = _firestore.batch();
      for (final section in catalog.sections) {
        batch.set(
          _firestore.collection(sectionsCollection).doc(section.id),
          section.toFirestore(),
        );
      }
      for (final entry in catalog.entries) {
        batch.set(
          _firestore.collection(entriesCollection).doc(entry.id),
          entry.toFirestore(),
        );
      }
      await batch.commit();
    } catch (_) {}
  }
}
