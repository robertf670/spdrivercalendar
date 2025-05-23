import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:spdrivercalendar/core/constants/app_constants.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';
import 'package:spdrivercalendar/core/constants/changelog_data.dart';
import 'package:spdrivercalendar/services/update_service.dart';
import 'package:spdrivercalendar/core/widgets/update_dialog.dart';

class VersionHistoryScreen extends StatefulWidget {
  const VersionHistoryScreen({Key? key}) : super(key: key);

  @override
  State<VersionHistoryScreen> createState() => _VersionHistoryScreenState();
}

class _VersionHistoryScreenState extends State<VersionHistoryScreen> {
  String _currentVersion = '';
  bool _isLoading = true;
  bool _isCheckingUpdates = false;
  UpdateInfo? _updateInfo;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _currentVersion = packageInfo.version;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _currentVersion = AppConstants.appVersion;
        _isLoading = false;
      });
    }
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _isCheckingUpdates = true;
    });

    try {
      final updateInfo = await UpdateService.checkForUpdate(forceCheck: true);
      setState(() {
        _updateInfo = updateInfo;
        _isCheckingUpdates = false;
      });

      if (updateInfo != null && updateInfo.hasUpdate && mounted) {
        showDialog(
          context: context,
          builder: (context) => UpdateDialog(updateInfo: updateInfo),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You\'re running the latest version!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isCheckingUpdates = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to check for updates. Please try again later.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sortedVersions = changelogData.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Version History'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _isCheckingUpdates ? null : _checkForUpdates,
            icon: _isCheckingUpdates
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Check for Updates',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Update availability banner
                if (_updateInfo != null && _updateInfo!.hasUpdate)
                  _buildUpdateBanner(),
                
                // Version list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: sortedVersions.length,
                    itemBuilder: (context, index) {
                      final version = sortedVersions[index];
                      final versionChanges = changelogData[version]!;
                      final isCurrentVersion = version == _currentVersion;
                      final isLatestVersion = _updateInfo?.latestVersion == version;
                      
                      return _buildVersionCard(version, versionChanges, isCurrentVersion, isLatestVersion);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildUpdateBanner() {
    if (_updateInfo == null || !_updateInfo!.hasUpdate) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue, width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.system_update, color: Colors.blue, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Update Available',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                Text(
                  'Version ${_updateInfo!.latestVersion} is ready to download',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => UpdateDialog(updateInfo: _updateInfo!),
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionCard(String version, List<Map<String, String>> changes, bool isCurrentVersion, [bool isLatestVersion = false]) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        side: isCurrentVersion
            ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Version $version',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isCurrentVersion ? Theme.of(context).colorScheme.primary : null,
                        ),
                  ),
                ),
                Row(
                  children: [
                    if (isLatestVersion && !isCurrentVersion)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.new_releases, size: 14, color: Colors.green),
                            const SizedBox(width: 4),
                            Text(
                              'Available',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (isCurrentVersion)
                      const SizedBox(width: 8),
                    if (isCurrentVersion)
                      Chip(
                        label: const Text('Current'),
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        labelStyle: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            if (changes.isEmpty)
              const Text('No specific changes listed for this version.')
            else
              ...changes.map((change) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        change['title'] ?? 'No Title',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        change['description'] ?? '',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }
} 