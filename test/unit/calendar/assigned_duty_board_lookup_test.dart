import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/utils/assigned_duty_board_lookup.dart';
import 'package:spdrivercalendar/models/event.dart';
import 'package:spdrivercalendar/services/zone_board_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(ZoneBoardService.clearCache);

  group('AssignedDutyBoardLookup.lookupCode', () {
    test('keeps zone and Uni codes', () {
      expect(AssignedDutyBoardLookup.lookupCode('PZ1/03'), 'PZ1/03');
      expect(AssignedDutyBoardLookup.lookupCode('807/06'), '807/06');
      expect(AssignedDutyBoardLookup.lookupCode('811/36'), '811/36');
    });

    test('strips Uni prefix and half suffixes', () {
      expect(AssignedDutyBoardLookup.lookupCode('UNI:807/06'), '807/06');
      expect(AssignedDutyBoardLookup.lookupCode('UNI:807/06A'), '807/06');
      expect(AssignedDutyBoardLookup.lookupCode('PZ1/03B'), 'PZ1/03');
      expect(AssignedDutyBoardLookup.lookupCode('PZ1/10XA'), 'PZ1/10X');
      expect(AssignedDutyBoardLookup.lookupCode('811/36A'), '811/36');
    });

    test('prefixes bare zone codes used on 22B/spare', () {
      expect(AssignedDutyBoardLookup.lookupCode('4/07'), 'PZ4/07');
      expect(AssignedDutyBoardLookup.lookupCode('1/03A'), 'PZ1/03');
    });
  });

  group('AssignedDutyBoardLookup.load', () {
    test('loads a zone board from a spare half-duty code', () async {
      final board = await AssignedDutyBoardLookup.load(
        assignedDuty: 'PZ1/01A',
        date: DateTime(2026, 8, 10),
      );
      expect(board, isNotNull);
      expect(board!.shift, 'PZ1/01');
      expect(board.sections, isNotEmpty);
    });

    test('loads a Uni board after stripping UNI: prefix', () async {
      final board = await AssignedDutyBoardLookup.load(
        assignedDuty: 'UNI:307/01',
        date: DateTime(2026, 8, 10),
      );
      expect(board, isNotNull);
      expect(board!.shift, '307/01');
      expect(board.sections, isNotEmpty);
    });

    test('loadForEvent uses assigned duties when the title is a spare code', () async {
      final day = DateTime(2026, 8, 10);
      final event = Event(
        id: 'spare-1',
        title: 'SP0800',
        startDate: day,
        startTime: const TimeOfDay(hour: 8, minute: 0),
        endDate: day,
        endTime: const TimeOfDay(hour: 16, minute: 0),
        assignedDuties: const ['PZ1/01A'],
      );

      final board = await AssignedDutyBoardLookup.loadForEvent(event);
      expect(board, isNotNull);
      expect(board!.shift, 'PZ1/01');
    });
  });
}
