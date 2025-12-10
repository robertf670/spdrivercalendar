import 'package:flutter/material.dart';
import '../models/live_update.dart';
import '../services/live_updates_service.dart';
import 'dart:async';

class LiveUpdatesBanner extends StatefulWidget {
  final VoidCallback? onTap;
  static const Key staticKey = ValueKey('live_updates_banner_static');

  const LiveUpdatesBanner({
    super.key = staticKey,
    this.onTap,
  });

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
        // Filter: active updates + active polls + ended polls in results window
        final visibleItems = updates.where((update) {
          if (update.isUpdate) {
            return update.isActive;
          } else if (update.isPoll) {
            return update.shouldShowPoll;
          }
          return false;
        }).toList();
        
        // Return empty widget when no updates/polls - this will collapse the space
        if (visibleItems.isEmpty) {
          return const SizedBox.shrink();
        }

        // Pass the updates/polls to a separate display widget
        return LiveUpdatesBannerDisplay(
          updates: visibleItems,
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
    super.key,
    required this.updates,
    this.onTap,
  });

  @override
  LiveUpdatesBannerDisplayState createState() => LiveUpdatesBannerDisplayState();
}

class LiveUpdatesBannerDisplayState extends State<LiveUpdatesBannerDisplay> {
  int _currentIndex = 0;
  Timer? _autoScrollTimer;
  Timer? _resumeTimer;
  PageController? _pageController;
  bool _userIsScrolling = false;

  @override
  void initState() {
    super.initState();
    if (widget.updates.length > 1) {
      _pageController = PageController();
    }
    _startAutoScroll();
  }

