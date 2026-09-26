import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:spdrivercalendar/core/constants/app_constants.dart';
import 'package:spdrivercalendar/core/services/storage_service.dart';
import 'package:spdrivercalendar/features/bus_reports/bus_report.dart';
import 'package:spdrivercalendar/features/bus_reports/bus_report_aggregate.dart';
import 'package:spdrivercalendar/features/bus_reports/bus_report_key.dart';

class BusReportService {
  BusReportService._();

  static const reportsCollection = 'bus_defect_reports';
  static const summariesCollection = 'bus_defect_summaries';
  static const _userIdKey = 'anonymous_user_id';

  static FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get _reports =>
      _firestore.collection(reportsCollection);

  static CollectionReference<Map<String, dynamic>> get _summaries =>
      _firestore.collection(summariesCollection);

  static bool get isAvailable => Firebase.apps.isNotEmpty;

  static Future<bool> isEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(AppConstants.busDefectReportsEnabledKey) ?? true;
    } catch (_) {
      return true;
    }
  }

  static Future<String> userId() async {
    String? id = await StorageService.getString(_userIdKey);
    if (id == null || id.isEmpty) {
      id = const Uuid().v4();
      await StorageService.saveString(_userIdKey, id);
    }
    return id;
  }

  static Future<BusReport?> getOwnReport(BusReportTarget target) async {
    if (!isAvailable) return null;
    try {
      final id = await userId();
      final snap = await _reports.doc(target.reportDocId(id)).get();
      if (!snap.exists || snap.data() == null) return null;
      return BusReport.fromMap(snap.id, snap.data()!);
    } catch (_) {
      return null;
    }
  }

  static Future<BusReportSummaryData?> getSummary(String busNumber) async {
    final target = BusReportKey.targetFor(
      rawBusNumber: busNumber,
      date: DateTime.now(),
      slot: BusReportSlot.full,
    );
    if (target == null || !isAvailable) return null;
    try {
      final snap = await _summaries.doc(target.summaryId).get();
      if (!snap.exists || snap.data() == null) return null;
      return BusReportSummaryData.fromMap(snap.data()!);
    } catch (_) {
      return null;
    }
  }

  static Future<List<BusReport>> fetchReportsForBus(String busNumber) async {
    final target = BusReportKey.targetFor(
      rawBusNumber: busNumber,
      date: DateTime.now(),
      slot: BusReportSlot.full,
    );
    if (target == null || !isAvailable) return const [];
    try {
      final snap =
          await _reports.where('busNumber', isEqualTo: target.busNumber).get();
      final reports = snap.docs
          .map((doc) => BusReport.fromMap(doc.id, doc.data()))
          .toList();
      reports.sort((a, b) {
        final aTime = a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      return reports;
    } catch (_) {
      return const [];
    }
  }

  static Future<List<BusReport>> fetchRecentPublicNotes() async {
    if (!isAvailable) return const [];
    try {
      final snap = await _reports.where('hasPublicNote', isEqualTo: true).get();
      final notes = snap.docs
          .map((doc) => BusReport.fromMap(doc.id, doc.data()))
          .where((report) => report.hasPublicNote)
          .toList();
      notes.sort((a, b) {
        final aTime = a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      return notes;
    } catch (_) {
      return const [];
    }
  }

  static Stream<List<BusReport>> watchPublicNotes() {
    if (!isAvailable) return Stream.value(const []);
    return _reports.where('hasPublicNote', isEqualTo: true).snapshots().map((
      snap,
    ) {
      final notes = snap.docs
          .map((doc) => BusReport.fromMap(doc.id, doc.data()))
          .where((report) => report.hasPublicNote)
          .toList();
      notes.sort((a, b) {
        final aTime = a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      return notes;
    });
  }

  static Future<List<BusReport>> fetchAllReports() async {
    if (!isAvailable) return const [];
    try {
      final snap = await _reports.get();
      return snap.docs
          .map((doc) => BusReport.fromMap(doc.id, doc.data()))
          .where((report) => report.busNumber.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<List<BusReportSummaryData>> fetchSummaries() async {
    if (!isAvailable) return const [];
    try {
      final snap = await _summaries.get();
      return snap.docs
          .map((doc) => BusReportSummaryData.fromMap(doc.data()))
          .where((row) => row.busNumber.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<BusReport> saveReport({
    required BusReportTarget target,
    BusReportCategory? category,
    required String note,
  }) async {
    final trimmed = note.trim();
    if (trimmed.length > BusReport.maxNoteLength) {
      throw ArgumentError(
        'Note must be ${BusReport.maxNoteLength} characters or fewer',
      );
    }
    if (!BusReportKey.canSave(category: category, note: trimmed)) {
      throw ArgumentError('Choose a category or write a short note');
    }

    final id = await userId();
    final reportRef = _reports.doc(target.reportDocId(id));
    final summaryRef = _summaries.doc(target.summaryId);
    final categoryName = category?.label ?? BusReportCategory.other.label;

    return _firestore.runTransaction((transaction) async {
      final reportSnap = await transaction.get(reportRef);
      final summarySnap = await transaction.get(summaryRef);
      final existing = reportSnap.exists && reportSnap.data() != null
          ? BusReport.fromMap(reportSnap.id, reportSnap.data()!)
          : null;

      var summary = summarySnap.exists && summarySnap.data() != null
          ? BusReportSummaryData.fromMap(summarySnap.data()!)
          : BusReportSummaryData(busNumber: target.busNumber);

      final reportedAt = DateTime.now();
      summary = summary.applyReport(
        oldCategory: existing?.categoryLabel,
        newCategory: categoryName,
        reportedAt: reportedAt,
      );

      final hasNote = trimmed.isNotEmpty;
      final noteRemoved = existing?.noteRemoved == true && !hasNote;
      final now = FieldValue.serverTimestamp();

      transaction.set(reportRef, {
        'userId': id,
        'busNumber': target.busNumber,
        'date': target.date,
        'slot': target.slot.id,
        'category': categoryName,
        'note': trimmed,
        'noteRemoved': noteRemoved,
        'hasPublicNote': hasNote && !noteRemoved,
        if (existing == null) 'createdAt': now,
        'updatedAt': now,
      }, SetOptions(merge: true));

      transaction.set(summaryRef, {
        ...summary.toMap(),
        'lastReportedAt': now,
        'updatedAt': now,
      }, SetOptions(merge: true));

      return BusReport(
        id: reportRef.id,
        userId: id,
        busNumber: target.busNumber,
        date: target.date,
        slot: target.slot,
        category: BusReportCategory.tryParse(categoryName),
        note: trimmed,
        noteRemoved: noteRemoved,
        updatedAt: reportedAt,
      );
    });
  }

  static Future<void> deleteOwnReport(BusReportTarget target) async {
    final id = await userId();
    await _deleteReportRef(
      reportRef: _reports.doc(target.reportDocId(id)),
      summaryRef: _summaries.doc(target.summaryId),
    );
  }

  static Future<void> removeNote(String reportId) async {
    await _reports.doc(reportId).update({
      'note': '',
      'noteRemoved': true,
      'hasPublicNote': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteReport(BusReport report) async {
    final target = BusReportTarget(
      busNumber: report.busNumber,
      date: report.date,
      slot: report.slot,
    );
    await _deleteReportRef(
      reportRef: _reports.doc(report.id),
      summaryRef: _summaries.doc(target.summaryId),
    );
  }

  static Future<void> _deleteReportRef({
    required DocumentReference<Map<String, dynamic>> reportRef,
    required DocumentReference<Map<String, dynamic>> summaryRef,
  }) async {
    await _firestore.runTransaction((transaction) async {
      final reportSnap = await transaction.get(reportRef);
      final summarySnap = await transaction.get(summaryRef);
      if (!reportSnap.exists || reportSnap.data() == null) return;

      final current = BusReport.fromMap(reportSnap.id, reportSnap.data()!);
      transaction.delete(reportRef);

      if (!summarySnap.exists || summarySnap.data() == null) return;
      final next = BusReportSummaryData.fromMap(
        summarySnap.data()!,
      ).removeReport(current.categoryLabel);
      if (next.reportCount <= 0) {
        transaction.delete(summaryRef);
      } else {
        transaction.set(summaryRef, {
          ...next.toMap(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    });
  }

}
