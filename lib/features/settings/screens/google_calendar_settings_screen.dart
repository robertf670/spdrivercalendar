import 'package:flutter/material.dart';
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
    bool hasAccess = false;
    if (isSignedIn) {
      hasAccess = await GoogleCalendarService.testConnection();
    }
    
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
                // Add disclaimer about Google Calendar access
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                  child: Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Google Calendar access requires test user approval. Please use the feedback section to request access with your email address.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _buildStatusCard(),
              ],
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
                      backgroundColor: _isConnected ? AppTheme.successColor.withValues(alpha: 0.2) : AppTheme.errorColor.withValues(alpha: 0.2),
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
                            final account = await GoogleCalendarService.signInWithGoogle();
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


}
