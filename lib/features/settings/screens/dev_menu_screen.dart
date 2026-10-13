import 'package:flutter/material.dart';
import 'package:spdrivercalendar/features/calendar/services/event_deletion_service.dart';
import 'package:spdrivercalendar/features/calendar/services/event_service.dart';
import 'package:spdrivercalendar/services/donnybrook_feature_service.dart';
import 'package:spdrivercalendar/services/jamestown_feature_service.dart';
import 'package:spdrivercalendar/services/zone2_roster_feature_service.dart';
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
  bool _zone2RosterEnabled = false;
  bool _isRemovingRosterFills = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await Future.wait([
      JamestownFeatureService.isEnabled(),
      DonnybrookFeatureService.isEnabled(),
      Zone2RosterFeatureService.isEnabled(),
    ]);
    if (!mounted) {
      return;
    }

    setState(() {
      _jamestownEnabled = settings[0];
      _donnybrook1Enabled = settings[1];
      _zone2RosterEnabled = settings[2];
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

  Future<void> _setZone2RosterEnabled(bool enabled) async {
    await Zone2RosterFeatureService.setEnabled(enabled);
    if (!mounted) {
      return;
    }
    setState(() => _zone2RosterEnabled = enabled);
  }

  Future<void> _removeZone2RosterFills() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final width = MediaQuery.sizeOf(dialogContext).width;
        return AlertDialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: width < 350 ? 16 : 40,
          ),
          title: const Text('Remove Zone 2 roster fills?'),
          content: const Text(
            'This deletes only duties added by the 35-week Zone 2 roster fill.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isRemovingRosterFills = true);
    final events = Zone2RosterFeatureService.filledEvents(
      await EventService.getAllEvents(),
    );
    final deletion = EventDeletionService();
    for (final event in events) {
      if (!mounted) return;
      await deletion.deleteEvent(
        event: event,
        context: context,
        isMounted: () => mounted,
      );
    }
    if (!mounted) return;
    setState(() => _isRemovingRosterFills = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          events.isEmpty
              ? 'No Zone 2 roster fills to remove.'
              : 'Removed ${events.length} Zone 2 roster duties.',
        ),
      ),
    );
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
                      title: const Text('Jamestown (30hr)'),
                      subtitle: const Text('Enable 30hr contract duties'),
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
                  Card(
                    margin: EdgeInsets.symmetric(
                      vertical: screenWidth < 350 ? 2.0 : 4.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppTheme.borderRadius,
                      ),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text(Zone2RosterFeatureService.menuLabel),
                          subtitle: const Text(
                            'Fill 35 weeks of Zone 2 Shift duties from Add Work Shift',
                          ),
                          secondary: Icon(
                            Icons.calendar_view_week_outlined,
                            color: _zone2RosterEnabled
                                ? AppTheme.primaryColor
                                : null,
                          ),
                          value: _zone2RosterEnabled,
                          onChanged: _setZone2RosterEnabled,
                        ),
                        if (_zone2RosterEnabled)
                          ListTile(
                            enabled: !_isRemovingRosterFills,
                            title: Text(
                              _isRemovingRosterFills
                                  ? 'Removing…'
                                  : 'Remove filled Zone 2 roster duties',
                            ),
                            onTap: _isRemovingRosterFills
                                ? null
                                : _removeZone2RosterFills,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