  @override
  void didUpdateWidget(LiveUpdatesBannerDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.updates.length != oldWidget.updates.length) {
      _currentIndex = 0;
      
      // Handle PageController for multiple vs single banners
      if (widget.updates.length > 1 && _pageController == null) {
        _pageController = PageController();
      } else if (widget.updates.length <= 1 && _pageController != null) {
        _pageController?.dispose();
        _pageController = null;
      }
      
      _startAutoScroll();
    }
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _resumeTimer?.cancel();
    _pageController?.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    if (widget.updates.length <= 1) return;
    
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted && !_userIsScrolling && _pageController != null) {
        final nextIndex = (_currentIndex + 1) % widget.updates.length;
        _pageController!.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _onUserScroll() {
    _userIsScrolling = true;
    _resumeTimer?.cancel();
    
    // Resume auto-scrolling after 8 seconds of no user interaction
    _resumeTimer = Timer(const Duration(seconds: 8), () {
      if (mounted) {
        _userIsScrolling = false;
      }
    });
  }

  void _onPageChanged(int index) {
    if (mounted) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  Color _getPriorityColor(String priority, bool isPoll) {
    if (isPoll) {
      return Colors.deepPurple.shade600;
    }
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

  IconData _getPriorityIcon(String priority, bool isPoll) {
    if (isPoll) {
      return Icons.poll;
    }
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

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // For single banner, use the original simple approach
    if (widget.updates.length == 1) {
      return _buildSingleBanner(widget.updates[0], isDark);
    }

    // For multiple banners, use PageView for scrolling
    final sizes = _getBannerSizes(context);
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: sizes['minHeight']!,
        maxHeight: sizes['maxHeight']!,
      ),
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        itemCount: widget.updates.length,
        itemBuilder: (context, index) {
          return _buildSingleBanner(widget.updates[index], isDark);
        },
      ),
    );
  }

  // Responsive sizing helper method for banners
  Map<String, double> _getBannerSizes(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth < 350) {
      return {
        'horizontalPadding': 10.0,
        'verticalPadding': 8.0,
        'minHeight': 65.0,
        'maxHeight': 85.0,
        'iconSize': 14.0,
        'titleFontSize': 12.0,
        'subtitleFontSize': 10.0,
        'iconPadding': 5.0,
        'spacing': 10.0,
      };
    } else if (screenWidth < 400) {
      return {
        'horizontalPadding': 12.0,
        'verticalPadding': 9.0,
        'minHeight': 68.0,
        'maxHeight': 88.0,
        'iconSize': 15.0,
        'titleFontSize': 12.5,
        'subtitleFontSize': 10.5,
        'iconPadding': 6.0,
        'spacing': 11.0,
      };
    } else if (screenWidth < 600) {
      return {
        'horizontalPadding': 16.0,
        'verticalPadding': 10.0,
        'minHeight': 70.0,
        'maxHeight': 90.0,
        'iconSize': 16.0,
        'titleFontSize': 13.0,
        'subtitleFontSize': 11.0,
        'iconPadding': 6.0,
        'spacing': 12.0,
      };
    } else {
      return {
        'horizontalPadding': 18.0,
        'verticalPadding': 11.0,
        'minHeight': 72.0,
        'maxHeight': 92.0,
        'iconSize': 17.0,
        'titleFontSize': 13.5,
        'subtitleFontSize': 11.5,
        'iconPadding': 7.0,
        'spacing': 12.0,
      };
    }
  }

  Widget _buildSingleBanner(LiveUpdate update, bool isDark) {
    final isPoll = update.isPoll;
    final priorityColor = _getPriorityColor(update.priority, isPoll);
    final priorityIcon = _getPriorityIcon(update.priority, isPoll);
    final statusText = isPoll 
        ? (update.isActive ? 'POLL' : 'RESULTS')
        : update.priority.toUpperCase();
    final sizes = _getBannerSizes(context);
    
    return GestureDetector(
      onTap: () {
        if (widget.updates.length > 1) {
          _onUserScroll(); // Pause auto-scrolling when user taps
        }
        widget.onTap?.call();
      },
      onPanStart: widget.updates.length > 1 ? (_) => _onUserScroll() : null,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          minHeight: sizes['minHeight']!,
          maxHeight: sizes['maxHeight']!,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: sizes['horizontalPadding']!,
          vertical: sizes['verticalPadding']!,
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
                priorityColor.withValues(alpha: 0.1),
                priorityColor.withValues(alpha: 0.05),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(6),
            border: Border(
              left: BorderSide(
                color: priorityColor,
                width: 3,
              ),
            ),
          ),
          padding: EdgeInsets.all(sizes['spacing']! * 0.5),
          child: Row(
            children: [
              // Priority/Poll icon
              Container(
                padding: EdgeInsets.all(sizes['iconPadding']!),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  priorityIcon,
                  color: priorityColor,
                  size: sizes['iconSize'],
                ),
              ),
              SizedBox(width: sizes['spacing']!),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title with priority/poll indicator
                    Flexible(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              update.title,
                              style: TextStyle(
                                fontSize: sizes['titleFontSize'],
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.only(left: sizes['spacing']! * 0.33),
                            padding: EdgeInsets.symmetric(
                              horizontal: sizes['spacing']! * 0.5,
                              vertical: sizes['spacing']! * 0.17,
                            ),
                            decoration: BoxDecoration(
                              color: priorityColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: priorityColor.withValues(alpha: 0.4),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                color: priorityColor,
                                fontSize: sizes['subtitleFontSize']! * 0.82,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          // Indicators - only show if not too narrow and multiple banners
                          if (MediaQuery.of(context).size.width > 350 && widget.updates.length > 1) ...[
                            SizedBox(width: sizes['spacing']! * 0.33),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: sizes['spacing']! * 0.33,
                                vertical: sizes['spacing']! * 0.17,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${_currentIndex + 1}/${widget.updates.length}',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                  fontSize: sizes['subtitleFontSize']! * 0.82,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    // Always show tap to view details
                    Flexible(
                      child: Padding(
                        padding: EdgeInsets.only(top: sizes['spacing']! * 0.08),
                        child: Text(
                          isPoll ? 'Tap to vote' : 'Tap to view details',
                          style: TextStyle(
                            fontSize: sizes['subtitleFontSize'],
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            fontStyle: FontStyle.italic,
                          ),
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