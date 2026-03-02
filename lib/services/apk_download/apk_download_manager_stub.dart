import 'package:spdrivercalendar/services/apk_download/apk_download_models.dart';

/// Web stub: APK download is Android-only. All methods no-op or return null/false.
class ApkDownloadManager {
  static Future<String?> downloadApk(
    String downloadUrl,
    String version,
    Function(DownloadProgress) onProgress,
  ) async {
    return null;
  }

  static Future<bool> installApk(
      String filePath, Function(DownloadProgress) onProgress) async {
    return false;
  }

  static void cancelDownload() {}

  static Future<void> cleanupOldDownloads() async {}

  static Future<String> getDownloadPath() async {
    return 'N/A';
  }
}
