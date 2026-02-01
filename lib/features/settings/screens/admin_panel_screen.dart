import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';
import '../../../models/live_update.dart';
import '../../../services/live_updates_service.dart';
import 'package:http/http.dart' as http;

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  AdminPanelScreenState createState() => AdminPanelScreenState();
}

class AdminPanelScreenState extends State<AdminPanelScreen> {
  final bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel - Live Updates'),
        elevation: 0,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Admin warning banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: theme.colorScheme.errorContainer,
                  child: Row(
                    children: [
                      Icon(
                        Icons.admin_panel_settings, 
                        color: theme.colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Admin Mode - Changes will be visible to all app users',
                          style: TextStyle(
                            color: theme.colorScheme.onErrorContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Updates list
                Expanded(
                  child: StreamBuilder<List<LiveUpdate>>(
                    stream: LiveUpdatesService.getUpdatesOnlyStream(),
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
                                color: theme.colorScheme.error,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Error loading updates: ${snapshot.error}',
                                style: TextStyle(color: theme.colorScheme.error),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      final updates = snapshot.data ?? [];
                      
                      if (updates.isEmpty) {
                        return _buildEmptyState();
                      }
                      
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: updates.length,
                        itemBuilder: (context, index) => _buildUpdateCard(updates[index]),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'addUpdate',
        onPressed: _showAddUpdateDialog,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        icon: const Icon(Icons.add),
        label: const Text('Add Update'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.grey.shade50,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _createDemoUpdate,
                icon: const Icon(Icons.science),
                label: const Text('Create Demo Update'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.campaign_outlined,
            size: 64,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No live updates yet',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first update to keep users informed',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateCard(LiveUpdate update) {
    final now = DateTime.now();
    final isExpired = now.isAfter(update.endTime);
    final isInTimeWindow = now.isAfter(update.startTime) && now.isBefore(update.endTime);
    final isForceVisible = update.forceVisible && !isExpired;

    Color statusColor;
    String statusText;
    IconData statusIcon;
    Widget? additionalBadge;

    if (isExpired) {
      statusColor = Colors.grey;
      statusText = 'Expired';
      statusIcon = Icons.history;
    } else if (update.isActive) {
      statusColor = Colors.green;
      statusText = 'Active';
      statusIcon = Icons.live_tv;
      
      // Add indicators for special states
      if (isForceVisible && !isInTimeWindow) {
        additionalBadge = Container(
          margin: const EdgeInsets.only(left: 4),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.purple.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.visibility, size: 10, color: Colors.purple),
              const SizedBox(width: 2),
              Text(
                'FORCED',
                style: TextStyle(
                  color: Colors.purple,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      } else if (update.isScheduledForEarlyVisibility) {
        additionalBadge = Container(
          margin: const EdgeInsets.only(left: 4),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.schedule, size: 10, color: Colors.blue),
              const SizedBox(width: 2),
              Text(
                'EARLY',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      } else if (update.enableScheduledVisibility && update.hoursBeforeStart > 0) {
        additionalBadge = Container(
          margin: const EdgeInsets.only(left: 4),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.schedule, size: 10, color: Colors.orange),
              const SizedBox(width: 2),
              Text(
                '${update.hoursBeforeStart}H',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }
    } else {
      statusColor = Colors.orange;
      statusText = 'Scheduled';
      statusIcon = Icons.schedule;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: statusColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status and actions
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Force visible badge if applicable
                if (additionalBadge != null) additionalBadge,
                const Spacer(),
                // Priority indicator (only for updates)
                if (!update.isPoll)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(update.priority).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      update.priority.toUpperCase(),
                      style: TextStyle(
                        color: _getPriorityColor(update.priority),
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _showEditUpdateDialog(update);
                        break;
                      case 'delete':
                        _confirmDelete(update);
                        break;
                      case 'end_now':
                        _endUpdateNow(update);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    if (update.isActive)
                      const PopupMenuItem(
                        value: 'end_now',
                        child: Row(
                          children: [
                            Icon(Icons.stop, size: 18),
                            SizedBox(width: 8),
                            Text('End Now'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Title
            Text(
              update.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            // Description
            Text(
              update.description,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            // Time info
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      '${DateFormat('MMM d, HH:mm').format(update.startTime)} - ${DateFormat('MMM d, HH:mm').format(update.endTime)}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                if (update.enableScheduledVisibility && update.hoursBeforeStart > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.visibility, size: 16, color: Colors.blue.shade600),
                      const SizedBox(width: 4),
                      Text(
                        'Visible from ${DateFormat('MMM d, HH:mm').format(update.effectiveStartTime)}',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            // Routes affected (if any) - only for updates
            if (!update.isPoll && update.routesAffected.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children: update.routesAffected.map((route) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    route,
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Poll card removed - polls are now managed in PollManagementScreen

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

  void _showAddUpdateDialog() {
    _showUpdateDialog();
  }

  void _showEditUpdateDialog(LiveUpdate update) {
    _showUpdateDialog(existingUpdate: update);
  }

  void _showUpdateDialog({LiveUpdate? existingUpdate}) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (context) => UpdateDialog(
        existingUpdate: existingUpdate,
        onSave: (update) async {
          try {
            if (existingUpdate != null) {
              await LiveUpdatesService.updateUpdate(update);
              if (mounted) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Update saved successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } else {
              await LiveUpdatesService.addUpdate(update);
              if (mounted) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Update created successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            }
          } catch (e) {
            if (mounted) {
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text('Error: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  // Reset votes method removed - polls are now managed in PollManagementScreen

  void _confirmDelete(LiveUpdate update) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Update'),
        content: Text('Are you sure you want to delete "${update.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await LiveUpdatesService.deleteUpdate(update.id);
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Update "${update.title}" deleted'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Error deleting update: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _endUpdateNow(LiveUpdate update) async {
    try {
      await LiveUpdatesService.endUpdateNow(update.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Update "${update.title}" ended'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error ending update: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _createDemoUpdate() async {
    try {
      final demoUpdate = LiveUpdate(
        id: '', // Will be generated by Firebase
        title: 'Route C1 Service Update',
        description: 'Minor delays expected on Route C1 due to traffic congestion on Parnell Street. Please allow extra travel time.',
        priority: 'warning',
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(hours: 2)),
        routesAffected: ['C1', 'C2'], // User's preferred routes!
      );
      
      await LiveUpdatesService.addUpdate(demoUpdate);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demo update created! Check the calendar banner and Live Updates.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating demo update: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Dialog for creating/editing updates
class UpdateDialog extends StatefulWidget {
  final LiveUpdate? existingUpdate;
  final Function(LiveUpdate) onSave;

  const UpdateDialog({
    super.key,
    this.existingUpdate,
    required this.onSave,
  });

  @override
  UpdateDialogState createState() => UpdateDialogState();
}

class UpdateDialogState extends State<UpdateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _routesController = TextEditingController();
  
  String _priority = 'info';
  DateTime _startTime = DateTime.now();
  DateTime _endTime = DateTime.now().add(const Duration(hours: 2));
  bool _forceVisible = false;
  bool _enableScheduledVisibility = true;
  int _hoursBeforeStart = 2;

  @override
  void initState() {
    super.initState();
    if (widget.existingUpdate != null) {
      final update = widget.existingUpdate!;
      _titleController.text = update.title;
      _descriptionController.text = update.description;
      _routesController.text = update.routesAffected.join(', ');
      _priority = update.priority;
      _startTime = update.startTime;
      _endTime = update.endTime;
      _forceVisible = update.forceVisible;
      _enableScheduledVisibility = update.enableScheduledVisibility;
      _hoursBeforeStart = update.hoursBeforeStart;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.edit, color: theme.colorScheme.onPrimary),
                  const SizedBox(width: 8),
                  Text(
                    widget.existingUpdate != null ? 'Edit Update' : 'Add New Update',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: theme.colorScheme.onPrimary),
                  ),
                ],
              ),
            ),
            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // URL Field for auto-filling
                      TextFormField(
                        controller: _urlController,
                        decoration: InputDecoration(
                          labelText: 'Paste URL (Optional)',
                          hintText: 'Paste Dublin Bus or news URL to auto-fill details',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            onPressed: _parseUrl,
                            icon: const Icon(Icons.auto_fix_high),
                            tooltip: 'Parse URL',
                          ),
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty && (value.contains('dublinbus.ie') || value.contains('http'))) {
                            _parseUrl();
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          hintText: 'e.g., Route 9 Diversion',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Title is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'e.g., Diverted via Nassau St due to gas leak',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Description is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _priority,
                        decoration: const InputDecoration(
                          labelText: 'Priority',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'info', child: Text('Info')),
                          DropdownMenuItem(value: 'warning', child: Text('Warning')),
                          DropdownMenuItem(value: 'critical', child: Text('Critical')),
                        ],
                        onChanged: (value) => setState(() => _priority = value!),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _routesController,
                        decoration: const InputDecoration(
                          labelText: 'Routes Affected (optional)',
                          hintText: 'e.g., Route 9, Route 122',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Force Visible Toggle
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.colorScheme.outline),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: SwitchListTile(
                          title: const Text('Force Visible'),
                          subtitle: const Text(
                            'Show immediately regardless of start time (still respects end time)',
                            style: TextStyle(fontSize: 12),
                          ),
                          value: _forceVisible,
                          onChanged: (bool value) {
                            setState(() {
                              _forceVisible = value;
                              // Disable scheduled visibility if force visible is enabled
                              if (value) {
                                _enableScheduledVisibility = false;
                              }
                            });
                          },
                          secondary: Icon(
                            _forceVisible ? Icons.visibility : Icons.visibility_off,
                            color: _forceVisible ? Colors.green : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Scheduled Visibility Toggle
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.colorScheme.outline),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          children: [
                            SwitchListTile(
                              title: const Text('Scheduled Visibility'),
                              subtitle: Text(
                                _enableScheduledVisibility
                                    ? 'Update will become visible $_hoursBeforeStart hour${_hoursBeforeStart == 1 ? '' : 's'} before start time'
                                    : 'Display update at a scheduled time before start time',
                                style: const TextStyle(fontSize: 12),
                              ),
                              value: _enableScheduledVisibility,
                              onChanged: _forceVisible ? null : (bool value) {
                                setState(() {
                                  _enableScheduledVisibility = value;
                                });
                              },
                              secondary: Icon(
                                _enableScheduledVisibility ? Icons.schedule : Icons.schedule_outlined,
                                color: _enableScheduledVisibility && !_forceVisible ? Colors.blue : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                            if (_enableScheduledVisibility && !_forceVisible) ...[
                              const Divider(height: 1),
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Hours before start time:',
                                      style: TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      children: [
                                        for (int hours in [1, 2, 4, 8])
                                          ChoiceChip(
                                            label: Text('${hours}h'),
                                            selected: _hoursBeforeStart == hours,
                                            onSelected: (selected) {
                                              if (selected) {
                                                setState(() {
                                                  _hoursBeforeStart = hours;
                                                });
                                              }
                                            },
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    if (_enableScheduledVisibility) ...[
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.info_outline, size: 16, color: Colors.blue.shade600),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Will become visible at ${DateFormat('MMM d, HH:mm').format(_startTime.subtract(Duration(hours: _hoursBeforeStart)))}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.blue.shade700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Start time
                      ListTile(
                        title: const Text('Start Time'),
                        subtitle: Text(DateFormat('MMM d, yyyy HH:mm').format(_startTime)),
                        trailing: const Icon(Icons.schedule),
                        onTap: () => _selectDateTime(true),
                      ),
                      // End time
                      ListTile(
                        title: const Text('End Time'),
                        subtitle: Text(DateFormat('MMM d, yyyy HH:mm').format(_endTime)),
                        trailing: const Icon(Icons.schedule),
                        onTap: () => _selectDateTime(false),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _saveUpdate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(widget.existingUpdate != null ? 'Update' : 'Create'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDateTime(bool isStartTime) async {
    final currentDateTime = isStartTime ? _startTime : _endTime;
    
    final date = await showDatePicker(
      context: context,
      initialDate: currentDateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(currentDateTime),
      );
      
      if (time != null) {
        final newDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
        
        setState(() {
          if (isStartTime) {
            _startTime = newDateTime;
            // Ensure end time is after start time
            if (_endTime.isBefore(_startTime)) {
              _endTime = _startTime.add(const Duration(hours: 2));
            }
          } else {
            _endTime = newDateTime;
          }
        });
      }
    }
  }

  void _parseUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Reading webpage content...'),
          ],
        ),
        duration: Duration(seconds: 3),
      ),
    );

    try {
      // Fetch webpage content with better headers to avoid 403
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8',
          'Accept-Language': 'en-US,en;q=0.9',
          'Accept-Encoding': 'gzip, deflate, br',
          'DNT': '1',
          'Connection': 'keep-alive',
          'Upgrade-Insecure-Requests': '1',
          'Sec-Fetch-Dest': 'document',
          'Sec-Fetch-Mode': 'navigate',
          'Sec-Fetch-Site': 'none',
          'Cache-Control': 'max-age=0',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final content = response.body.toLowerCase();
        
        // Extract title from webpage
        final titleMatch = RegExp(r'<title[^>]*>([^<]+)</title>', caseSensitive: false)
            .firstMatch(response.body);
        String extractedTitle = '';
        if (titleMatch != null) {
          extractedTitle = titleMatch.group(1)!
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim()
              .replaceAll(' - Dublin Bus', '')
              .replaceAll(' | Dublin Bus', '');
        }

        // Extract route numbers from content (more precise)
        final routeMatches = RegExp(r'\broute\s*(c[12]|[0-9]+[a-z]?|l[0-9]+|n[0-9]+)\b', caseSensitive: false)
            .allMatches(content);
        
        final routes = <String>{};
        for (final match in routeMatches) {
          final route = match.group(1)!.toUpperCase();
          // Exclude years and other numbers
          if (!RegExp(r'^(19|20)\d{2}$').hasMatch(route) && 
              !RegExp(r'^\d{4,}$').hasMatch(route)) {
            routes.add(route);
          }
        }

        // Extract description/content from webpage
        String extractedDescription = '';
        // Simple meta description extraction
        if (content.contains('description')) {
          final startIndex = content.indexOf('description');
          final contentIndex = content.indexOf('content=', startIndex);
          if (contentIndex != -1) {
            final start = contentIndex + 8; // Skip 'content='
            final quoteChar = content[start]; // Get quote character
            if (quoteChar == '"' || quoteChar == "'") {
              final endIndex = content.indexOf(quoteChar, start + 1);
              if (endIndex != -1) {
                extractedDescription = response.body.substring(start + 1, endIndex).trim();
              }
            }
          }
        }
        
        // If no meta description, try to extract from paragraph tags
        if (extractedDescription.isEmpty) {
          final paragraphMatch = RegExp(r'<p[^>]*>([^<]+)</p>', caseSensitive: false)
              .firstMatch(response.body);
          if (paragraphMatch != null) {
            extractedDescription = paragraphMatch.group(1)!
                .replaceAll(RegExp(r'\s+'), ' ')
                .trim();
          }
        }

        // Auto-fill fields
        if (_titleController.text.isEmpty && extractedTitle.isNotEmpty) {
          _titleController.text = extractedTitle;
        }

        if (routes.isNotEmpty) {
          _routesController.text = routes.join(', ');
        }

        if (_descriptionController.text.isEmpty) {
          if (extractedDescription.isNotEmpty) {
            _descriptionController.text = '$extractedDescription\n\nFull details: $url';
          } else {
            _descriptionController.text = 'Please check Dublin Bus website for full details: $url';
          }
        }

        // Auto-set priority based on content keywords
        if (content.contains('emergency') || content.contains('urgent') || content.contains('major disruption')) {
          setState(() {
            _priority = 'critical';
          });
        } else if (content.contains('delay') || content.contains('diversion') || content.contains('closure') || content.contains('disruption')) {
          setState(() {
            _priority = 'warning';
          });
        } else {
          setState(() {
            _priority = 'info';
          });
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully extracted content from webpage${routes.isNotEmpty ? " - Found routes: ${routes.join(", ")}" : ""}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Failed to load webpage (${response.statusCode})');
      }
    } catch (e) {
      // Try alternative approach if initial request failed
      try {
        await _tryAlternativeWebScraping(url);
      } catch (alternativeError) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cannot access webpage (403 blocked). Using URL-based parsing instead.'),
            backgroundColor: Colors.orange,
          ),
        );
        
        // Fallback to smart URL parsing
        _parseUrlFallback(url);
      }
    }
  }

  Future<void> _tryAlternativeWebScraping(String url) async {
    // Alternative approach with minimal headers
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'User-Agent': 'SpDriverCalendar/1.0',
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      // Basic content extraction if alternative method works
      
      // Extract title
      final titleMatch = RegExp(r'<title[^>]*>([^<]+)</title>', caseSensitive: false)
          .firstMatch(response.body);
      if (titleMatch != null && _titleController.text.isEmpty) {
        final title = titleMatch.group(1)!
            .replaceAll(' - Dublin Bus', '')
            .replaceAll(' | Dublin Bus', '')
            .trim();
        _titleController.text = title;
      }
      
      _parseUrlFallback(url);
    } else {
      throw Exception('Alternative method also failed');
    }
  }

  void _parseUrlFallback(String url) {
    // Smart fallback parsing from URL structure and content
    final urlLower = url.toLowerCase();
    
    // Extract information from URL path and content
    if (_titleController.text.isEmpty) {
      if (urlLower.contains('pride')) {
        _titleController.text = 'Pride Festival Diversions';
        setState(() {
          _priority = 'warning';
        });
      } else if (urlLower.contains('diversion')) {
        _titleController.text = 'Service Diversions';
        setState(() {
          _priority = 'warning';
        });
      } else if (urlLower.contains('delay')) {
        _titleController.text = 'Service Delays';
        setState(() {
          _priority = 'warning';
        });
      } else if (urlLower.contains('closure')) {
        _titleController.text = 'Road Closure';
        setState(() {
          _priority = 'critical';
        });
      } else if (urlLower.contains('emergency')) {
        _titleController.text = 'Emergency Service Update';
        setState(() {
          _priority = 'critical';
        });
      } else {
        _titleController.text = 'Service Update';
        setState(() {
          _priority = 'info';
        });
      }
    }

    // Smart route extraction from URL
    if (_routesController.text.isEmpty) {
      // Extract route numbers from URL (avoiding years)
      final routeMatches = RegExp(r'\b(?:route[s]?[-\s]*)?([c][12]|[0-9]{1,3}[a-z]?|[ln][0-9]+)\b', caseSensitive: false)
          .allMatches(urlLower);
      
      final routes = <String>{};
      for (final match in routeMatches) {
        final route = match.group(1)!.toUpperCase();
        // Exclude years (1900-2099) and other obvious non-routes
        if (!RegExp(r'^(19|20)\d{2}$').hasMatch(route) && 
            !RegExp(r'^\d{4,}$').hasMatch(route) &&
            int.tryParse(route) != null ? int.parse(route) <= 200 : true) {
          routes.add(route);
        }
      }
      
      if (routes.isNotEmpty) {
        _routesController.text = routes.join(', ');
      }
    }

    if (_descriptionController.text.isEmpty) {
      // Create smart description based on URL content
      String description = '';
      
      if (urlLower.contains('pride')) {
        description = 'Service diversions in place for Pride Festival. Routes may be diverted or delayed.';
      } else if (urlLower.contains('diversion')) {
        description = 'Route diversions are in place. Please check for alternative stops and delays.';
      } else if (urlLower.contains('delay')) {
        description = 'Service delays are expected. Please allow extra travel time.';
      } else {
        description = 'Service update information available.';
      }
      
      _descriptionController.text = '$description\n\nFull details: $url';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Auto-filled details from URL analysis'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _saveUpdate() {
    if (_formKey.currentState!.validate()) {
      final routes = _routesController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final update = LiveUpdate(
        id: widget.existingUpdate?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        priority: _priority,
        startTime: _startTime,
        endTime: _endTime,
        routesAffected: routes,
        forceVisible: _forceVisible,
        enableScheduledVisibility: _enableScheduledVisibility && !_forceVisible,
        hoursBeforeStart: _enableScheduledVisibility && !_forceVisible ? _hoursBeforeStart : 0,
      );

      widget.onSave(update);
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _routesController.dispose();
    super.dispose();
  }
}

// Dialog for creating/editing polls
class PollDialog extends StatefulWidget {
  final LiveUpdate? existingPoll;
  final Function(LiveUpdate) onSave;

  const PollDialog({
    super.key,
    this.existingPoll,
    required this.onSave,
  });

  @override
  PollDialogState createState() => PollDialogState();
}

class PollDialogState extends State<PollDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [];
  
  String _voteVisibility = 'always';
  DateTime _startTime = DateTime.now();
  DateTime _endTime = DateTime.now().add(const Duration(days: 7));
  int _resultsVisibleDays = 7;

  @override
  void initState() {
    super.initState();
    if (widget.existingPoll != null) {
      final poll = widget.existingPoll!;
      _titleController.text = poll.title;
      _descriptionController.text = poll.description;
      _voteVisibility = poll.voteVisibility ?? 'always';
      _startTime = poll.startTime;
      _endTime = poll.endTime;
      _resultsVisibleDays = poll.resultsVisibleUntil != null
          ? poll.resultsVisibleUntil!.difference(poll.endTime).inDays
          : 7;
      
      if (poll.pollOptions != null) {
        for (var option in poll.pollOptions!) {
          _optionControllers.add(TextEditingController(text: option));
        }
      }
    } else {
      // Default: 2 options
      _optionControllers.add(TextEditingController());
      _optionControllers.add(TextEditingController());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.deepPurple.shade600,
                    Colors.deepPurple.shade800,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.poll, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    widget.existingPoll != null ? 'Edit Poll' : 'Create New Poll',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Poll Question',
                          hintText: 'e.g., Which route do you prefer?',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Question is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description (Optional)',
                          hintText: 'Additional context for the poll',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      // Poll Options
                      Row(
                        children: [
                          const Text(
                            'Poll Options',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              setState(() {
                                _optionControllers.add(TextEditingController());
                              });
                            },
                            tooltip: 'Add Option',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ..._optionControllers.asMap().entries.map((entry) {
                        final index = entry.key;
                        final controller = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: controller,
                                  decoration: InputDecoration(
                                    labelText: 'Option ${index + 1}',
                                    border: const OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Required';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              if (_optionControllers.length > 2)
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      controller.dispose();
                                      _optionControllers.removeAt(index);
                                    });
                                  },
                                ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _voteVisibility,
                        decoration: const InputDecoration(
                          labelText: 'Vote Visibility',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'always',
                            child: Text('Always show counts'),
                          ),
                          DropdownMenuItem(
                            value: 'after_vote',
                            child: Text('Show after user votes'),
                          ),
                          DropdownMenuItem(
                            value: 'after_end',
                            child: Text('Show after poll ends'),
                          ),
                          DropdownMenuItem(
                            value: 'never',
                            child: Text('Never show counts'),
                          ),
                        ],
                        onChanged: (value) => setState(() => _voteVisibility = value!),
                      ),
                      const SizedBox(height: 16),
                      // Start time
                      ListTile(
                        title: const Text('Start Time'),
                        subtitle: Text(DateFormat('MMM d, yyyy HH:mm').format(_startTime)),
                        trailing: const Icon(Icons.schedule),
                        onTap: () => _selectDateTime(true),
                      ),
                      // End time
                      ListTile(
                        title: const Text('End Time'),
                        subtitle: Text(DateFormat('MMM d, yyyy HH:mm').format(_endTime)),
                        trailing: const Icon(Icons.schedule),
                        onTap: () => _selectDateTime(false),
                      ),
                      const SizedBox(height: 16),
                      // Results visible duration
                      TextFormField(
                        initialValue: _resultsVisibleDays.toString(),
                        decoration: const InputDecoration(
                          labelText: 'Show Results For (Days)',
                          hintText: 'How many days to show results after poll ends',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          final days = int.tryParse(value);
                          if (days != null && days > 0) {
                            setState(() => _resultsVisibleDays = days);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _savePoll,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple.shade600,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(widget.existingPoll != null ? 'Update' : 'Create'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDateTime(bool isStartTime) async {
    final currentDateTime = isStartTime ? _startTime : _endTime;
    
    final date = await showDatePicker(
      context: context,
      initialDate: currentDateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(currentDateTime),
      );
      
      if (time != null) {
        final newDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
        
        setState(() {
          if (isStartTime) {
            _startTime = newDateTime;
            if (_endTime.isBefore(_startTime)) {
              _endTime = _startTime.add(const Duration(days: 7));
            }
          } else {
            _endTime = newDateTime;
          }
        });
      }
    }
  }

  void _savePoll() {
    if (_formKey.currentState!.validate()) {
      if (_optionControllers.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add at least 2 options'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final options = _optionControllers
          .map((controller) => controller.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();

      if (options.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add at least 2 valid options'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final poll = LiveUpdate(
        id: widget.existingPoll?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        priority: 'info', // Not used for polls
        startTime: _startTime,
        endTime: _endTime,
        routesAffected: [], // Polls are app-wide
        type: 'poll',
        pollOptions: options,
        voteVisibility: _voteVisibility,
        voteCounts: widget.existingPoll?.voteCounts ?? List.filled(options.length, 0),
        totalVotes: widget.existingPoll?.totalVotes ?? 0,
        resultsVisibleUntil: _endTime.add(Duration(days: _resultsVisibleDays)),
      );

      widget.onSave(poll);
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}

 