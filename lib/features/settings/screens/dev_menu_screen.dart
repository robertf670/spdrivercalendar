import 'package:flutter/material.dart';
import 'package:spdrivercalendar/services/donnybrook_feature_service.dart';
import 'package:spdrivercalendar/services/jamestown_feature_service.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';

class DevMenuScreen extends StatefulWidget {
  const DevMenuScreen({super.key});

  @override
  State<DevMenuScreen> createState() => _DevMenuScreenState();
}

class _DevMenuScreenState extends State<DevMenuScreen> {
  bool _isLoading = true;
  bool _jamestownEnabled = false;
  bool _donnybrook1Enabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await Future.wait([
      JamestownFeatureService.isEnabled(),
      DonnybrookFeatureService.isEnabled(),
    ]);
    if (!mounted) {
      return;
    }

    setState(() {
      _jamestownEnabled = settings[0];
      _donnybrook1Enabled = settings[1];
      _isLoading = false;
    });
  }

  Future<void> _setJamestownEnabled(bool enabled) async {
    await JamestownFeatureService.setEnabled(enabled);
    if (!mounted) {
      return;
    }

    setState(() {
      _jamestownEnabled = enabled;
      if (enabled) {
        _donnybrook1Enabled = false;
      }
    });
  }

  Future<void> _setDonnybrook1Enabled(bool enabled) async {
    await DonnybrookFeatureService.setEnabled(enabled);
    if (!mounted) {
      return;
    }

    setState(() {
      _donnybrook1Enabled = enabled;
      if (enabled) {
        _jamestownEnabled = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = screenWidth < 350
        ? 8.0
        : screenWidth < 450
            ? 12.0
            : screenWidth < 600
                ? 16.0
                : screenWidth < 900
                    ? 24.0
                    : screenWidth * 0.2;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dev Menu'),
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: screenWidth < 350 ? 8.0 : 16.0,
                ),
                children: [
                  Card(
                    margin: EdgeInsets.symmetric(
                      vertical: screenWidth < 350 ? 2.0 : 4.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppTheme.borderRadius,
                      ),
                    ),
                    child: SwitchListTile(
                      title: const Text('Jamestown'),
                      subtitle: const Text('Enable Jamestown duties'),
                      secondary: Icon(
                        Icons.location_on_outlined,
                        color: _jamestownEnabled
                            ? AppTheme.primaryColor
                            : null,
                      ),
                      value: _jamestownEnabled,
                      onChanged: _setJamestownEnabled,
                    ),
                  ),
                  Card(
                    margin: EdgeInsets.symmetric(
                      vertical: screenWidth < 350 ? 2.0 : 4.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppTheme.borderRadius,
                      ),
                    ),
                    child: SwitchListTile(
                      title: const Text(DonnybrookFeatureService.menuLabel),
                      subtitle: const Text('Enable DB Z1 duties'),
                      secondary: Icon(
                        Icons.directions_bus_outlined,
                        color: _donnybrook1Enabled
                            ? AppTheme.primaryColor
                            : null,
                      ),
                      value: _donnybrook1Enabled,
                      onChanged: _setDonnybrook1Enabled,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
