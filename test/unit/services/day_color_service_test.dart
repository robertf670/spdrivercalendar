import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spdrivercalendar/core/constants/app_constants.dart';
import 'package:spdrivercalendar/services/day_color_service.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    DayColorService.invalidateCache();
  });

  test('stores, reads and clears a day colour', () async {
    final date = DateTime(2026, 9, 18);
    expect(DayColorService.colorForDate(date), isNull);

    await DayColorService.setColor(date, const Color(0xFFEC407A));
    expect(DayColorService.colorForDate(date), const Color(0xFFEC407A));
    expect(DayColorService.hasOverride(date), isTrue);

    DayColorService.invalidateCache();
    await DayColorService.load();
    expect(DayColorService.colorForDate(date), const Color(0xFFEC407A));

    await DayColorService.clearColor(date);
    expect(DayColorService.colorForDate(date), isNull);
  });

  test('normalises the stored date key to midnight', () {
    expect(
      DayColorService.dateToKey(DateTime(2026, 9, 18, 15, 30)),
      DayColorService.dateToKey(DateTime(2026, 9, 18)),
    );
  });

  test('uses the day_colors storage key', () {
    expect(AppConstants.dayColorsStorageKey, 'day_colors');
  });
}
