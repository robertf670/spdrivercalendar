import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';

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
      onProgress(DownloadProgress(
        downloadedBytes: 0,
        totalBytes: 0,
        percentage: 0.0,
        status: 'Checking permissions...',
      ));
      
      if (!await _checkPermissions()) {
        const errorMsg = 'Storage permissions required for download';

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
        const errorMsg = 'Could not access download directory';

        onProgress(DownloadProgress.error(errorMsg));
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



      // Download with progress tracking
      await _dio.download(
        downloadUrl,
        filePath,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final progress = DownloadProgress.downloading(received, total);

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
        // File downloaded successfully
        onProgress(DownloadProgress.completed());
        return filePath;
      } else {
        const errorMsg = 'Download completed but file not found';

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
      

      onProgress(DownloadProgress.error(errorMsg));
      return null;
    } catch (e) {
      final errorMsg = 'Unexpected error: $e';

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



      // Try to open APK file with system installer
      final result = await OpenFilex.open(filePath);
      
      if (result.type == ResultType.done) {

        onProgress(DownloadProgress(
          downloadedBytes: 0,
          totalBytes: 0,
          percentage: 100.0,
          status: 'Tap "Install" when prompted',
        ));
        return true;
      } else {

        // Fallback: Try URL launcher
        return await _openApkFile(filePath, onProgress);
      }
    } catch (e) {

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
          // Android 11+ - Try MANAGE_EXTERNAL_STORAGE first
          final manageStorageStatus = await Permission.manageExternalStorage.status;

          
          if (!manageStorageStatus.isGranted) {
            // Request MANAGE_EXTERNAL_STORAGE permission
            final manageStorageResult = await Permission.manageExternalStorage.request();

            
            if (!manageStorageResult.isGranted) {
              // If denied, we can still use app-specific directory

              // Continue - we'll use app-specific directory
            }
          }
        } else {
          // Android 10 and below
          final storageStatus = await Permission.storage.status;

          
          if (!storageStatus.isGranted) {
            final storageResult = await Permission.storage.request();

            
            if (!storageResult.isGranted) {

              return false;
            }
          }
        }
        
        // Check install permission (important for APK installation)
        final installStatus = await Permission.requestInstallPackages.status;

        
        if (!installStatus.isGranted) {
          final installResult = await Permission.requestInstallPackages.request();

          
          if (!installResult.isGranted) {

            // Continue anyway - user can manually install from Downloads
          }
        }
      }
      

              return true;
      } catch (e) {
        // Failed to check permissions, continue without
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

            return apiLevel;
          }
        }
      }
      
      // Fallback - assume Android 10 (API 29) for safety

      return 29;
    } catch (e) {
      // Failed to get Android version, use default
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

          }
        }
      }
    } catch (e) {
      // Failed to cleanup old downloads
    }
  }

  /// Get download directory path for display
  static Future<String> getDownloadPath() async {
    final directory = await _getDownloadDirectory();
    return directory?.path ?? 'Unknown';
  }
} 
