import 'dart:async';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

import 'package:flutter/material.dart';

/// Web: Listens for service worker updates and shows SnackBar with Reload option.
void initWebUpdateNotifier(GlobalKey<NavigatorState>? navigatorKey) {
  if (navigatorKey == null) return;

  void checkAndShow() {
    final context = navigatorKey.currentContext;
    if (context != null && context.mounted) {
      _checkForUpdate(context, navigatorKey);
    }
  }

  checkAndShow();
  Timer.periodic(const Duration(minutes: 5), (_) => checkAndShow());
}

Future<void> _checkForUpdate(
    BuildContext context, GlobalKey<NavigatorState> navigatorKey) async {
  try {
    final sw = html.window.navigator.serviceWorker;
    if (sw == null) return;
    final registration = await sw.ready;

    if (registration.waiting != null) {
      _showUpdateSnackBar(navigatorKey, registration);
      return;
    }

    registration.addEventListener('updatefound', (_) {
      final newWorker = registration.installing;
      if (newWorker == null) return;
      newWorker.addEventListener('statechange', (_) {
        if (newWorker.state == 'installed' && registration.waiting != null) {
          _showUpdateSnackBar(navigatorKey, registration);
        }
      });
    });

    await registration.update();
  } catch (_) {}
}

void _showUpdateSnackBar(
    GlobalKey<NavigatorState> navigatorKey, html.ServiceWorkerRegistration registration) {
  final context = navigatorKey.currentContext;
  if (context == null || !context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const Text('Update available.'),
      action: SnackBarAction(
        label: 'Reload',
        onPressed: () {
          registration.waiting?.postMessage({'type': 'SKIP_WAITING'});
          html.window.location.reload();
        },
      ),
      duration: const Duration(days: 1),
    ),
  );
}
