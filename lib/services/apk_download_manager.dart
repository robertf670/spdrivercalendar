// Conditional export: Android uses IO; Web uses stub (APK download is Android-only).
export 'apk_download/apk_download_models.dart';
export 'apk_download/apk_download_manager_io.dart'
    if (dart.library.html) 'apk_download/apk_download_manager_stub.dart';
