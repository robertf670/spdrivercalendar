import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:spdrivercalendar/services/update_service.dart';
import 'package:spdrivercalendar/services/apk_download_manager.dart';
import 'package:spdrivercalendar/core/constants/changelog_data.dart';

class EnhancedUpdateDialog extends StatefulWidget {
  final UpdateInfo updateInfo;

  const EnhancedUpdateDialog({Key? key, required this.updateInfo}) : super(key: key);

  @override
  State<EnhancedUpdateDialog> createState() => _EnhancedUpdateDialogState();
}

class _EnhancedUpdateDialogState extends State<EnhancedUpdateDialog> {
  bool _isDownloading = false;
  bool _useInAppDownload = true;
  DownloadProgress? _progress;
  String? _downloadPath;
  String? _currentVersion;

  @override
  void initState() {
    super.initState();
    _loadDownloadPath();
    _loadCurrentVersion();
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

  Future<void> _loadCurrentVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _currentVersion = packageInfo.version;
      });
    } catch (e) {
      // Ignore error, will use fallback in changelog method
    }
  }

  /// Compare two version strings semantically
  int _compareVersions(String version1, String version2) {
    try {
      final v1Parts = version1.split('.').map(int.parse).toList();
      final v2Parts = version2.split('.').map(int.parse).toList();
      
      // Ensure both have same number of parts
      while (v1Parts.length < v2Parts.length) v1Parts.add(0);
      while (v2Parts.length < v1Parts.length) v2Parts.add(0);
      
      for (int i = 0; i < v1Parts.length; i++) {
        if (v1Parts[i] != v2Parts[i]) {
          return v1Parts[i].compareTo(v2Parts[i]);
        }
      }
      return 0;
    } catch (e) {
      // Fallback to string comparison if parsing fails
      return version1.compareTo(version2);
    }
  }

  /// Get list of versions between current and latest (inclusive of latest)
  List<String> _getMissedVersions() {
    if (_currentVersion == null) return [widget.updateInfo.latestVersion];
    
    final allVersions = changelogData.keys.toList()
      ..sort((a, b) => _compareVersions(a, b)); // Ascending order
    
    return allVersions.where((version) {
      return _compareVersions(version, _currentVersion!) > 0 && 
             _compareVersions(version, widget.updateInfo.latestVersion) <= 0;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedNotes = _getLocalChangelogNotes();
    
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
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
              _buildReleaseNotes(theme, formattedNotes),
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
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
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
              color: Colors.green,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'NEW',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReleaseNotes(ThemeData theme, String formattedNotes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What\'s New:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Text(
            formattedNotes,
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurface.withOpacity(0.8),
              height: 1.4,
            ),
          ),
        ),
      ],
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
            color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
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
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
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
              ? theme.colorScheme.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected 
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withOpacity(0.3),
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
                  : theme.colorScheme.onSurface.withOpacity(0.6),
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
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
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
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress.percentage / 100,
            backgroundColor: theme.colorScheme.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
          const SizedBox(height: 8),
          if (progress.totalBytes > 0) ...[
            Text(
              '${_formatBytes(progress.downloadedBytes)} / ${_formatBytes(progress.totalBytes)}',
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
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
            color: theme.colorScheme.onSurface.withOpacity(0.6),
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
                color: Colors.green.withOpacity(0.1),
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
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
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
                color: Colors.blue.withOpacity(0.1),
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
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
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

  /// Get properly formatted changelog notes from local data
  String _getLocalChangelogNotes() {
    final missedVersions = _getMissedVersions();
    
    if (missedVersions.isEmpty) {
      return 'Bug fixes and performance improvements\n\nCheck the What\'s New screen in the app for detailed information.';
    }
    
    if (missedVersions.length == 1) {
      // Single version - use existing format
      final version = missedVersions.first;
      final versionChanges = changelogData[version];
      
      if (versionChanges == null || versionChanges.isEmpty) {
        return 'Bug fixes and performance improvements\n\nCheck the What\'s New screen in the app for detailed information.';
      }
      
      final formattedEntries = versionChanges.map((entry) {
        final title = entry['title'] ?? 'Update';
        final description = entry['description'] ?? '';
        
        if (description.isNotEmpty) {
          return '• $title\n  $description';
        } else {
          return '• $title';
        }
      }).join('\n\n');
      
      return formattedEntries;
    }
    
    // Multiple versions - aggregate format
    final buffer = StringBuffer();
    if (missedVersions.length == 2) {
      buffer.writeln('Updates since your last version (${missedVersions.length} versions):\n');
    } else {
      buffer.writeln('Updates since your last version (${missedVersions.length} versions):\n');
    }
    
    for (int i = 0; i < missedVersions.length; i++) {
      final version = missedVersions[i];
      final versionChanges = changelogData[version] ?? [];
      
      if (versionChanges.isNotEmpty) {
        buffer.writeln('VERSION $version');
        for (final change in versionChanges) {
          final title = change['title'] ?? 'Update';
          buffer.writeln('• $title');
        }
        
        // Add spacing between versions, but not after the last one
        if (i < missedVersions.length - 1) {
          buffer.writeln();
        }
      }
    }
    
    return buffer.toString();
  }
} 