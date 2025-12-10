import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/live_update.dart';
import '../services/live_updates_service.dart';
import '../services/user_preferences_service.dart';
import '../services/poll_service.dart';
import '../features/settings/screens/live_updates_preferences_screen.dart';
import '../theme/app_theme.dart';

class LiveUpdatesDetailsScreen extends StatefulWidget {
  const LiveUpdatesDetailsScreen({super.key});

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

  Color _getPriorityColor(String priority, {bool isPoll = false}) {
    if (isPoll) return Colors.purple;
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

  IconData _getPriorityIcon(String priority, {bool isPoll = false}) {
    if (isPoll) return Icons.poll;
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
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading updates',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final updates = snapshot.data ?? [];
          // Filter: active updates + active polls + ended polls in results window
          final visibleItems = updates.where((update) {
            if (update.isUpdate) {
              return update.isActive;
            } else if (update.isPoll) {
              return update.shouldShowPoll;
            }
            return false;
          }).toList();

          return Column(
            children: [
              // Preference status banner
              if (!_showAllUpdates && _preferredRoutes.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Row(
                    children: [
                      Icon(Icons.filter_list, color: Theme.of(context).colorScheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Filtered for your preferred routes (${_preferredRoutes.length} routes)',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
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
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Updates and polls list
              Expanded(
                child: _buildUpdatesList(visibleItems),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUpdatesList(List<LiveUpdate> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'No Active Updates or Polls',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _showAllUpdates 
                ? 'All clear! No diversions, service updates, or polls at this time.'
                : 'No updates for your preferred routes. Tap "Show All" to see all updates.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final listPadding = screenWidth < 350 ? 12.0 : screenWidth < 400 ? 14.0 : screenWidth < 600 ? 16.0 : 18.0;
    
    return ListView.builder(
      padding: EdgeInsets.all(listPadding),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item.isPoll) {
          return _buildPollCard(item);
        } else {
          return _buildUpdateCard(item);
        }
      },
    );
  }

  // Responsive sizing helper method for poll cards
  Map<String, double> _getPollCardSizes(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth < 350) {
      return {
        'cardPadding': 12.0,
        'titleFontSize': 15.0,
        'descriptionFontSize': 13.0,
        'optionFontSize': 14.0,
        'optionPadding': 12.0,
        'iconSize': 18.0,
        'spacing': 12.0,
        'badgeFontSize': 12.0,
        'badgePadding': 8.0,
      };
    } else if (screenWidth < 400) {
      return {
        'cardPadding': 14.0,
        'titleFontSize': 15.5,
        'descriptionFontSize': 13.5,
        'optionFontSize': 14.5,
        'optionPadding': 13.0,
        'iconSize': 20.0,
        'spacing': 14.0,
        'badgeFontSize': 12.5,
        'badgePadding': 9.0,
      };
    } else if (screenWidth < 600) {
      return {
        'cardPadding': 16.0,
        'titleFontSize': 16.0,
        'descriptionFontSize': 14.0,
        'optionFontSize': 15.0,
        'optionPadding': 14.0,
        'iconSize': 22.0,
        'spacing': 16.0,
        'badgeFontSize': 14.0,
        'badgePadding': 10.0,
      };
    } else {
      return {
        'cardPadding': 18.0,
        'titleFontSize': 17.0,
        'descriptionFontSize': 14.5,
        'optionFontSize': 15.5,
        'optionPadding': 16.0,
        'iconSize': 24.0,
        'spacing': 18.0,
        'badgeFontSize': 14.0,
        'badgePadding': 10.0,
      };
    }
  }

  Widget _buildPollCard(LiveUpdate poll) {
    final sizes = _getPollCardSizes(context);
    
    return FutureBuilder<Map<String, dynamic>>(
      future: _getPollData(poll),
      builder: (context, snapshot) {
        final hasVoted = snapshot.data?['hasVoted'] ?? false;
        final userVoteIndex = snapshot.data?['userVoteIndex'];
        final isPollEnded = !poll.isActive;
        
        return Card(
          margin: EdgeInsets.only(bottom: sizes['spacing']!),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Colors.deepPurple.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  Colors.deepPurple.withValues(alpha: 0.08),
                  Colors.deepPurple.withValues(alpha: 0.03),
                  Theme.of(context).colorScheme.surface,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(sizes['cardPadding']!),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(sizes['iconSize']! * 0.45),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.deepPurple.shade400,
                              Colors.deepPurple.shade600,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.deepPurple.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.poll,
                          color: Colors.white,
                          size: sizes['iconSize'],
                        ),
                      ),
                      SizedBox(width: sizes['spacing']! * 0.75),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              poll.title,
                              style: TextStyle(
                                fontSize: sizes['titleFontSize'],
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.deepPurple.shade400,
                                        Colors.deepPurple.shade600,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.deepPurple.withValues(alpha: 0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    isPollEnded ? 'ENDED' : 'POLL',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                if (hasVoted) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.teal.shade400,
                                          Colors.teal.shade600,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.teal.withValues(alpha: 0.2),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.check_circle, size: 12, color: Colors.white),
                                        SizedBox(width: 4),
                                        Text(
                                          'VOTED',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (isPollEnded)
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () async {
                            await PollService.dismissPoll(poll.id);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Poll dismissed')),
                              );
                            }
                          },
                          tooltip: 'Dismiss',
                        ),
                    ],
                  ),
                  
                  if (poll.description.isNotEmpty) ...[
                    SizedBox(height: sizes['spacing']!),
                    Text(
                      poll.description,
                      style: TextStyle(
                        fontSize: sizes['descriptionFontSize'],
                        color: Theme.of(context).colorScheme.onSurface,
                        height: 1.4,
                      ),
                    ),
                  ],
                  
                  SizedBox(height: sizes['spacing']!),
                  
                  // Poll options
                  Builder(
                    builder: (context) {
                      final showCounts = PollService.shouldShowVoteCounts(poll, hasVoted, isPollEnded);
                      final totalVotes = poll.totalVotes ?? 0;
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (poll.pollOptions != null && poll.pollOptions!.isNotEmpty)
                            ...poll.pollOptions!.asMap().entries.map((entry) {
                              final optionIndex = entry.key;
                              final option = entry.value;
                              final voteCount = poll.voteCounts != null && optionIndex < poll.voteCounts!.length
                                  ? poll.voteCounts![optionIndex]
                                  : 0;
                              final percentage = totalVotes > 0 ? (voteCount / totalVotes * 100) : 0.0;
                              final isUserVote = hasVoted && userVoteIndex == optionIndex;
                      
                      return Padding(
                        padding: EdgeInsets.only(bottom: sizes['spacing']! * 0.75),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isPollEnded && !hasVoted)
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.deepPurple.shade50,
                                      Colors.deepPurple.shade100.withValues(alpha: 0.5),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: Colors.deepPurple.withValues(alpha: 0.3),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.deepPurple.withValues(alpha: 0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _handleVote(poll, optionIndex),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: sizes['optionPadding']!,
                                        vertical: sizes['optionPadding']! * 0.875,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              option,
                                              style: TextStyle(
                                                fontSize: sizes['optionFontSize'],
                                                fontWeight: FontWeight.w600,
                                                color: Colors.deepPurple.shade900,
                                              ),
                                            ),
                                          ),
                                          Icon(
                                            Icons.arrow_forward_ios,
                                            size: sizes['optionFontSize']! * 0.9,
                                            color: Colors.deepPurple.shade700,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            else
                              Container(
                                padding: EdgeInsets.all(sizes['optionPadding']!),
                                decoration: BoxDecoration(
                                  gradient: isUserVote
                                      ? LinearGradient(
                                          colors: [
                                            Colors.teal.shade50,
                                            Colors.teal.shade100.withValues(alpha: 0.5),
                                          ],
                                        )
                                      : LinearGradient(
                                          colors: [
                                            Theme.of(context).colorScheme.surfaceContainerLow,
                                            Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                          ],
                                        ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isUserVote 
                                        ? Colors.teal.shade400
                                        : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                                    width: isUserVote ? 2 : 1.5,
                                  ),
                                  boxShadow: isUserVote
                                      ? [
                                          BoxShadow(
                                            color: Colors.teal.withValues(alpha: 0.15),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        option,
                                        style: TextStyle(
                                          fontSize: sizes['optionFontSize']! * 0.93,
                                          fontWeight: isUserVote ? FontWeight.w600 : FontWeight.normal,
                                          color: isUserVote 
                                              ? Colors.green 
                                              : Theme.of(context).colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    if (showCounts) ...[
                                      SizedBox(width: sizes['spacing']! * 0.75),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: sizes['badgePadding']!,
                                          vertical: sizes['badgePadding']! * 0.4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isUserVote
                                              ? Colors.teal.shade400
                                              : Colors.deepPurple.shade400,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '$voteCount',
                                              style: TextStyle(
                                                fontSize: sizes['badgeFontSize'],
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                            SizedBox(width: sizes['spacing']! * 0.25),
                                            Text(
                                              '(${percentage.toStringAsFixed(1)}%)',
                                              style: TextStyle(
                                                fontSize: sizes['badgeFontSize']! * 0.86,
                                                color: Colors.white.withValues(alpha: 0.9),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    if (isUserVote) ...[
                                      SizedBox(width: sizes['spacing']! * 0.5),
                                      Container(
                                        padding: EdgeInsets.all(sizes['spacing']! * 0.25),
                                        decoration: BoxDecoration(
                                          color: Colors.teal.shade400,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: sizes['badgeFontSize']! * 0.9,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            if (showCounts && totalVotes > 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: FractionallySizedBox(
                                      alignment: Alignment.centerLeft,
                                      widthFactor: percentage / 100,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: isUserVote
                                                ? [
                                                    Colors.teal.shade400,
                                                    Colors.teal.shade600,
                                                  ]
                                                : [
                                                    Colors.deepPurple.shade400,
                                                    Colors.deepPurple.shade600,
                                                  ],
                                          ),
                                          borderRadius: BorderRadius.circular(8),
                                          boxShadow: [
                                            BoxShadow(
                                              color: (isUserVote ? Colors.teal : Colors.deepPurple)
                                                  .withValues(alpha: 0.3),
                                              blurRadius: 4,
                                              offset: const Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                            }),
                          if (showCounts && totalVotes > 0) ...[
                            SizedBox(height: sizes['spacing']! * 0.75),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: sizes['spacing']! * 0.75,
                                vertical: sizes['spacing']! * 0.5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.deepPurple.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.people_outline,
                                    size: sizes['badgeFontSize']! * 1.1,
                                    color: Colors.deepPurple.shade700,
                                  ),
                                  SizedBox(width: sizes['spacing']! * 0.375),
                                  Text(
                                    'Total votes: $totalVotes',
                                    style: TextStyle(
                                      fontSize: sizes['badgeFontSize']! * 0.93,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.deepPurple.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                  
                  SizedBox(height: sizes['spacing']!),
                  
                  // Time information
                  Container(
                    padding: EdgeInsets.all(sizes['spacing']! * 0.75),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Theme.of(context).colorScheme.outline),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isPollEnded 
                                ? 'Ended ${_formatTimeRange(poll.startTime, poll.endTime)}'
                                : _formatTimeRange(poll.startTime, poll.endTime),
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _getPollData(LiveUpdate poll) async {
    final hasVoted = await PollService.hasUserVoted(poll.id);
    final userVoteIndex = hasVoted ? await PollService.getUserVote(poll.id) : null;
    return {
      'hasVoted': hasVoted,
      'userVoteIndex': userVoteIndex,
    };
  }

  Future<void> _handleVote(LiveUpdate poll, int optionIndex) async {
    try {
      final success = await PollService.vote(poll.id, optionIndex);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vote submitted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          setState(() {}); // Refresh to show vote
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You have already voted in this poll'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error voting: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildUpdateCard(LiveUpdate update) {
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
                Theme.of(context).colorScheme.surface,
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
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
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
                                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.live_tv,
                                        size: 10,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        'ACTIVE',
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.primary,
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
                      color: Theme.of(context).colorScheme.onSurface,
                      height: 1.4,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Time information
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Theme.of(context).colorScheme.outline),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _formatTimeRange(update.startTime, update.endTime),
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurface,
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
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
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
  }
}