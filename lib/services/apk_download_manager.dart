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
      print('[Download] Starting APK download for version $version');
      print('[Download] URL: $downloadUrl');
      
      // Check and request permissions
      onProgress(DownloadProgress(
        downloadedBytes: 0,
        totalBytes: 0,
        percentage: 0.0,
        status: 'Checking permissions...',
      ));
      
      if (!await _checkPermissions()) {
        final errorMsg = 'Storage permissions required for download';
        print('[Download] Permission check failed: $errorMsg');
        onProgress(DownloadProgress.error(errorMsg));
        return null;
      }

      // Create download directory
      onProgress(DownloadProgress(
        downloadedBytes: 0,
        totalBytes: 0,
        percentage: 0.0,
        status: 'Preparing download...',
      ));
      
      final directory = await _getDownloadDirectory();
      if (directory == null) {
        final errorMsg = 'Could not access download directory';
        print('[Download] Directory access failed: $errorMsg');
        onProgress(DownloadProgress.error(errorMsg));
        return null;
      }

      print('[Download] Using directory: ${directory.path}');

      final fileName = 'spdrivercalendar-$version.apk';
      final filePath = '${directory.path}/$fileName';

      // Clean up any existing file
      final file = File(filePath);
      if (await file.exists()) {
        print('[Download] Removing existing file: $filePath');
        await file.delete();
      }

      // Initialize cancel token
      _cancelToken = CancelToken();

      print('[Download] Starting download to: $filePath');

      // Download with progress tracking
      await _dio.download(
        downloadUrl,
        filePath,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final progress = DownloadProgress.downloading(received, total);
            print('[Download] Progress: ${progress.percentage.toStringAsFixed(1)}% (${(received / 1024 / 1024).toStringAsFixed(1)}/${(total / 1024 / 1024).toStringAsFixed(1)} MB)');
            onProgress(progress);
          }
        },
        options: Options(
          headers: {
            'User-Agent': 'SpDriverCalendar-App/$version',
          },
          receiveTimeout: const Duration(minutes: 10),
          sendTimeout: const Duration(minutes: 5),
        ),
      );

      // Verify file was downloaded
      if (await file.exists()) {
        final fileSize = await file.length();
        print('[Download] File downloaded successfully: ${(fileSize / 1024 / 1024).toStringAsFixed(1)} MB');
        onProgress(DownloadProgress.completed());
        return filePath;
      } else {
        final errorMsg = 'Download completed but file not found';
        print('[Download] Verification failed: $errorMsg');
        onProgress(DownloadProgress.error(errorMsg));
        return null;
      }
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
      
      print('[Download] DioException: $errorMsg');
      onProgress(DownloadProgress.error(errorMsg));
      return null;
    } catch (e) {
      final errorMsg = 'Unexpected error: $e';
      print('[Download] Unexpected error: $errorMsg');
      onProgress(DownloadProgress.error(errorMsg));
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
      print('[Permissions] Checking permissions...');
      
      // For Android 11+ (API 30+), we need different permissions
      if (Platform.isAndroid) {
        final androidInfo = await _getAndroidVersion();
        print('[Permissions] Android API level: $androidInfo');
        
        if (androidInfo >= 30) {
          // Android 11+ - Try MANAGE_EXTERNAL_STORAGE first
          final manageStorageStatus = await Permission.manageExternalStorage.status;
          print('[Permissions] MANAGE_EXTERNAL_STORAGE status: $manageStorageStatus');
          
          if (!manageStorageStatus.isGranted) {
            // Request MANAGE_EXTERNAL_STORAGE permission
            final manageStorageResult = await Permission.manageExternalStorage.request();
            print('[Permissions] MANAGE_EXTERNAL_STORAGE request result: $manageStorageResult');
            
            if (!manageStorageResult.isGranted) {
              // If denied, we can still use app-specific directory
              print('[Permissions] MANAGE_EXTERNAL_STORAGE denied, using app-specific directory');
              // Continue - we'll use app-specific directory
            }
          }
        } else {
          // Android 10 and below
          final storageStatus = await Permission.storage.status;
          print('[Permissions] STORAGE status: $storageStatus');
          
          if (!storageStatus.isGranted) {
            final storageResult = await Permission.storage.request();
            print('[Permissions] STORAGE request result: $storageResult');
            
            if (!storageResult.isGranted) {
              print('[Permissions] Storage permission denied');
              return false;
            }
          }
        }
        
        // Check install permission (important for APK installation)
        final installStatus = await Permission.requestInstallPackages.status;
        print('[Permissions] REQUEST_INSTALL_PACKAGES status: $installStatus');
        
        if (!installStatus.isGranted) {
          final installResult = await Permission.requestInstallPackages.request();
          print('[Permissions] REQUEST_INSTALL_PACKAGES request result: $installResult');
          
          if (!installResult.isGranted) {
            print('[Permissions] Install permission denied - APK installation may fail');
            // Continue anyway - user can manually install from Downloads
          }
        }
      }
      
      print('[Permissions] Permission check completed successfully');
      return true;
    } catch (e) {
      print('[Permissions] Error checking permissions: $e');
      return false;
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
      if (Platform.isAndroid) {
        // Try to get actual Android version from system properties
        // This is a simplified approach - in production you'd use platform_device_id or similar
        final result = await Process.run('getprop', ['ro.build.version.sdk']);
        if (result.exitCode == 0) {
          final apiLevel = int.tryParse(result.stdout.toString().trim());
          if (apiLevel != null) {
            print('[Version] Detected Android API level: $apiLevel');
            return apiLevel;
          }
        }
      }
      
      // Fallback - assume Android 10 (API 29) for safety
      print('[Version] Using fallback Android API level: 29');
      return 29;
    } catch (e) {
      print('[Version] Error detecting Android version: $e, using fallback');
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