import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/utils/sick_day_display.dart';

void main() {
  group('SickDayDisplay.typeLabel', () {
    test('returns the known calendar labels', () {
      expect(SickDayDisplay.typeLabel('normal'), 'Normal Sick Day');
      expect(
        SickDayDisplay.typeLabel('self-certified'),
        'Self-Certified Sick Day',
      );
      expect(SickDayDisplay.typeLabel('force-majeure'), 'Force Majeure');
    });

    test('passes through unknown values', () {
      expect(SickDayDisplay.typeLabel('custom-type'), 'custom-type');
    });
  });

  group('SickDayDisplay.displayCode', () {
    test('returns calendar codes for known types', () {
      expect(SickDayDisplay.displayCode('normal'), 'S');
      expect(SickDayDisplay.displayCode('self-certified'), 'SC');
      expect(SickDayDisplay.displayCode('force-majeure'), 'FM');
    });

    test('returns an empty string for null or unknown types', () {
      expect(SickDayDisplay.displayCode(null), '');
      expect(SickDayDisplay.displayCode('unknown'), '');
    });
  });
}
