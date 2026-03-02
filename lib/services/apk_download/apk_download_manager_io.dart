import 'dart:io';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:spdrivercalendar/core/config/platform_utils.dart';
import 'package:spdrivercalendar/services/apk_download/apk_download_models.dart';

class ApkDownloadManager {
  static final Dio _dio = Dio();
  static CancelToken? _cancelToken;

  static Future<String?> downloadApk(
    String downloadUrl,
    String version,
    Function(DownloadProgress) onProgress,
  ) async {
    try {
      onProgress(DownloadProgress(
        downloadedBytes: 0,
        totalBytes: 0,
        percentage: 0.0,
        status: 'Checking permissions...',
      ));

      if (!await _checkPermissions()) {
        onProgress(DownloadProgress.error('Storage permissions required for download'));
        return null;
      }

      onProgress(DownloadProgress(
        downloadedBytes: 0,
        totalBytes: 0,
        percentage: 0.0,
        status: 'Preparing download...',
      ));

      final directory = await _getDownloadDirectory();
      if (directory == null) {
        onProgress(DownloadProgress.error('Could not access download directory'));
        return null;
      }

      final fileName = 'spdrivercalendar-$version.apk';
      final filePath = '${directory.path}/$fileName';

      final file = File(filePath);
      if (await file.exists()) await file.delete();

      _cancelToken = CancelToken();

      await _dio.download(
        downloadUrl,
        filePath,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0) onProgress(DownloadProgress.downloading(received, total));
        },
        options: Options(
          headers: {'User-Agent': 'SpDriverCalendar-App/$version'},
          receiveTimeout: const Duration(minutes: 10),
          sendTimeout: const Duration(minutes: 5),
        ),
      );

      if (await file.exists()) {
        onProgress(DownloadProgress.completed());
        return filePath;
      }
      onProgress(DownloadProgress.error('Download completed but file not found'));
      return null;
    } on DioException catch (e) {
      String errorMsg;
      if (e.type == DioExceptionType.cancel) {
        errorMsg = 'Download cancelled by user';
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMsg = 'Connection timeout - check your internet';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMsg = 'Download timeout - file too large or slow connection';
      } else if (e.type == DioExceptionType.badResponse) {
        errorMsg = 'Server error: ${e.response?.statusCode ?? 'Unknown'}';
      } else {
        errorMsg = 'Network error: ${e.message ?? 'Unknown'}';
      }
      onProgress(DownloadProgress.error(errorMsg));
      return null;
    } catch (e) {
      onProgress(DownloadProgress.error('Unexpected error: $e'));
      return null;
    }
  }

  static Future<bool> installApk(
      String filePath, Function(DownloadProgress) onProgress) async {
    try {
      onProgress(DownloadProgress.installing());

      final file = File(filePath);
      if (!await file.exists()) {
        onProgress(DownloadProgress.error('APK file not found'));
        return false;
      }

      final result = await OpenFilex.open(filePath);
      if (result.type == ResultType.done) {
        onProgress(DownloadProgress(
          downloadedBytes: 0,
          totalBytes: 0,
          percentage: 100.0,
          status: 'Tap "Install" when prompted',
        ));
        return true;
      }
      return await _openApkFile(filePath, onProgress);
    } catch (e) {
      return await _openApkFile(filePath, onProgress);
    }
  }

  static Future<bool> _openApkFile(
      String filePath, Function(DownloadProgress) onProgress) async {
    try {
      final uri = Uri.file(filePath);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        onProgress(DownloadProgress(
          downloadedBytes: 0,
          totalBytes: 0,
          percentage: 100.0,
          status: 'Tap the APK to install',
        ));
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static void cancelDownload() {
    _cancelToken?.cancel('User cancelled download');
    _cancelToken = null;
  }

  static Future<bool> _checkPermissions() async {
    try {
      if (PlatformUtils.isAndroid) {
        final androidInfo = await _getAndroidVersion();
        if (androidInfo >= 30) {
          final manageStorageStatus = await Permission.manageExternalStorage.status;
          if (!manageStorageStatus.isGranted) {
            await Permission.manageExternalStorage.request();
          }
        } else {
          final storageStatus = await Permission.storage.status;
          if (!storageStatus.isGranted) {
            final storageResult = await Permission.storage.request();
            if (!storageResult.isGranted) return false;
          }
        }
        final installStatus = await Permission.requestInstallPackages.status;
        if (!installStatus.isGranted) {
          await Permission.requestInstallPackages.request();
        }
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<Directory?> _getDownloadDirectory() async {
    try {
      if (PlatformUtils.isAndroid) {
        final androidVersion = await _getAndroidVersion();
        if (androidVersion >= 30) {
          return await getApplicationDocumentsDirectory();
        } else {
          final directory = await getExternalStorageDirectory();
          if (directory != null) {
            final downloadDir = Directory('${directory.path}/Download');
            if (!await downloadDir.exists()) {
              await downloadDir.create(recursive: true);
            }
            return downloadDir;
          }
        }
      }
      return await getApplicationDocumentsDirectory();
    } catch (e) {
      return null;
    }
  }

  static Future<int> _getAndroidVersion() async {
    try {
      if (PlatformUtils.isAndroid) {
        final result = await Process.run('getprop', ['ro.build.version.sdk']);
        if (result.exitCode == 0) {
          final apiLevel = int.tryParse(result.stdout.toString().trim());
          if (apiLevel != null) return apiLevel;
        }
      }
      return 29;
    } catch (e) {
      return 29;
    }
  }

  static Future<void> cleanupOldDownloads() async {
    try {
      final directory = await _getDownloadDirectory();
      if (directory == null) return;

      for (final file in directory.listSync()) {
        if (file is File &&
            file.path.endsWith('.apk') &&
            file.path.contains('spdrivercalendar')) {
          final stat = await file.stat();
          if (DateTime.now().difference(stat.modified).inDays > 7) {
            await file.delete();
          }
        }
      }
    } catch (_) {
      // Ignore file system errors during cleanup
    }
  }

  static Future<String> getDownloadPath() async {
    final directory = await _getDownloadDirectory();
    return directory?.path ?? 'Unknown';
  }
}
