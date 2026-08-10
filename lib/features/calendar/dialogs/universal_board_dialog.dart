import 'package:flutter/material.dart';
import 'package:spdrivercalendar/models/universal_board.dart';

/// Presentation dialog for a [UniversalBoard] timeline.
class UniversalBoardDialog extends StatelessWidget {
  const UniversalBoardDialog({
    super.key,
    required this.board,
  });

  final UniversalBoard board;

  Map<String, double> _getResponsiveSizes(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    if (screenWidth < 350) {
      return {
        'timeWidth': 58.0,
        'padding': 12.0,
        'headerHPad': 12.0,
        'headerVPad': 14.0,
        'maxWidthFactor': 0.96,
        'maxHeightFactor': 0.9,
      };
    } else if (screenWidth < 400) {
      return {
        'timeWidth': 64.0,
        'padding': 16.0,
        'headerHPad': 16.0,
        'headerVPad': 16.0,
        'maxWidthFactor': 0.95,
        'maxHeightFactor': 0.88,
      };
    }
    return {
      'timeWidth': 70.0,
      'padding': 20.0,
      'headerHPad': 20.0,
      'headerVPad': 18.0,
      'maxWidthFactor': 0.95,
      'maxHeightFactor': 0.85,
    };
  }

  @override
  Widget build(BuildContext context) {
    final sizes = _getResponsiveSizes(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final timeWidth = sizes['timeWidth']!;
    final contentPadding = sizes['padding']!;

    return Dialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: screenWidth < 350 ? 8 : 24,
          vertical: 24,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: screenWidth * sizes['maxWidthFactor']!,
            maxHeight: screenHeight * sizes['maxHeightFactor']!,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.symmetric(horizontal: sizes['headerHPad']!, vertical: sizes['headerVPad']!),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Board ${board.shift}',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          if (board.duty != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Duty ${board.duty}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                      onPressed: () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(contentPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: board.sections.map((section) {
                      final sectionType = section.type;
                      final isFirstHalf = sectionType == 'firstHalf';
                      final sectionColor = isFirstHalf ? Colors.orange : Colors.blue;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Section header with subtle background
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: sectionColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: sectionColor,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      isFirstHalf ? 'First Half' : 'Second Half',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: screenWidth < 350 ? 15 : 17,
                                        color: sectionColor.shade800,
                                        letterSpacing: 0.3,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Entries with subtle timeline
                            ...section.entries.asMap().entries.map((entryEntry) {
                              final entry = entryEntry.value;
                              final isLast = entryEntry.key == section.entries.length - 1;
                              
                              // Calculate if this entry has content below the action
                              final hasDetails = entry.location != null || 
                                                 entry.notes != null || 
                                                 (entry.action.toLowerCase() != 'route' && entry.route != null);
                              
                              // Check if action is Route (to combine with route badge)
                              final isRouteAction = entry.action.toLowerCase() == 'route' && entry.route != null;
                              
                              return Padding(
                                padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Time column - fixed width and alignment
                                    SizedBox(
                                      width: timeWidth,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (entry.time != null)
                                            Container(
                                              width: timeWidth,
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: sectionColor.shade50,
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: sectionColor.withValues(alpha: 0.3),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Text(
                                                entry.time!,
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  color: sectionColor.shade800,
                                                  height: 1.2,
                                                ),
                                              ),
                                            )
                                          else
                                            SizedBox(
                                              width: timeWidth,
                                              height: 30, // Match badge height
                                            ),
                                          if (!isLast) ...[
                                            const SizedBox(height: 6),
                                            Container(
                                              width: 2,
                                              height: hasDetails ? 35 : 15,
                                              color: sectionColor.withValues(alpha: 0.2),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: screenWidth < 350 ? 8 : 16),
                                    // Content column
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Action - aligned with time badge by matching height
                                          SizedBox(
                                            height: entry.time != null ? 30 : null,
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: isRouteAction
                                                  ? Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      crossAxisAlignment: CrossAxisAlignment.center,
                                                      children: [
                                                        Text(
                                                          'Route ',
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.w600,
                                                            fontSize: screenWidth < 350 ? 14 : 16,
                                                            color: Theme.of(context).colorScheme.onSurface,
                                                          ),
                                                        ),
                                                        Flexible(
                                                          child: Container(
                                                            padding: const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 4,
                                                            ),
                                                            decoration: BoxDecoration(
                                                              color: Colors.blue.shade50,
                                                              borderRadius: BorderRadius.circular(6),
                                                            ),
                                                            child: Text(
                                                              entry.route!,
                                                              overflow: TextOverflow.ellipsis,
                                                              style: TextStyle(
                                                                fontSize: screenWidth < 350 ? 14 : 16,
                                                                color: Colors.blue.shade700,
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    )
                                                  : Text(
                                                      entry.action,
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: screenWidth < 350 ? 14 : 16,
                                                        color: Theme.of(context).colorScheme.onSurface,
                                                      ),
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                            ),
                                          ),
                                          if (hasDetails) const SizedBox(height: 6),
                                          // Route path information - just "From [location]"
                                          if (isRouteAction && entry.location != null) ...[
                                            Padding(
                                              padding: const EdgeInsets.only(top: 2),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.location_on,
                                                    size: 16,
                                                    color: Theme.of(context)
                                                        .colorScheme.onSurface
                                                        .withValues(alpha: 0.5),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Text(
                                                      'From ${entry.location}',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Theme.of(context)
                                                            .colorScheme.onSurface
                                                            .withValues(alpha: 0.7),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Show notes if they exist (like "via Celbridge")
                                            if (entry.notes != null) ...[
                                              Padding(
                                                padding: const EdgeInsets.only(top: 4),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.info_outline,
                                                      size: 16,
                                                      color: Theme.of(context)
                                                          .colorScheme.onSurface
                                                          .withValues(alpha: 0.5),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Expanded(
                                                      child: Text(
                                                        entry.notes!,
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          fontStyle: FontStyle.italic,
                                                          color: Theme.of(context)
                                                              .colorScheme.onSurface
                                                              .withValues(alpha: 0.7),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ] else ...[
                                            // Route badge (only if action is not "Route")
                                            if (entry.route != null) ...[
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 5,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.shade50,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  'Route ${entry.route}',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.blue.shade700,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                            ],
                                            // Location (for non-Route entries)
                                            if (entry.location != null) ...[
                                              Padding(
                                                padding: const EdgeInsets.only(top: 2),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.location_on,
                                                      size: 16,
                                                      color: Theme.of(context)
                                                          .colorScheme.onSurface
                                                          .withValues(alpha: 0.5),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Expanded(
                                                      child: Text(
                                                        entry.location!,
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color: Theme.of(context)
                                                              .colorScheme.onSurface
                                                              .withValues(alpha: 0.7),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ],
                                          // Notes (exclude Route entries as they're handled above)
                                          if (entry.notes != null && !isRouteAction) ...[
                                            Padding(
                                              padding: EdgeInsets.only(
                                                top: entry.location != null ? 4 : 2,
                                              ),
                                              child: Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context)
                                                      .colorScheme.surfaceContainerHighest
                                                      .withValues(alpha: 0.5),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Icon(
                                                      Icons.info_outline,
                                                      size: 16,
                                                      color: Theme.of(context)
                                                          .colorScheme.onSurface
                                                          .withValues(alpha: 0.5),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        entry.notes!,
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          color: Theme.of(context)
                                                              .colorScheme.onSurface
                                                              .withValues(alpha: 0.7),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }
}
