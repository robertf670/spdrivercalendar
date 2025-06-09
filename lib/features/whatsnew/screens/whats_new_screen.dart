import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:spdrivercalendar/core/constants/app_constants.dart';
import 'package:spdrivercalendar/core/services/storage_service.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';
import 'package:spdrivercalendar/core/constants/changelog_data.dart';

class WhatsNewScreen extends StatefulWidget {
  final VoidCallback onContinue;

  const WhatsNewScreen({
    Key? key,
    required this.onContinue,
  }) : super(key: key);

  @override
  State<WhatsNewScreen> createState() => _WhatsNewScreenState();
}

class _WhatsNewScreenState extends State<WhatsNewScreen> {
  String _currentVersion = '';
  String? _lastSeenVersion;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final lastSeen = await StorageService.getString(AppConstants.lastSeenVersionKey);
      setState(() {
        _currentVersion = packageInfo.version;
        _lastSeenVersion = lastSeen;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _currentVersion = AppConstants.appVersion;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateLastSeenVersion() async {
    await StorageService.saveString(AppConstants.lastSeenVersionKey, _currentVersion);
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

  /// Get list of versions between last seen and current (inclusive of current)
  List<String> _getMissedVersions() {
    if (_lastSeenVersion == null) return [_currentVersion];
    
    final allVersions = changelogData.keys.toList()
      ..sort((a, b) => _compareVersions(a, b)); // Ascending order
    
    return allVersions.where((version) {
      return _compareVersions(version, _lastSeenVersion!) > 0 && 
             _compareVersions(version, _currentVersion) <= 0;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('What\'s New'),
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _buildVersionTitle(),
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _buildSubtitle(),
                            style: const TextStyle(
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ..._buildChangelogItems(),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          _updateLastSeenVersion().then((_) {
                            widget.onContinue();
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                        ),
                        child: const Text('Continue'),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  String _buildVersionTitle() {
    final missedVersions = _getMissedVersions();
    if (missedVersions.length == 1) {
      return 'Version ${missedVersions.first}';
    } else {
      return 'Updates Since Your Last Version';
    }
  }

  String _buildSubtitle() {
    final missedVersions = _getMissedVersions();
    if (missedVersions.length == 1) {
      return 'We\'ve made some updates to improve your experience:';
    } else {
      return 'We\'ve made updates across ${missedVersions.length} versions to improve your experience:';
    }
  }

  List<Widget> _buildChangelogItems() {
    final missedVersions = _getMissedVersions();
    
    if (missedVersions.isEmpty) {
      return [
        _buildChangeItem(
          'General Improvements',
          'Various bug fixes and performance improvements',
        ),
      ];
    }
    
    if (missedVersions.length == 1) {
      // Single version - use existing format
      final version = missedVersions.first;
      final versionChanges = changelogData[version] ?? [];
      
      if (versionChanges.isEmpty) {
        return [
          _buildChangeItem(
            'General Improvements',
            'Various bug fixes and performance improvements',
          ),
        ];
      }
      
      return versionChanges.map((item) {
        return _buildChangeItem(item['title'] ?? 'No Title', item['description'] ?? '');
      }).toList();
    }
    
    // Multiple versions - aggregate format
    final List<Widget> items = [];
    
    for (int i = 0; i < missedVersions.length; i++) {
      final version = missedVersions[i];
      final versionChanges = changelogData[version] ?? [];
      
      if (versionChanges.isNotEmpty) {
        // Add version header
        items.add(_buildVersionHeader(version));
        
        // Add changes for this version
        for (final change in versionChanges) {
          items.add(_buildChangeItem(
            change['title'] ?? 'Update', 
            change['description'] ?? '',
            isSubItem: true,
          ));
        }
        
        // Add spacing between versions (except after last one)
        if (i < missedVersions.length - 1) {
          items.add(const SizedBox(height: 8));
        }
      }
    }
    
    return items.isNotEmpty ? items : [
      _buildChangeItem(
        'General Improvements',
        'Various bug fixes and performance improvements',
      ),
    ];
  }

  Widget _buildVersionHeader(String version) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
        ),
        child: Text(
          'VERSION $version',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: AppTheme.primaryColor,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildChangeItem(String title, String description, {bool isSubItem = false}) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: 16.0,
        left: isSubItem ? 16.0 : 0.0,
      ),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        ),
        elevation: isSubItem ? 1 : 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isSubItem ? Icons.arrow_right : Icons.star, 
                    color: AppTheme.primaryColor,
                    size: isSubItem ? 20 : 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isSubItem ? 15 : 16,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(fontSize: isSubItem ? 13 : 14),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
} 
