import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/utils/edit_event_display_title.dart';

void main() {
  test('formats BusCheck titles', () {
    expect(formatEditEventDisplayTitle('BusCheck3'), 'Bus Check 3');
  });

  test('returns Untitled Event for empty titles', () {
    expect(formatEditEventDisplayTitle(''), 'Untitled Event');
  });

  test('keeps normal duty titles unchanged', () {
    expect(formatEditEventDisplayTitle('PZ1/01'), 'PZ1/01');
    expect(formatEditEventDisplayTitle('807/20A (OT)'), '807/20A (OT)');
  });
}
