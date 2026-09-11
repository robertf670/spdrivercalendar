import 'package:flutter/material.dart';
import 'package:spdrivercalendar/features/calendar/widgets/universal_board_timeline.dart';
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
        'padding': 12.0,
        'headerHPad': 12.0,
        'headerVPad': 14.0,
        'maxWidthFactor': 0.96,
        'maxHeightFactor': 0.9,
      };
    } else if (screenWidth < 400) {
      return {
        'padding': 16.0,
        'headerHPad': 16.0,
        'headerVPad': 16.0,
        'maxWidthFactor': 0.95,
        'maxHeightFactor': 0.88,
      };
    }
    return {
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
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: sizes['headerHPad']!,
                vertical: sizes['headerVPad']!,
              ),
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
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimary
                                  .withValues(alpha: 0.9),
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
            Expanded(
              child: UniversalBoardTimeline(
                board: board,
                padding: EdgeInsets.all(sizes['padding']!),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
