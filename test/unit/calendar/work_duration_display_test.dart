import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/utils/work_duration_display.dart';

void main() {
  group('formatWorkDurationForDisplay', () {
    test('strips leading zeros from CSV duration', () {
      expect(formatWorkDurationForDisplay('06:40:00'), '6h 40m');
      expect(formatWorkDurationForDisplay('08:18:00'), '8h 18m');
    });

    test('strips leading zeros from UNI-style labels', () {
      expect(formatWorkDurationForDisplay('06h 40m'), '6h 40m');
      expect(formatWorkDurationForDisplay('07h 05m'), '7h 5m');
    });

    test('leaves already-unpadded labels unchanged', () {
      expect(formatWorkDurationForDisplay('6h 40m'), '6h 40m');
    });

    test('returns null for empty or nan values', () {
      expect(formatWorkDurationForDisplay(null), isNull);
      expect(formatWorkDurationForDisplay(''), isNull);
      expect(formatWorkDurationForDisplay('nan'), isNull);
    });
  });
}
