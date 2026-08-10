import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/utils/holiday_type_presentation.dart';

void main() {
  test('maps known holiday types to labels and icons', () {
    expect(holidayTypePresentation('winter').label, 'Winter Holiday');
    expect(holidayTypePresentation('winter').icon, Icons.ac_unit);
    expect(holidayTypePresentation('summer').label, 'Summer Holiday');
    expect(holidayTypePresentation('day_in_lieu').label, 'Day In Lieu');
    expect(holidayTypePresentation('other').label, 'Holiday');
  });
}
