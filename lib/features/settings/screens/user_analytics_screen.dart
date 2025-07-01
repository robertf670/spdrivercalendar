import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../main.dart';
import '../../../services/user_activity_service.dart';

class UserAnalyticsScreen extends StatefulWidget {
  const UserAnalyticsScreen({Key? key}) : super(key: key);

  @override
  UserAnalyticsScreenState createState() => UserAnalyticsScreenState();
}

class UserAnalyticsScreenState extends State<UserAnalyticsScreen> {
  Map<String, int>? _analyticsStats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalyticsStats();
    // Log analytics event for admin viewing analytics
    analytics.logEvent(
      name: 'admin_view_analytics',
      parameters: {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  Future<void> _loadAnalyticsStats() async {
    try {
      final stats = await UserActivityService.getAnalyticsStats();
      if (mounted) {
        setState(() {
          _analyticsStats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _analyticsStats = {'activeToday': 0, 'activeThisWeek': 0};
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Analytics'),
        elevation: 0,
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.analytics,
                              color: Colors.green.shade600,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'User Analytics',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Track app usage and user engagement anonymously',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Status card
                _buildStatusCard(),
                const SizedBox(height: 16),
                
                // Quick stats with real data
                _buildQuickStatsCard(),
                const SizedBox(height: 16),
                
                // Actions
                Expanded(
                  child: Column(
                    children: [
                      _buildActionCard(
                        title: 'View Full Analytics Dashboard',
                        subtitle: 'Open Firebase Console for detailed insights',
                        icon: Icons.dashboard,
                        color: Colors.blue,
                        onTap: _openFirebaseConsole,
                      ),
                      const SizedBox(height: 12),
                      _buildActionCard(
                        title: 'Privacy Information',
                        subtitle: 'How user data is collected and protected',
                        icon: Icons.privacy_tip,
                        color: Colors.orange,
                        onTap: _showPrivacyInfo,
                      ),
                      const SizedBox(height: 12),
                      _buildActionCard(
                        title: 'Test Analytics Event',
                        subtitle: 'Send a test event to verify analytics',
                        icon: Icons.bug_report,
                        color: Colors.purple,
                        onTap: _sendTestEvent,
                      ),
                      const SizedBox(height: 12),
                      _buildActionCard(
                        title: 'Refresh Stats',
                        subtitle: 'Reload current analytics data',
                        icon: Icons.refresh,
                        color: Colors.teal,
                        onTap: _refreshStats,
                      ),
                      const SizedBox(height: 12),
                      _buildActionCard(
                        title: 'Clear Analytics Data',
                        subtitle: 'Reset all analytics data (for testing)',
                        icon: Icons.clear_all,
                        color: Colors.red,
                        onTap: _clearAnalyticsData,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Analytics Active',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'User analytics are being collected anonymously',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
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

  Widget _buildQuickStatsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Quick Stats',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                if (_isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Active Today',
                    _isLoading 
                        ? '...' 
                        : '${_analyticsStats?['activeToday'] ?? 0}',
                    Icons.today,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'This Week',
                    _isLoading 
                        ? '...' 
                        : '${_analyticsStats?['activeThisWeek'] ?? 0}',
                    Icons.calendar_view_week,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _isLoading 
                  ? 'Loading real-time analytics data...'
                  : 'Real-time data from Firestore analytics tracking',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade400,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _refreshStats() async {
    setState(() {
      _isLoading = true;
    });
    await _loadAnalyticsStats();
  }

  void _clearAnalyticsData() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Clear Analytics Data'),
          ],
        ),
        content: const Text(
          'This will permanently delete all analytics data for testing purposes. Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear Data'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await UserActivityService.clearAllData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Analytics data cleared successfully'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          // Refresh stats to show the cleared data
          _refreshStats();
        }
      } catch (e) {
        if (mounted) {
          _showErrorDialog('Error', 'Failed to clear analytics data: $e');
        }
      }
    }
  }

  void _openFirebaseConsole() async {
    // Your actual Firebase project ID from google-services.json
    const firebaseProjectId = 'spdrivercalendar';
    final url = 'https://console.firebase.google.com/project/$firebaseProjectId/analytics';
    
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        
        // Log analytics event
        analytics.logEvent(
          name: 'admin_open_firebase_console',
          parameters: {
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          },
        );
      } else {
        _showErrorDialog('Cannot open Firebase Console', 'Please visit the URL manually:\n$url');
      }
    } catch (e) {
      _showErrorDialog('Error', 'Failed to open Firebase Console: $e');
    }
  }

  void _showPrivacyInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.privacy_tip, color: Colors.orange),
            SizedBox(width: 8),
            Text('Privacy Information'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Firebase Analytics Privacy:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('• No personal information is collected'),
              const Text('• Anonymous user IDs are generated automatically'),
              const Text('• Users can opt out of analytics'),
              const Text('• Data is aggregated and anonymized'),
              const Text('• GDPR compliant'),
              const SizedBox(height: 16),
              const Text(
                'Data Collected:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('• App launches and sessions'),
              const Text('• Screen views and navigation patterns'),
              const Text('• Device type and OS version'),
              const Text('• Geographic region (country level)'),
              const Text('• App crashes (for debugging)'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _sendTestEvent() async {
    try {
      await analytics.logEvent(
        name: 'admin_test_event',
        parameters: {
          'test_parameter': 'analytics_working',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'admin_user': 'true',
        },
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Test event sent successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error', 'Failed to send test event: $e');
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
} 