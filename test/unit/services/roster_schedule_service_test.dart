import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spdrivercalendar/core/services/storage_service.dart';
import 'package:spdrivercalendar/features/calendar/services/roster_schedule_service.dart';
import 'package:spdrivercalendar/features/calendar/services/roster_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.clear();
    RosterScheduleService.resetForTesting();
  });

  group('RosterScheduleService', () {
    test('uses the baseline before a dated change and the change afterwards',
        () async {
      final baselineDate = DateTime(2026, 8, 2);

      await RosterScheduleService.setChange(
        effectiveDate: DateTime(2026, 8, 16),
        startWeek: 3,
      );

      expect(
        RosterService.getShiftForDate(
          DateTime(2026, 8, 10),
          baselineDate,
          0,
        ),
        'E',
      );
      expect(
        RosterService.getShiftForDate(
          DateTime(2026, 8, 17),
          baselineDate,
          0,
        ),
        'R',
      );
    });

    test('normalizes effective dates to Sunday and persists changes', () async {
      await RosterScheduleService.setChange(
        effectiveDate: DateTime(2026, 8, 19),
        startWeek: 2,
      );

      RosterScheduleService.resetForTesting();
      await RosterScheduleService.initialize();

      expect(RosterScheduleService.changes, hasLength(1));
      expect(
        RosterScheduleService.changes.single.effectiveDate,
        DateTime(2026, 8, 16),
      );
      expect(RosterScheduleService.changes.single.startWeek, 2);
    });

    test('replaces an existing change for the same week', () async {
      await RosterScheduleService.setChange(
        effectiveDate: DateTime(2026, 8, 16),
        startWeek: 1,
      );
      await RosterScheduleService.setChange(
        effectiveDate: DateTime(2026, 8, 20),
        startWeek: 4,
      );

      expect(RosterScheduleService.changes, hasLength(1));
      expect(RosterScheduleService.changes.single.startWeek, 4);
    });
  });
}
