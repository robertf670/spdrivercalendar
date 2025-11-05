import 'package:flutter/material.dart';
import 'package:spdrivercalendar/services/update_service.dart';
import 'package:spdrivercalendar/services/apk_download_manager.dart';

class EnhancedUpdateDialog extends StatefulWidget {
  final UpdateInfo updateInfo;

  const EnhancedUpdateDialog({super.key, required this.updateInfo});

  @override
  State<EnhancedUpdateDialog> createState() => _EnhancedUpdateDialogState();
}

class _EnhancedUpdateDialogState extends State<EnhancedUpdateDialog> {
  bool _isDownloading = false;
  bool _useInAppDownload = true;
  DownloadProgress? _progress;
  String? _downloadPath;

  @override
  void initState() {
    super.initState();
    _loadDownloadPath();
  }

  Future<void> _loadDownloadPath() async {
    try {
      final path = await UpdateService.getDownloadPath();
      setState(() {
        _downloadPath = path;
      });
    } catch (e) {
      // Ignore error, will fall back to browser download
    }
  }



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _isDownloading ? Icons.downloading : Icons.system_update,
              color: theme.colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _isDownloading ? 'Updating...' : 'Update Available',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_isDownloading) ...[
              _buildVersionInfo(theme),
              const SizedBox(height: 16),
              _buildDownloadOptions(theme),
            ] else ...[
              _buildDownloadProgress(theme),
            ],
          ],
        ),
      ),
      actions: _isDownloading ? _buildDownloadingActions() : _buildInitialActions(),
    );
  }

  Widget _buildVersionInfo(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.new_releases, size: 20),
          const SizedBox(width: 8),
          Text(
            'Version ${widget.updateInfo.latestVersion}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'NEW',
              style: TextStyle(
                color: theme.colorScheme.onPrimary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadOptions(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Download Options:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              _buildDownloadOption(
                title: 'Smart Download (Recommended)',
                subtitle: 'Download directly in app with auto-install',
                icon: Icons.smart_button,
                isSelected: _useInAppDownload,
                onTap: () => setState(() => _useInAppDownload = true),
              ),
              const SizedBox(height: 8),
              _buildDownloadOption(
                title: 'Browser Download',
                subtitle: 'Download using your browser',
                icon: Icons.web,
                isSelected: !_useInAppDownload,
                onTap: () => setState(() => _useInAppDownload = false),
              ),
              if (_downloadPath != null && _useInAppDownload) ...[
                const SizedBox(height: 8),
                Text(
                  'Download location: $_downloadPath',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDownloadOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected 
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected 
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Radio<bool>(
              value: true,
              groupValue: isSelected,
              onChanged: (_) => onTap(),
            ),
            const SizedBox(width: 8),
            Icon(
              icon,
              size: 20,
              color: isSelected 
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isSelected 
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadProgress(ThemeData theme) {
    final progress = _progress;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (progress != null) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  progress.status,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${progress.percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress.percentage / 100,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
          const SizedBox(height: 8),
          if (progress.totalBytes > 0) ...[
            Text(
              '${_formatBytes(progress.downloadedBytes)} / ${_formatBytes(progress.totalBytes)}',
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ] else ...[
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          const Text('Preparing download...'),
        ],
      ],
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  List<Widget> _buildInitialActions() {
    final theme = Theme.of(context);
    
    return [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(
          'Later',
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
      const SizedBox(width: 8),
      ElevatedButton.icon(
        onPressed: _startUpdate,
        icon: Icon(
          _useInAppDownload ? Icons.download : Icons.web,
          size: 18,
        ),
        label: Text(_useInAppDownload ? 'Update Now' : 'Download'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    ];
  }

  List<Widget> _buildDownloadingActions() {
    return [
      TextButton(
        onPressed: () {
          UpdateService.cancelDownload();
          Navigator.of(context).pop();
        },
        child: const Text('Cancel'),
      ),
    ];
  }

  Future<void> _startUpdate() async {
    setState(() {
      _isDownloading = true;
    });

    try {
      bool success;
      
      if (_useInAppDownload) {
        success = await UpdateService.downloadAndInstallUpdate(
          widget.updateInfo,
          (progress) {
            if (mounted) {
              setState(() {
                _progress = progress;
              });
            }
          },
        );
      } else {
        success = await UpdateService.downloadUpdate(widget.updateInfo.downloadUrl);
      }

      if (mounted) {
        Navigator.of(context).pop();
        
        if (success) {
          if (_useInAppDownload) {
            _showInstallInstructions();
          } else {
            _showBrowserDownloadInstructions();
          }
        } else {
          _showDownloadError();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _progress = null;
        });
        _showDownloadError();
      }
    }
  }

  void _showInstallInstructions() {
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Ready to Install'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.android,
              size: 48,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            Text(
              'The update has been downloaded and is ready to install.',
              style: TextStyle(
                fontSize: 16,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Android will now prompt you to install the update. Tap "Install" when prompted.',
                style: TextStyle(fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showBrowserDownloadInstructions() {
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.download_done,
                color: Colors.blue,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Download Started'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.smartphone,
              size: 48,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            Text(
              'The update is downloading in your browser.',
              style: TextStyle(
                fontSize: 16,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Check your Downloads folder and tap the APK file to install when ready.',
                style: TextStyle(fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showDownloadError() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Download Failed'),
          ],
        ),
        content: const Text(
          'Unable to download the update. Please check your internet connection and try again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }


} 
