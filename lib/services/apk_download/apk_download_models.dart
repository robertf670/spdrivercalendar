/// Shared model for APK download progress.
/// Used by both IO and stub implementations.
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
