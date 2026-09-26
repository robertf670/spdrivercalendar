import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:spdrivercalendar/features/bus_reports/bus_report_key.dart';

class BusReport {
  const BusReport({
    required this.id,
    required this.userId,
    required this.busNumber,
    required this.date,
    required this.slot,
    this.category,
    this.note = '',
    this.noteRemoved = false,
    this.updatedAt,
  });

  static const maxNoteLength = 140;

  final String id;
  final String userId;
  final String busNumber;
  final String date;
  final BusReportSlot slot;
  final BusReportCategory? category;
  final String note;
  final bool noteRemoved;
  final DateTime? updatedAt;

  bool get hasPublicNote => !noteRemoved && note.trim().isNotEmpty;

  String get categoryLabel => category?.label ?? 'Other';

  factory BusReport.fromMap(String id, Map<String, dynamic> map) {
    return BusReport(
      id: id,
      userId: map['userId'] as String? ?? '',
      busNumber: map['busNumber'] as String? ?? '',
      date: map['date'] as String? ?? '',
      slot: BusReportSlot.tryParse(map['slot'] as String?),
      category: BusReportCategory.tryParse(map['category'] as String?),
      note: map['note'] as String? ?? '',
      noteRemoved: map['noteRemoved'] == true,
      updatedAt: _asDate(map['updatedAt']),
    );
  }

  static DateTime? _asDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
