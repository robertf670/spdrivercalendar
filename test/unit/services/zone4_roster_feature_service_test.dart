import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spdrivercalendar/core/services/storage_service.dart';
import 'package:spdrivercalendar/services/zone2_roster_feature_service.dart';
import 'package:spdrivercalendar/services/zone4_roster_feature_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.clear();
  });

  test('turning Zone 4 on turns Route 13 off', () async {
    await Zone2RosterFeatureService.setEnabled(true);
    await Zone4RosterFeatureService.setEnabled(true);
    expect(await Zone4RosterFeatureService.isEnabled(), isTrue);
    expect(await Zone2RosterFeatureService.isEnabled(), isFalse);

    await Zone2RosterFeatureService.setEnabled(true);
    expect(await Zone2RosterFeatureService.isEnabled(), isTrue);
    expect(await Zone4RosterFeatureService.isEnabled(), isFalse);
  });

  test('toggle defaults off and persists', () async {
    expect(await Zone4RosterFeatureService.isEnabled(), isFalse);
    await Zone4RosterFeatureService.setEnabled(true);
    expect(await Zone4RosterFeatureService.isEnabled(), isTrue);
  });

  test('shows for a Shift driver marked in on Zone 4', () {
    expect(
      Zone4RosterFeatureService.showsForMarkedIn(
        status: 'Shift',
        zone: 'Zone 4',
      ),
      isTrue,
    );
    expect(
      Zone4RosterFeatureService.showsForMarkedIn(
        status: 'M-F',
        zone: 'Zone 4',
      ),
      isFalse,
    );
    expect(
      Zone4RosterFeatureService.showsForMarkedIn(
        status: 'Shift',
        zone: 'Route 13',
      ),
      isFalse,
    );
  });
}
