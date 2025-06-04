import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';

class DownloadProgress {
  final int downloadedBytes;
  final int totalBytes;
  final double percentage;
  final String status;

  DownloadProgress({
    required this.downloadedBytes,
    required this.totalBytes,
    required this.percentage,
    required this.status,
  });

  factory DownloadProgress.downloading(int downloaded, int total) {
    final percentage = total > 0 ? (downloaded / total * 100) : 0.0;
    return DownloadProgress(
      downloadedBytes: downloaded,
      totalBytes: total,
      percentage: percentage,
      status: 'Downloading...',
    );
  }

  factory DownloadProgress.completed() {
    return DownloadProgress(
      downloadedBytes: 0,
      totalBytes: 0,
      percentage: 100.0,
      status: 'Download completed',
    );
  }

  factory DownloadProgress.installing() {
    return DownloadProgress(
      downloadedBytes: 0,
      totalBytes: 0,
      percentage: 100.0,
      status: 'Installing...',
    );
  }

  factory DownloadProgress.error(String message) {
    return DownloadProgress(
      downloadedBytes: 0,
      totalBytes: 0,
      percentage: 0.0,
      status: 'Error: $message',
    );
  }
}

class ApkDownloadManager {
  static final Dio _dio = Dio();
  static CancelToken? _cancelToken;

  /// Download APK with progress tracking
  static Future<String?> downloadApk(
    String downloadUrl,
    String version,
    Function(DownloadProgress) onProgress,
  ) async {
    try {
      // Check and request permissions
      if (!await _checkPermissions()) {
        onProgress(DownloadProgress.error('Storage permission denied'));
        return null;
      }

      // Create download directory
      final directory = await _getDownloadDirectory();
      if (directory == null) {
        onProgress(DownloadProgress.error('Could not access download directory'));
        return null;
      }

      final fileName = 'spdrivercalendar-$version.apk';
      final filePath = '${directory.path}/$fileName';

      // Clean up any existing file
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }

      // Initialize cancel token
      _cancelToken = CancelToken();

      print('[Download] Starting download: $downloadUrl');
      print('[Download] Saving to: $filePath');

      // Download with progress tracking
      await _dio.download(
        downloadUrl,
        filePath,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            onProgress(DownloadProgress.downloading(received, total));
          }
        },
        options: Options(
          headers: {
            'User-Agent': 'SpDriverCalendar-App/$version',
          },
        ),
      );

      // Verify file was downloaded
      if (await file.exists()) {
        final fileSize = await file.length();
        print('[Download] File downloaded successfully: $fileSize bytes');
        onProgress(DownloadProgress.completed());
        return filePath;
      } else {
        onProgress(DownloadProgress.error('Download failed - file not found'));
        return null;
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        onProgress(DownloadProgress.error('Download cancelled'));
      } else {
        onProgress(DownloadProgress.error('Network error: ${e.message}'));
      }
      print('[Download] Error: $e');
      return null;
    } catch (e) {
      onProgress(DownloadProgress.error('Unexpected error: $e'));
      print('[Download] Unexpected error: $e');
      return null;
    }
  }

  /// Attempt to auto-install the downloaded APK
  static Future<bool> installApk(String filePath, Function(DownloadProgress) onProgress) async {
    try {
      onProgress(DownloadProgress.installing());
      
      final file = File(filePath);
      if (!await file.exists()) {
        onProgress(DownloadProgress.error('APK file not found'));
        return false;
      }

      print('[Install] Attempting to install: $filePath');

      // Try to open APK file with system installer
      final result = await OpenFilex.open(filePath);
      
      if (result.type == ResultType.done) {
        print('[Install] APK opened successfully with system installer');
        onProgress(DownloadProgress(
          downloadedBytes: 0,
          totalBytes: 0,
          percentage: 100.0,
          status: 'Tap "Install" when prompted',
        ));
        return true;
      } else {
        print('[Install] Failed to open APK: ${result.message}');
        // Fallback: Try URL launcher
        return await _openApkFile(filePath, onProgress);
      }
    } catch (e) {
      print('[Install] Install error: $e');
      // Fallback: Open file with system installer
      return await _openApkFile(filePath, onProgress);
    }
  }

  /// Fallback: Open APK file with system installer
  static Future<bool> _openApkFile(String filePath, Function(DownloadProgress) onProgress) async {
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
      print('[Install] Error opening APK file: $e');
      return false;
    }
  }

  /// Cancel ongoing download
  static void cancelDownload() {
    _cancelToken?.cancel('User cancelled download');
    _cancelToken = null;
  }

  /// Check and request necessary permissions
  static Future<bool> _checkPermissions() async {
    try {
      // For Android 11+ (API 30+), we need different permissions
      if (Platform.isAndroid) {
        final androidInfo = await _getAndroidVersion();
        
        if (androidInfo >= 30) {
          // Android 11+ - Check MANAGE_EXTERNAL_STORAGE or use app-specific directory
          final status = await Permission.manageExternalStorage.status;
          if (!status.isGranted) {
            // Try to use app-specific directory instead
            return true; // We'll use getApplicationDocumentsDirectory()
          }
        } else {
          // Android 10 and below
          final status = await Permission.storage.status;
          if (!status.isGranted) {
            final result = await Permission.storage.request();
            return result.isGranted;
          }
        }
        
        // Check install permission
        final installStatus = await Permission.requestInstallPackages.status;
        if (!installStatus.isGranted) {
          final installResult = await Permission.requestInstallPackages.request();
          if (!installResult.isGranted) {
            print('[Permissions] Install permission denied - will use fallback');
            // Continue anyway - we can still download and open the file
          }
        }
      }
      
      return true;
    } catch (e) {
      print('[Permissions] Error checking permissions: $e');
      return true; // Continue anyway
    }
  }

  /// Get appropriate download directory based on Android version
  static Future<Directory?> _getDownloadDirectory() async {
    try {
      if (Platform.isAndroid) {
        final androidVersion = await _getAndroidVersion();
        
        if (androidVersion >= 30) {
          // Android 11+ - Use app-specific directory
          return await getApplicationDocumentsDirectory();
        } else {
          // Android 10 and below - Use external storage
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
      
      // Fallback to app documents directory
      return await getApplicationDocumentsDirectory();
    } catch (e) {
      print('[Directory] Error getting download directory: $e');
      return null;
    }
  }

  /// Get Android version (API level approximation)
  static Future<int> _getAndroidVersion() async {
    try {
      // This is a simplified version detection
      // In a real implementation, you might want to use a plugin to get exact API level
      return 29; // Default to Android 10 for safety
    } catch (e) {
      return 29;
    }
  }

  /// Clean up old downloaded APK files
  static Future<void> cleanupOldDownloads() async {
    try {
      final directory = await _getDownloadDirectory();
      if (directory == null) return;

      final files = directory.listSync();
      for (final file in files) {
        if (file is File && file.path.endsWith('.apk') && file.path.contains('spdrivercalendar')) {
          final stat = await file.stat();
          final age = DateTime.now().difference(stat.modified);
          
          // Delete APK files older than 7 days
          if (age.inDays > 7) {
            await file.delete();
            print('[Cleanup] Deleted old APK: ${file.path}');
          }
        }
      }
    } catch (e) {
      print('[Cleanup] Error cleaning up old downloads: $e');
    }
  }

  /// Get download directory path for display
  static Future<String> getDownloadPath() async {
    final directory = await _getDownloadDirectory();
    return directory?.path ?? 'Unknown';
  }
} 