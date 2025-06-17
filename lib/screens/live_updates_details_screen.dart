import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/live_update.dart';
import '../services/live_updates_service.dart';
import '../services/user_preferences_service.dart';
import '../features/settings/screens/live_updates_preferences_screen.dart';
import '../theme/app_theme.dart';

class LiveUpdatesDetailsScreen extends StatefulWidget {
  const LiveUpdatesDetailsScreen({Key? key}) : super(key: key);

  @override
  LiveUpdatesDetailsScreenState createState() => LiveUpdatesDetailsScreenState();
}

class LiveUpdatesDetailsScreenState extends State<LiveUpdatesDetailsScreen> {
  List<String> _preferredRoutes = [];
  bool _showAllUpdates = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final routes = await UserPreferencesService.getPreferredRoutes();
    final showAll = await UserPreferencesService.getShowAllUpdates();
    setState(() {
      _preferredRoutes = routes;
      _showAllUpdates = showAll;
    });
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'info':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical':
        return Icons.error;
      case 'warning':
        return Icons.warning;
      case 'info':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  String _formatTimeRange(DateTime start, DateTime end) {
    final now = DateTime.now();
    final dateFormat = DateFormat('MMM d');
    final timeFormat = DateFormat('HH:mm');
    
    // If both dates are today
    if (start.day == now.day && start.month == now.month && start.year == now.year &&
        end.day == now.day && end.month == now.month && end.year == now.year) {
      return '${timeFormat.format(start)} - ${timeFormat.format(end)} today';
    }
    
    // If start is today
    if (start.day == now.day && start.month == now.month && start.year == now.year) {
      return 'Started ${timeFormat.format(start)} today, ends ${dateFormat.format(end)} ${timeFormat.format(end)}';
    }
    
    // If end is today
    if (end.day == now.day && end.month == now.month && end.year == now.year) {
      return 'Started ${dateFormat.format(start)} ${timeFormat.format(start)}, ends ${timeFormat.format(end)} today';
    }
    
    // Different days
    return '${dateFormat.format(start)} ${timeFormat.format(start)} - ${dateFormat.format(end)} ${timeFormat.format(end)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Updates'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LiveUpdatesPreferencesScreen(),
                ),
              ).then((_) => _loadPreferences()); // Reload preferences when returning
            },
            icon: const Icon(Icons.tune),
            tooltip: 'Preferences',
          ),
        ],
      ),
      body: StreamBuilder<List<LiveUpdate>>(
        stream: _showAllUpdates 
          ? LiveUpdatesService.getActiveUpdatesStream()
          : LiveUpdatesService.getRelevantUpdatesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading updates',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final updates = snapshot.data ?? [];
          final activeUpdates = updates.where((update) => update.isActive).toList();

          return Column(
            children: [
              // Preference status banner
              if (!_showAllUpdates && _preferredRoutes.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: Colors.amber.shade50,
                  child: Row(
                    children: [
                      Icon(Icons.filter_list, color: Colors.amber.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Filtered for your preferred routes (${_preferredRoutes.length} routes)',
                          style: TextStyle(
                            color: Colors.amber.shade700,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          await UserPreferencesService.setShowAllUpdates(true);
                          _loadPreferences();
                        },
                        child: Text(
                          'Show All',
                          style: TextStyle(
                            color: Colors.amber.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Updates list
              Expanded(
                child: _buildUpdatesList(activeUpdates),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUpdatesList(List<LiveUpdate> activeUpdates) {
    if (activeUpdates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.green.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No Active Updates',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _showAllUpdates 
                ? 'All clear! No diversions or service updates at this time.'
                : 'No updates for your preferred routes. Tap "Show All" to see all updates.',
              style: TextStyle(
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activeUpdates.length,
      itemBuilder: (context, index) {
        final update = activeUpdates[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: _getPriorityColor(update.priority).withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  _getPriorityColor(update.priority).withValues(alpha: 0.05),
                  Colors.white,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with priority icon and indicator
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getPriorityColor(update.priority).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getPriorityIcon(update.priority),
                          color: _getPriorityColor(update.priority),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              update.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _getPriorityColor(update.priority).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    update.priority.toUpperCase(),
                                    style: TextStyle(
                                      color: _getPriorityColor(update.priority),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.live_tv,
                                        size: 10,
                                        color: Colors.green.shade700,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        'ACTIVE',
                                        style: TextStyle(
                                          color: Colors.green.shade700,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Description
                  Text(
                    update.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Time information
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _formatTimeRange(update.startTime, update.endTime),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Routes affected (if any)
                  if (update.routesAffected.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Routes Affected:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: update.routesAffected.map((route) {
                            final isPreferred = _preferredRoutes.any((preferred) => 
                              route.toLowerCase().contains(preferred.toLowerCase()) ||
                              preferred.toLowerCase().contains(route.toLowerCase())
                            );
                            
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isPreferred 
                                  ? Colors.amber.withValues(alpha: 0.2)
                                  : AppTheme.primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isPreferred 
                                    ? Colors.amber.withValues(alpha: 0.6)
                                    : AppTheme.primaryColor.withValues(alpha: 0.3),
                                  width: isPreferred ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isPreferred) ...[
                                    Icon(
                                      Icons.star,
                                      size: 12,
                                      color: Colors.amber.shade700,
                                    ),
                                    const SizedBox(width: 3),
                                  ],
                                  Text(
                                    route,
                                    style: TextStyle(
                                      color: isPreferred 
                                        ? Colors.amber.shade700
                                        : AppTheme.primaryColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}