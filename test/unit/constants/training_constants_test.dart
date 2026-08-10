import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/core/constants/training_constants.dart';

void main() {
  group('TrainingConstants.resolveLocation', () {
    test('returns null when no location is selected', () {
      expect(TrainingConstants.resolveLocation(null, ''), isNull);
      expect(TrainingConstants.resolveLocation('', ''), isNull);
    });

    test('returns a selected preset location', () {
      expect(
        TrainingConstants.resolveLocation('Garage', ''),
        'Garage',
      );
    });

    test('trims and returns a custom location', () {
      expect(
        TrainingConstants.resolveLocation('Other', '  Custom location  '),
        'Custom location',
      );
    });

    test('returns null for an empty custom location', () {
      expect(
        TrainingConstants.resolveLocation('Other', '   '),
        isNull,
      );
    });
  });
}
