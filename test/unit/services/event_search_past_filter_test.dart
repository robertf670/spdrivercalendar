import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/services/event_search_service.dart';

void main() {
  final today = DateTime(2026, 10, 18, 16, 45);

  test('past filter includes today and earlier', () {
    expect(
      EventSearchService.isOnOrBeforeDay(DateTime(2026, 10, 18, 6, 0), today),
      isTrue,
    );
    expect(
      EventSearchService.isOnOrBeforeDay(DateTime(2026, 10, 17), today),
      isTrue,
    );
  });

  test('past filter excludes tomorrow', () {
    expect(
      EventSearchService.isOnOrBeforeDay(DateTime(2026, 10, 19), today),
      isFalse,
    );
  });
}
