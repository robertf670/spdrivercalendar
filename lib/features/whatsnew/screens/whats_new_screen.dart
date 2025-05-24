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
  bool _isLoading = true;

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

  Future<void> _updateLastSeenVersion() async {
    await StorageService.saveString(AppConstants.lastSeenVersionKey, _currentVersion);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('What\'s New'),
        elevation: 0,
      ),
      body: _isLoading
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
                          'Version $_currentVersion',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'We\'ve made some updates to improve your experience:',
                          style: TextStyle(
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
    );
  }

  List<Widget> _buildChangelogItems() {
    // Find the changelog for the current version
    final List<Map<String, String>> versionChanges = changelogData[_currentVersion] ?? [];
    
    // If no changelog for this specific version, show a default message
    if (versionChanges.isEmpty) {
      return [
        _buildChangeItem(
          'General Improvements',
          'Various bug fixes and performance improvements',
        ),
      ];
    }

    // Otherwise, show the specific changes for this version
    return versionChanges.map((item) {
      return _buildChangeItem(item['title'] ?? 'No Title', item['description'] ?? '');
    }).toList();
  }

  Widget _buildChangeItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        ),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.star, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 