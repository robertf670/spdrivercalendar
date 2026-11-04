import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spdrivercalendar/core/services/storage_service.dart';
import 'package:spdrivercalendar/features/calendar/utils/zone1_shift_roster.dart';
import 'package:spdrivercalendar/models/event.dart';
import 'package:spdrivercalendar/services/zone1_roster_feature_service.dart';
import 'package:spdrivercalendar/services/zone2_roster_feature_service.dart';
import 'package:spdrivercalendar/services/zone4_roster_feature_service.dart';

Event _event({String? rosterFillSource}) {
  return Event(
    id: 'e1',
    title: 'PZ1/65',
    startDate: DateTime(2026, 11, 3),
    endDate: DateTime(2026, 11, 3),
    startTime: const TimeOfDay(hour: 5, minute: 0),
    endTime: const TimeOfDay(hour: 13, minute: 0),
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
    expect(await Zone1RosterFeatureService.isEnabled(), isFalse);
    await Zone1RosterFeatureService.setEnabled(true);
    expect(await Zone1RosterFeatureService.isEnabled(), isTrue);
  });

  test('shows for a Shift driver marked in on Zone 1', () {
    expect(
      Zone1RosterFeatureService.showsForMarkedIn(
        status: 'Shift',
        zone: 'Zone 1',
      ),
      isTrue,
    );
    expect(
      Zone1RosterFeatureService.showsForMarkedIn(
        status: 'M-F',
        zone: 'Zone 1',
      ),
      isFalse,
    );
    expect(
      Zone1RosterFeatureService.showsForMarkedIn(
        status: 'Shift',
        zone: 'Route 13',
      ),
      isFalse,
    );
  });

  test('turning one roster on turns the others off', () async {
    await Zone2RosterFeatureService.setEnabled(true);
    await Zone4RosterFeatureService.setEnabled(true);
    await Zone1RosterFeatureService.setEnabled(true);
    expect(await Zone1RosterFeatureService.isEnabled(), isTrue);
    expect(await Zone2RosterFeatureService.isEnabled(), isFalse);
    expect(await Zone4RosterFeatureService.isEnabled(), isFalse);

    await Zone2RosterFeatureService.setEnabled(true);
    expect(await Zone2RosterFeatureService.isEnabled(), isTrue);
    expect(await Zone1RosterFeatureService.isEnabled(), isFalse);

    await Zone4RosterFeatureService.setEnabled(true);
    expect(await Zone4RosterFeatureService.isEnabled(), isTrue);
    expect(await Zone1RosterFeatureService.isEnabled(), isFalse);
    expect(await Zone2RosterFeatureService.isEnabled(), isFalse);
  });

  test('filledEvents keeps only tagged Zone 1 roster fills', () {
    final tagged = _event(rosterFillSource: Zone1ShiftRoster.sourceTag);
    final other = _event();
    expect(Zone1RosterFeatureService.isFillEvent(tagged), isTrue);
    expect(Zone1RosterFeatureService.isFillEvent(other), isFalse);
    expect(
      Zone1RosterFeatureService.filledEvents([tagged, other]),
      [tagged],
    );
  });
}
