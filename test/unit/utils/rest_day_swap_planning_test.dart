import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/utils/rest_day_swap_planning.dart';
import 'package:spdrivercalendar/services/rest_day_swap_service.dart';

void main() {
  group('RestDaySwapPlanning', () {
    test('weekStartSunday returns the Sunday of the selected week', () {
      // Wednesday 5 Aug 2026 -> Sunday 2 Aug 2026
      expect(
        RestDaySwapPlanning.weekStartSunday(DateTime(2026, 8, 5)),
        DateTime(2026, 8, 2),
      );
      expect(
        RestDaySwapPlanning.weekStartSunday(DateTime(2026, 8, 2)),
        DateTime(2026, 8, 2),
      );
    });

    test('findSwapForDate matches work or rest side of a swap', () {
      final swap = RestDaySwap(
        workDate: DateTime(2026, 8, 3),
        restDate: DateTime(2026, 8, 4),
        shiftType: 'E',
      );

      expect(
        RestDaySwapPlanning.findSwapForDate([swap], DateTime(2026, 8, 3)),
        same(swap),
      );
      expect(
        RestDaySwapPlanning.findSwapForDate([swap], DateTime(2026, 8, 4)),
        same(swap),
      );
      expect(
        RestDaySwapPlanning.findSwapForDate([swap], DateTime(2026, 8, 5)),
        isNull,
      );
    });

    test('buildCandidates returns opposite roster days in the same week', () {
      String roster(DateTime date) {
        // Sun rest, Mon-Sat work letters
        if (date.weekday % 7 == 0) return 'R';
        return 'E';
      }

      final monday = DateTime(2026, 8, 3);
      final fromWork = RestDaySwapPlanning.buildCandidates(
        selected: monday,
        isWorkDay: true,
        existingSwaps: const [],
        rosterShiftForDate: roster,
      );
      expect(fromWork, [DateTime(2026, 8, 2)]);

      final sunday = DateTime(2026, 8, 2);
      final fromRest = RestDaySwapPlanning.buildCandidates(
        selected: sunday,
        isWorkDay: false,
        existingSwaps: const [],
        rosterShiftForDate: roster,
      );
      expect(fromRest.length, 6);
      expect(fromRest.contains(DateTime(2026, 8, 2)), isFalse);
    });

    test('buildCandidates skips days already in a swap', () {
      final existing = [
        RestDaySwap(
          workDate: DateTime(2026, 8, 3),
          restDate: DateTime(2026, 8, 2),
          shiftType: 'E',
        ),
      ];

      final candidates = RestDaySwapPlanning.buildCandidates(
        selected: DateTime(2026, 8, 4),
        isWorkDay: true,
        existingSwaps: existing,
        rosterShiftForDate: (date) => date.weekday % 7 == 0 ? 'R' : 'E',
      );

      expect(candidates, isEmpty);
    });

    test('resolvePair assigns work and rest dates from selection side', () {
      final selected = DateTime(2026, 8, 3);
      final picked = DateTime(2026, 8, 2);

      final fromWork = RestDaySwapPlanning.resolvePair(
        selected: selected,
        picked: picked,
        isWorkDay: true,
      );
      expect(fromWork.workDate, selected);
      expect(fromWork.restDate, picked);

      final fromRest = RestDaySwapPlanning.resolvePair(
        selected: picked,
        picked: selected,
        isWorkDay: false,
      );
      expect(fromRest.workDate, selected);
      expect(fromRest.restDate, picked);
    });
  });
}
