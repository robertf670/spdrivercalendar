import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/utils/spare_shift_duties.dart';
import 'package:spdrivercalendar/models/event.dart';

void main() {
  Event buildEvent({
    required String title,
    List<String>? assignedDuties,
  }) {
    final day = DateTime(2026, 8, 4);
    return Event(
      id: 'event-1',
      title: title,
      startDate: day,
      startTime: const TimeOfDay(hour: 8, minute: 0),
      endDate: day,
      endTime: const TimeOfDay(hour: 16, minute: 0),
      assignedDuties: assignedDuties,
    );
  }

  group('SpareShiftDuties.hasFullDuties', () {
    test('returns false for non-spare titles', () {
      expect(
        SpareShiftDuties.hasFullDuties(
          buildEvent(title: 'PZ1/03', assignedDuties: ['PZ1/03']),
        ),
        isFalse,
      );
    });

    test('returns false for spare shifts without assigned duties', () {
      expect(
        SpareShiftDuties.hasFullDuties(buildEvent(title: 'SP1')),
        isFalse,
      );
      expect(
        SpareShiftDuties.hasFullDuties(
          buildEvent(title: 'SP1', assignedDuties: const []),
        ),
        isFalse,
      );
    });

    test('returns false when every assigned duty is a half duty', () {
      expect(
        SpareShiftDuties.hasFullDuties(
          buildEvent(
            title: 'SP1',
            assignedDuties: const ['PZ1/03A', 'UNI:807/06B'],
          ),
        ),
        isFalse,
      );
    });

    test('returns true when any assigned duty is a full duty', () {
      expect(
        SpareShiftDuties.hasFullDuties(
          buildEvent(
            title: 'SP1',
            assignedDuties: const ['PZ1/03A', 'PZ1/04'],
          ),
        ),
        isTrue,
      );
      expect(
        SpareShiftDuties.hasFullDuties(
          buildEvent(
            title: 'SP2',
            assignedDuties: const ['UNI:807/06'],
          ),
        ),
        isTrue,
      );
    });

    test('treats 22B/01 like spare for full-duty detection', () {
      expect(
        SpareShiftDuties.hasFullDuties(
          buildEvent(
            title: '22B/01',
            assignedDuties: const ['4/07'],
          ),
        ),
        isTrue,
      );
    });
  });
}
