import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spdrivercalendar/core/services/storage_service.dart';
import 'package:spdrivercalendar/features/calendar/utils/zone2_shift_roster.dart';
import 'package:spdrivercalendar/models/event.dart';
import 'package:spdrivercalendar/services/zone2_roster_feature_service.dart';

Event _event({String? rosterFillSource}) {
  return Event(
    id: 'e1',
    title: 'PZ2/33',
    startDate: DateTime(2026, 10, 13),
    endDate: DateTime(2026, 10, 13),
    startTime: const TimeOfDay(hour: 19, minute: 12),
    endTime: const TimeOfDay(hour: 0, minute: 45),
    rosterFillSource: rosterFillSource,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.clear();
  });

  test('toggle defaults off and persists', () async {
    expect(await Zone2RosterFeatureService.isEnabled(), isFalse);
    await Zone2RosterFeatureService.setEnabled(true);
    expect(await Zone2RosterFeatureService.isEnabled(), isTrue);
  });

  test('filledEvents keeps only tagged Zone 2 roster fills', () {
    final tagged = _event(rosterFillSource: Zone2ShiftRoster.sourceTag);
    final other = _event();
    expect(Zone2RosterFeatureService.isFillEvent(tagged), isTrue);
    expect(Zone2RosterFeatureService.isFillEvent(other), isFalse);
    expect(
      Zone2RosterFeatureService.filledEvents([tagged, other]),
      [tagged],
    );
  });
}
