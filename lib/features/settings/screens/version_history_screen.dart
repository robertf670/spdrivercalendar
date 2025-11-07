import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:spdrivercalendar/core/constants/app_constants.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';
import 'package:spdrivercalendar/core/constants/changelog_data.dart';
import 'package:spdrivercalendar/services/update_service.dart';
import 'package:spdrivercalendar/core/widgets/enhanced_update_dialog.dart';

class VersionHistoryScreen extends StatefulWidget {
  const VersionHistoryScreen({super.key});

  @override
  State<VersionHistoryScreen> createState() => _VersionHistoryScreenState();
}

class _VersionHistoryScreenState extends State<VersionHistoryScreen> {
  String _currentVersion = '';
  bool _isLoading = true;
  bool _isCheckingUpdates = false;
  UpdateInfo? _updateInfo;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
          builder: (context) => EnhancedUpdateDialog(updateInfo: updateInfo),
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

  // Responsive sizing helper method
  Map<String, double> _getResponsiveSizes(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Very small screens (narrow phones)
    if (screenWidth < 350) {
      return {
        'padding': 8.0,              // Reduced from 16
        'cardPadding': 12.0,          // Reduced from 16
        'cardMargin': 12.0,          // Reduced from 16
        'bannerPadding': 12.0,       // Reduced from 16
        'bannerMargin': 8.0,          // Reduced from 16
        'spacing': 8.0,              // Reduced from 12
      };
    }
    // Small phones (like older iPhones)
    else if (screenWidth < 400) {
      return {
        'padding': 10.0,
        'cardPadding': 14.0,
        'cardMargin': 14.0,
        'bannerPadding': 14.0,
        'bannerMargin': 10.0,
        'spacing': 10.0,
      };
    }
    // Mid-range phones (like Galaxy S23)
    else if (screenWidth < 450) {
      return {
        'padding': 12.0,
        'cardPadding': 15.0,
        'cardMargin': 15.0,
        'bannerPadding': 15.0,
        'bannerMargin': 12.0,
        'spacing': 11.0,
      };
    }
    // Regular phones and larger
    else {
      return {
        'padding': 16.0,             // Original size
        'cardPadding': 16.0,         // Original size
        'cardMargin': 16.0,         // Original size
        'bannerPadding': 16.0,      // Original size
        'bannerMargin': 16.0,       // Original size
        'spacing': 12.0,            // Original size
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final sortedVersions = changelogData.keys.toList()
      ..sort((a, b) => _compareVersions(b, a));
    final sizes = _getResponsiveSizes(context);

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
                  _buildUpdateBanner(sizes),
                
                // Version list
                Expanded(
                  child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    thickness: 6,
                    radius: const Radius.circular(3),
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.all(sizes['padding']!),
                      itemCount: sortedVersions.length,
                      itemBuilder: (context, index) {
                      final version = sortedVersions[index];
                      final versionChanges = changelogData[version]!;
                      final isCurrentVersion = version == _currentVersion;
                      final isLatestVersion = _updateInfo?.latestVersion == version;
                      
                      return _buildVersionCard(version, versionChanges, isCurrentVersion, isLatestVersion, sizes);
                    },
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildUpdateBanner(Map<String, double> sizes) {
    if (_updateInfo == null || !_updateInfo!.hasUpdate) return const SizedBox.shrink();
    
    return Container(
      margin: EdgeInsets.all(sizes['bannerMargin']!),
      padding: EdgeInsets.all(sizes['bannerPadding']!),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
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
                builder: (context) => EnhancedUpdateDialog(updateInfo: _updateInfo!),
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionCard(String version, List<Map<String, String>> changes, bool isCurrentVersion, [bool isLatestVersion = false, Map<String, double>? sizes]) {
    final cardSizes = sizes ?? _getResponsiveSizes(context);
    
    return Card(
      margin: EdgeInsets.only(bottom: cardSizes['cardMargin']!),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        side: isCurrentVersion
            ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: EdgeInsets.all(cardSizes['cardPadding']!),
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
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.new_releases, size: 14, color: Colors.green),
                            SizedBox(width: 4),
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
            SizedBox(height: cardSizes['spacing']!),
            if (changes.isEmpty)
              const Text('No specific changes listed for this version.')
            else
              ...changes.map((change) {
                return Padding(
                  padding: EdgeInsets.only(bottom: cardSizes['spacing']! * 0.67),
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
              }),
          ],
        ),
      ),
    );
  }

  int _compareVersions(String version1, String version2) {
    try {
      final v1Parts = version1.split('.').map(int.parse).toList();
      final v2Parts = version2.split('.').map(int.parse).toList();
      
      // Ensure both have same number of parts
      while (v1Parts.length < v2Parts.length) {
        v1Parts.add(0);
      }
      while (v2Parts.length < v1Parts.length) {
        v2Parts.add(0);
      }
      
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
} 
