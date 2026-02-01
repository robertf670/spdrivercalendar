import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/live_update.dart';
import '../../../services/live_updates_service.dart';
import '../../../services/poll_service.dart';
import 'admin_panel_screen.dart';

class PollManagementScreen extends StatefulWidget {
  const PollManagementScreen({super.key});

  @override
  PollManagementScreenState createState() => PollManagementScreenState();
}

class PollManagementScreenState extends State<PollManagementScreen> {
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
        title: const Text('Admin Panel - Polls'),
        elevation: 0,
        backgroundColor: Colors.deepPurple.shade600,
        foregroundColor: Colors.white,
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
                // Polls list
                Expanded(
                  child: StreamBuilder<List<LiveUpdate>>(
                    stream: LiveUpdatesService.getPollsStream(),
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
                                'Error loading polls: ${snapshot.error}',
                                style: TextStyle(color: theme.colorScheme.error),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      final polls = snapshot.data ?? [];
                      
                      if (polls.isEmpty) {
                        return _buildEmptyState();
                      }
                      
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: polls.length,
                        itemBuilder: (context, index) => _buildPollCard(polls[index]),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'addPoll',
        onPressed: _showAddPollDialog,
        backgroundColor: Colors.deepPurple.shade600,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.poll),
        label: const Text('Add Poll'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.poll_outlined,
            size: 64,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No polls yet',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to create your first poll',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPollCard(LiveUpdate poll) {
    final theme = Theme.of(context);
    final isExpired = poll.endTime.isBefore(DateTime.now());
    final isActive = poll.isActive;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.deepPurple.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isActive
                          ? [Colors.deepPurple.shade400, Colors.deepPurple.shade600]
                          : [Colors.grey.shade400, Colors.grey.shade600],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isActive ? 'Active' : (isExpired ? 'Ended' : 'Scheduled'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _showEditPollDialog(poll);
                        break;
                      case 'reset_votes':
                        _confirmResetVotes(poll);
                        break;
                      case 'delete':
                        _confirmDelete(poll);
                        break;
                      case 'end_now':
                        _endPollNow(poll);
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
                    PopupMenuItem(
                      value: 'reset_votes',
                      child: Row(
                        children: [
                          Icon(Icons.refresh, size: 18, color: Colors.orange),
                          const SizedBox(width: 8),
                          Text(
                            'Reset Votes${poll.totalVotes != null && poll.totalVotes! > 0 ? ' (${poll.totalVotes})' : ''}',
                            style: const TextStyle(color: Colors.orange),
                          ),
                        ],
                      ),
                    ),
                    if (poll.isActive)
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
              poll.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            // Description
            if (poll.description.isNotEmpty)
              Text(
                poll.description,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                ),
              ),
            const SizedBox(height: 12),
            // Poll options with vote counts
            if (poll.pollOptions != null && poll.pollOptions!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.bar_chart, size: 16, color: Colors.deepPurple.shade700),
                    const SizedBox(width: 6),
                    const Text(
                      'Options & Votes:',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ...poll.pollOptions!.asMap().entries.map((entry) {
                final index = entry.key;
                final option = entry.value;
                final voteCount = poll.voteCounts != null && index < poll.voteCounts!.length
                    ? poll.voteCounts![index]
                    : 0;
                final totalVotes = poll.totalVotes ?? 0;
                final percentage = totalVotes > 0 ? (voteCount / totalVotes * 100) : 0.0;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.deepPurple.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          option,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.deepPurple.shade900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.deepPurple.shade400,
                              Colors.deepPurple.shade600,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.deepPurple.withValues(alpha: 0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$voteCount',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '(${percentage.toStringAsFixed(1)}%)',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.deepPurple.shade100,
                      Colors.deepPurple.shade50,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.deepPurple.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people, size: 16, color: Colors.deepPurple.shade700),
                    const SizedBox(width: 6),
                    Text(
                      'Total votes: ${poll.totalVotes ?? 0}',
                      style: TextStyle(
                        color: Colors.deepPurple.shade800,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            // Time info
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '${DateFormat('MMM d, HH:mm').format(poll.startTime)} - ${DateFormat('MMM d, HH:mm').format(poll.endTime)}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            if (poll.resultsVisibleUntil != null && isExpired) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.visibility, size: 16, color: Colors.blue.shade600),
                  const SizedBox(width: 4),
                  Text(
                    'Results visible until ${DateFormat('MMM d, HH:mm').format(poll.resultsVisibleUntil!)}',
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
      ),
    );
  }

  void _showAddPollDialog() {
    _showPollDialog();
  }

  void _showEditPollDialog(LiveUpdate poll) {
    _showPollDialog(existingPoll: poll);
  }
  
  void _showPollDialog({LiveUpdate? existingPoll}) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (context) => PollDialog(
        existingPoll: existingPoll,
        onSave: (poll) async {
          try {
            if (existingPoll != null) {
              await LiveUpdatesService.updateUpdate(poll);
              if (mounted) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Poll saved successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } else {
              await LiveUpdatesService.addUpdate(poll);
              if (mounted) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Poll created successfully'),
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

  void _confirmResetVotes(LiveUpdate poll) {
    final totalVotes = poll.totalVotes ?? 0;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.refresh, color: Colors.orange),
            SizedBox(width: 8),
            Text('Reset Poll Votes'),
          ],
        ),
        content: Text(
          'Are you sure you want to reset all votes for "${poll.title}"?\n\n'
          'This will delete all $totalVotes vote(s) and cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final optionCount = poll.pollOptions?.length ?? 0;
                await PollService.resetPollVotes(poll.id, optionCount);
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('All votes reset for "${poll.title}"'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Error resetting votes: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Reset Votes'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(LiveUpdate poll) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Poll'),
        content: Text('Are you sure you want to delete "${poll.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await LiveUpdatesService.deleteUpdate(poll.id);
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Poll "${poll.title}" deleted'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Error deleting poll: $e'),
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

  void _endPollNow(LiveUpdate poll) async {
    try {
      await LiveUpdatesService.endUpdateNow(poll.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Poll "${poll.title}" ended'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error ending poll: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

