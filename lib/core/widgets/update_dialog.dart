import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:spdrivercalendar/services/update_service.dart';
import 'package:spdrivercalendar/core/constants/changelog_data.dart';

class UpdateDialog extends StatefulWidget {
  final UpdateInfo updateInfo;

  const UpdateDialog({Key? key, required this.updateInfo}) : super(key: key);

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  String? _currentVersion;

  @override
  void initState() {
    super.initState();
    _loadCurrentVersion();
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
              Icons.system_update,
              color: theme.colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Update Available',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Version info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.new_releases,
                    color: theme.colorScheme.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                                  Text(
                  'Version ${widget.updateInfo.latestVersion}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // What's new section
            Text(
              'What\'s New:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            
            // Release notes
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
        ),
      ),
      actions: [
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
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            UpdateService.downloadUpdate(widget.updateInfo.downloadUrl);
          },
          child: const Text('Download'),
        ),
      ],
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
    buffer.writeln('Updates since your last version (${missedVersions.length} versions):\n');
    
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