import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/utils/marked_in_status.dart';

void main() {
  test('4 Day works Friday through Monday', () {
    expect(MarkedInStatus.isWorkDay('4 Day', DateTime(2026, 10, 16)), isTrue); // Fri
    expect(MarkedInStatus.isWorkDay('4 Day', DateTime(2026, 10, 17)), isTrue); // Sat
    expect(MarkedInStatus.isWorkDay('4 Day', DateTime(2026, 10, 18)), isTrue); // Sun
    expect(MarkedInStatus.isWorkDay('4 Day', DateTime(2026, 10, 19)), isTrue); // Mon
    expect(MarkedInStatus.isWorkDay('4 Day', DateTime(2026, 10, 20)), isFalse); // Tue
    expect(MarkedInStatus.isWorkDay('4 Day', DateTime(2026, 10, 21)), isFalse); // Wed
    expect(MarkedInStatus.isWorkDay('4 Day', DateTime(2026, 10, 22)), isFalse); // Thu
  });

  test('M-F still works Monday through Friday', () {
    expect(MarkedInStatus.isWorkDay('M-F', DateTime(2026, 10, 19)), isTrue); // Mon
    expect(MarkedInStatus.isWorkDay('M-F', DateTime(2026, 10, 23)), isTrue); // Fri
    expect(MarkedInStatus.isWorkDay('M-F', DateTime(2026, 10, 17)), isFalse); // Sat
    expect(MarkedInStatus.isWorkDay('M-F', DateTime(2026, 10, 18)), isFalse); // Sun
  });

  test('4 Day is spare and does not need a marked-in zone', () {
    expect(MarkedInStatus.needsZone('4 Day'), isFalse);
    expect(MarkedInStatus.isFixedWorkPattern('4 Day'), isTrue);
  });
}
