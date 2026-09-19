import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/core/startup/app_startup.dart';

void main() {
  test('heavy startup is deferred on web only', () {
    expect(AppStartup.deferHeavyInit(isWeb: true), isTrue);
    expect(AppStartup.deferHeavyInit(isWeb: false), isFalse);
  });

  test('web index shows a splash until Flutter paints', () {
    final html = File('web/index.html').readAsStringSync();
    expect(html, contains('id="app-loading"'));
    expect(html, contains('apple-touch-startup-image'));
    expect(html, contains('flutter-first-frame'));
  });

  test('web bootstrap does not wait long for the service worker', () {
    final js = File('web/flutter_bootstrap.js').readAsStringSync();
    expect(js, contains('timeoutMillis: 1'));
    expect(js, contains('_flutter.loader.load'));
  });

  test('iOS startup images referenced by index.html exist', () {
    final html = File('web/index.html').readAsStringSync();
    final hrefs = RegExp(r'href="(splash/apple-splash-\d+-\d+\.png)"')
        .allMatches(html)
        .map((match) => match.group(1)!)
        .toSet();
    expect(hrefs, isNotEmpty);
    for (final href in hrefs) {
      expect(File('web/$href').existsSync(), isTrue, reason: href);
    }
  });
}
