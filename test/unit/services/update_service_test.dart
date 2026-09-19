import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/services/update_service.dart';

void main() {
  test('APK updates are offered on Android only, not on web', () {
    expect(apkUpdatesEnabled(isWeb: true), isFalse);
    expect(apkUpdatesEnabled(isWeb: false), isTrue);
  });
}
