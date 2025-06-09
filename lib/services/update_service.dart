import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:spdrivercalendar/core/services/storage_service.dart';
import 'package:spdrivercalendar/services/apk_download_manager.dart';

class UpdateInfo {
  final String latestVersion;
  final String downloadUrl;
  final String releaseNotes;
  final bool hasUpdate;
  final String publishedAt;
  final int downloadCount;

  UpdateInfo({
    required this.latestVersion,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.hasUpdate,
    required this.publishedAt,
    required this.downloadCount,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json, String currentVersion) {
    final latestVersion = json['tag_name'].toString().replaceFirst('v', '');
    
    // Find the APK asset
    final assets = json['assets'] as List;
    final apkAsset = assets.firstWhere(
      (asset) => asset['name'].toString().endsWith('.apk'),
      orElse: () => null,
    );

    final downloadUrl = apkAsset?['browser_download_url'] ?? '';
    final downloadCount = apkAsset?['download_count'] ?? 0;
    final releaseNotes = json['body'] ?? 'No release notes available';
    final publishedAt = json['published_at'] ?? '';

    // Compare versions
    final hasUpdate = _isNewerVersion(currentVersion, latestVersion);

    return UpdateInfo(
      latestVersion: latestVersion,
      downloadUrl: downloadUrl,
      releaseNotes: releaseNotes,
      hasUpdate: hasUpdate,
      publishedAt: publishedAt,
      downloadCount: downloadCount,
    );
  }

  static bool _isNewerVersion(String current, String latest) {
    try {
      final currentParts = current.split('.').map(int.parse).toList();
      final latestParts = latest.split('.').map(int.parse).toList();

      // Ensure both have same number of parts
      while (currentParts.length < latestParts.length) currentParts.add(0);
      while (latestParts.length < currentParts.length) latestParts.add(0);

      for (int i = 0; i < currentParts.length; i++) {
        if (latestParts[i] > currentParts[i]) return true;
        if (latestParts[i] < currentParts[i]) return false;
      }
      return false;
    } catch (e) {
      // Error comparing versions
      return false;
    }
  }
}

class UpdateService {
  static const String repoOwner = 'robertf670';
  static const String repoName = 'spdrivercalendar';
  static const String apiUrl = 'https://api.github.com/repos/$repoOwner/$repoName/releases/latest';
  static const String lastUpdateCheckKey = 'last_update_check';
  static const String updateCheckIntervalHours = 'update_check_interval';
  
  /// Check for updates with optional frequency control
  static Future<UpdateInfo?> checkForUpdate({bool forceCheck = false}) async {
    try {
      // Check if we should skip update check based on frequency
      if (!forceCheck && !await _shouldCheckForUpdate()) {
        // Skipping update check - too soon since last check
        return null;
      }

      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      // Checking for updates

      // Fetch latest release from GitHub
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'SpDriverCalendar-App/$currentVersion',
        },
      );

      if (response.statusCode != 200) {
        // Failed to check for updates
        return null;
      }

      final releaseData = jsonDecode(response.body);
      final updateInfo = UpdateInfo.fromJson(releaseData, currentVersion);

      // Update last check timestamp
      await StorageService.saveString(
        lastUpdateCheckKey, 
        DateTime.now().toIso8601String()
      );


      
      return updateInfo;

    } catch (e) {

      return null;
    }
  }

  /// Check if enough time has passed since last update check
  static Future<bool> _shouldCheckForUpdate() async {
    try {
      final lastCheckString = await StorageService.getString(lastUpdateCheckKey);
      if (lastCheckString == null) return true;

      final lastCheck = DateTime.parse(lastCheckString);
      final hoursSinceLastCheck = DateTime.now().difference(lastCheck).inHours;
      
      // Check every 24 hours by default
      final checkInterval = await StorageService.getInt(updateCheckIntervalHours, defaultValue: 24);
      
      return hoursSinceLastCheck >= checkInterval;
    } catch (e) {

      return true; // Default to checking if there's an error
    }
  }

  /// Download and install update using in-app downloader with fallback
  static Future<bool> downloadAndInstallUpdate(
    UpdateInfo updateInfo,
    Function(DownloadProgress) onProgress,
  ) async {
    try {

      
      // Clean up old downloads first
      await ApkDownloadManager.cleanupOldDownloads();
      
      // Download APK
      final filePath = await ApkDownloadManager.downloadApk(
        updateInfo.downloadUrl,
        updateInfo.latestVersion,
        onProgress,
      );

      if (filePath == null) {

        return await _fallbackToBrowser(updateInfo.downloadUrl);
      }

      // Try to install

      final installSuccess = await ApkDownloadManager.installApk(filePath, onProgress);
      
      if (installSuccess) {

        return true;
      } else {

        return await _fallbackToBrowser(updateInfo.downloadUrl);
      }

    } catch (e) {

      // Fallback to browser on any error
      return await _fallbackToBrowser(updateInfo.downloadUrl);
    }
  }

  /// Original download method (browser-based) - kept as fallback
  static Future<bool> downloadUpdate(String downloadUrl) async {
    return await _fallbackToBrowser(downloadUrl);
  }

  /// Fallback to browser download
  static Future<bool> _fallbackToBrowser(String downloadUrl) async {
    try {
      final uri = Uri.parse(downloadUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri, 
          mode: LaunchMode.externalApplication,
        );
        return true;
      }
      return false;
    } catch (e) {

      return false;
    }
  }

  /// Cancel ongoing download
  static void cancelDownload() {
    ApkDownloadManager.cancelDownload();
  }

  /// Get formatted release notes for display
  static String formatReleaseNotes(String releaseNotes) {
    if (releaseNotes.isEmpty || releaseNotes == 'No release notes available') {
      return '• Bug fixes and improvements\n• Performance optimizations';
    }
    
    // Clean up markdown formatting for display
    String formatted = releaseNotes
        .replaceAll('###', '•')
        .replaceAll('##', '•')
        .replaceAll('# ', '• ')
        .replaceAll('- ', '• ');
    
    // Limit length for dialog display
    if (formatted.length > 300) {
      formatted = formatted.substring(0, 300) + '...';
    }
    
    return formatted;
  }

  /// Set update check frequency (in hours)
  static Future<void> setUpdateCheckFrequency(int hours) async {
    await StorageService.saveInt(updateCheckIntervalHours, hours);
  }

  /// Get current update check frequency
  static Future<int> getUpdateCheckFrequency() async {
    return await StorageService.getInt(updateCheckIntervalHours, defaultValue: 24);
  }

  /// Get download directory for display purposes
  static Future<String> getDownloadPath() async {
    return await ApkDownloadManager.getDownloadPath();
  }
} 
