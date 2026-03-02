// Conditional export: mobile stub vs web implementation.
export 'web_update_notifier_stub.dart'
    if (dart.library.html) 'web_update_notifier_web.dart';
