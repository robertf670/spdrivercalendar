import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/services/user_preferences_service.dart';

void main() {
  test('live update routes are the depot routes only', () {
    expect(UserPreferencesService.availableRoutes, [
      'C1',
      'C2',
      'L58',
      'L59',
      '13',
      '23',
      '24',
      '39',
      '39A',
    ]);
  });

  test('sanitizePreferredRoutes drops routes that are not at this depot', () {
    expect(
      UserPreferencesService.sanitizePreferredRoutes(['39A', 'N4', '122', '13']),
      ['13', '39A'],
    );
  });

  test('sanitizePreferredRoutes falls back to depot defaults when none remain', () {
    expect(
      UserPreferencesService.sanitizePreferredRoutes(['N1', 'L51']),
      UserPreferencesService.availableRoutes,
    );
  });
}
