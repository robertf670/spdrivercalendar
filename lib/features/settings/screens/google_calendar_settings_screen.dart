import 'package:flutter/material.dart';
import 'package:spdrivercalendar/calendar_test_helper.dart';
import 'package:spdrivercalendar/google_calendar_service.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';

class GoogleCalendarSettingsScreen extends StatefulWidget {
  const GoogleCalendarSettingsScreen({super.key});

  @override
  _GoogleCalendarSettingsScreenState createState() => _GoogleCalendarSettingsScreenState();
}

class _GoogleCalendarSettingsScreenState extends State<GoogleCalendarSettingsScreen> {
  bool _isConnected = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkConnectionStatus();
  }

  Future<void> _checkConnectionStatus() async {
    setState(() {
      _isLoading = true;
    });
    
    final isSignedIn = await GoogleCalendarService.isSignedIn();
    final hasAccess = isSignedIn ? await GoogleCalendarService.checkCalendarAccess() : false;
    
    setState(() {
      _isConnected = isSignedIn && hasAccess;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Calendar Settings'),
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusCard(),
                const SizedBox(height: 24),
                _buildSectionHeader('Test Actions'),
                _buildTestCard(),
              ],
            ),
          ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      elevation: 2,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isConnected ? AppTheme.successColor : AppTheme.errorColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppTheme.borderRadius),
                topRight: Radius.circular(AppTheme.borderRadius),
              ),
            ),
            child: Text(
              _isConnected ? 'Connected' : 'Not Connected',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: _isConnected ? AppTheme.successColor.withOpacity(0.2) : AppTheme.errorColor.withOpacity(0.2),
                      child: Icon(
                        _isConnected ? Icons.check : Icons.error_outline,
                        color: _isConnected ? AppTheme.successColor : AppTheme.errorColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Google Calendar',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            _isConnected 
                                ? 'Your account is connected and working properly'
                                : 'Your account is not connected or has issues',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isConnected
                        ? () async {
                            await GoogleCalendarService.signOut();
                            await _checkConnectionStatus();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Disconnected from Google Calendar'))
                            );
                          }
                        : () async {
                            final account = await GoogleCalendarService.signIn();
                            await _checkConnectionStatus();
                            if (account != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Connected to Google Calendar'))
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isConnected ? Colors.redAccent : AppTheme.primaryColor,
                    ),
                    child: Text(_isConnected ? 'Disconnect' : 'Connect'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius / 2),
                ),
                child: const Icon(Icons.add_box, color: AppTheme.primaryColor),
              ),
              title: const Text('Add Test Event'),
              subtitle: const Text('Create a sample event in your Google Calendar'),
              trailing: const Icon(Icons.chevron_right),
              enabled: _isConnected,
              onTap: _isConnected
                  ? () async {
                      await CalendarTestHelper.addTestEvent(context);
                    }
                  : null,
            ),
            const Divider(),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius / 2),
                ),
                child: const Icon(Icons.list, color: AppTheme.secondaryColor),
              ),
              title: const Text('View Recent Events'),
              subtitle: const Text('Fetch your recent calendar events'),
              trailing: const Icon(Icons.chevron_right),
              enabled: _isConnected,
              onTap: _isConnected
                  ? () async {
                      final events = await CalendarTestHelper.fetchRecentEvents(context);
                      if (!mounted) return;
                      
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Recent Events (${events.length})'),
                          content: SizedBox(
                            width: double.maxFinite,
                            height: 300,
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: events.length,
                              itemBuilder: (context, index) {
                                final event = events[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  child: ListTile(
                                    title: Text(event.summary ?? 'No title'),
                                    subtitle: Text(event.start?.dateTime?.toString().substring(0, 16) ?? 'No start time'),
                                    leading: const Icon(Icons.event, color: AppTheme.primaryColor),
                                  ),
                                );
                              },
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
