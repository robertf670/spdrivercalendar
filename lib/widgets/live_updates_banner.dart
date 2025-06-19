import 'package:flutter/material.dart';
import '../models/live_update.dart';
import '../services/live_updates_service.dart';
import 'dart:async';

class LiveUpdatesBanner extends StatefulWidget {
  final VoidCallback? onTap;
  static const Key staticKey = ValueKey('live_updates_banner_static');

  const LiveUpdatesBanner({
    Key? key = staticKey,
    this.onTap,
  }) : super(key: key);

  @override
  LiveUpdatesBannerState createState() => LiveUpdatesBannerState();
}

class LiveUpdatesBannerState extends State<LiveUpdatesBanner> {

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<LiveUpdate>>(
      stream: LiveUpdatesService.getActiveUpdatesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(8),
            color: Theme.of(context).colorScheme.errorContainer,
            child: Row(
              children: [
                Icon(Icons.error, color: Theme.of(context).colorScheme.error, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Error loading updates',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final updates = snapshot.data ?? [];
        final activeUpdates = updates.where((update) => update.isActive).toList();
        
        // Return empty widget when no updates - this will collapse the space
        if (activeUpdates.isEmpty) {
          return const SizedBox.shrink();
        }

        // Pass the updates to a separate display widget
        return LiveUpdatesBannerDisplay(
          updates: activeUpdates,
          onTap: widget.onTap,
        );
      },
    );
  }
}

class LiveUpdatesBannerDisplay extends StatefulWidget {
  final List<LiveUpdate> updates;
  final VoidCallback? onTap;

  const LiveUpdatesBannerDisplay({
    Key? key,
    required this.updates,
    this.onTap,
  }) : super(key: key);

  @override
  LiveUpdatesBannerDisplayState createState() => LiveUpdatesBannerDisplayState();
}

class LiveUpdatesBannerDisplayState extends State<LiveUpdatesBannerDisplay> {
  int _currentIndex = 0;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  @override
  void didUpdateWidget(LiveUpdatesBannerDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.updates.length != oldWidget.updates.length) {
      _currentIndex = 0;
      _startAutoScroll();
    }
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    if (widget.updates.length <= 1) return;
    
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % widget.updates.length;
        });
      }
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
        return Theme.of(context).colorScheme.outline;
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

  @override
  Widget build(BuildContext context) {
    if (widget.updates.isEmpty || _currentIndex >= widget.updates.length) {
      return const SizedBox.shrink();
    }

    final currentUpdate = widget.updates[_currentIndex];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(
          minHeight: 70,
          maxHeight: 90,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width < 400 ? 12 : 16,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isDark ? Theme.of(context).colorScheme.surfaceContainerHighest : Theme.of(context).colorScheme.surfaceContainerLow,
          // Subtle bottom border only for separation
          border: Border(
            bottom: BorderSide(
              color: isDark 
                ? Theme.of(context).colorScheme.outline.withValues(alpha: 0.2) 
                : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
              width: 0.5,
            ),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _getPriorityColor(currentUpdate.priority).withValues(alpha: 0.1),
                _getPriorityColor(currentUpdate.priority).withValues(alpha: 0.05),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(6),
            border: Border(
              left: BorderSide(
                color: _getPriorityColor(currentUpdate.priority),
                width: 3,
              ),
            ),
          ),
          padding: const EdgeInsets.all(6),
          child: Row(
            children: [
              // Priority icon
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _getPriorityColor(currentUpdate.priority).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getPriorityIcon(currentUpdate.priority),
                  color: _getPriorityColor(currentUpdate.priority),
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title with priority indicator
                    Flexible(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              currentUpdate.title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getPriorityColor(currentUpdate.priority).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _getPriorityColor(currentUpdate.priority).withValues(alpha: 0.4),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              currentUpdate.priority.toUpperCase(),
                              style: TextStyle(
                                color: _getPriorityColor(currentUpdate.priority),
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          // Indicators - only show if not too narrow
                          if (MediaQuery.of(context).size.width > 350 && widget.updates.length > 1) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${_currentIndex + 1}/${widget.updates.length}',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    // Message preview - only if there's enough space
                    if (currentUpdate.description.isNotEmpty)
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Text(
                            currentUpdate.description,
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
  }
} 