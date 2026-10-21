import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:spdrivercalendar/features/calendar/widgets/universal_board_timeline.dart';
import 'package:spdrivercalendar/models/universal_board.dart';

/// Logical width of a shared board image.
///
/// Every phone paints the same width, with text scale 1, so the PNG does not
/// change with the screen size or the system text size. 420 picks the larger
/// type size used by the on-screen board.
const double boardShareWidth = 420;

/// Longest side of the PNG, in pixels. Tall boards drop the pixel ratio so the
/// image still fits in one shot.
const double boardShareMaxPixels = 8192;

String boardShareFileName(UniversalBoard board) {
  var safe = board.shift.replaceAll(RegExp(r'[/\\:*?"<>|]'), '_');
  safe = safe.replaceAll(RegExp(r'\s+'), '_');
  if (safe.length > 80) {
    safe = safe.substring(0, 80);
  }
  if (safe.isEmpty) {
    safe = 'board';
  }
  return 'board_$safe.png';
}

/// Paints [board] at [boardShareWidth] and returns a PNG of the whole board,
/// including parts that are scrolled out of view.
///
/// The sheet is added to the overlay for one frame so it can be painted, then
/// removed. Text scale is forced to 1 and the width is fixed, so the image
/// matches across phones.
Future<Uint8List> captureBoardPng({
  required BuildContext context,
  required UniversalBoard board,
}) async {
  final theme = Theme.of(context);
  final boundaryKey = GlobalKey();
  final overlay = Overlay.of(context, rootOverlay: true);
  final entry = OverlayEntry(
    builder: (overlayContext) {
      return Positioned(
        left: 0,
        top: 0,
        width: boardShareWidth,
        child: IgnorePointer(
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minHeight: 0,
            maxHeight: double.infinity,
            fit: OverflowBoxFit.deferToChild,
            child: Opacity(
              opacity: 0.02,
              child: RepaintBoundary(
                key: boundaryKey,
                child: _captureTree(theme, board),
              ),
            ),
          ),
        ),
      );
    },
  );

  overlay.insert(entry);
  try {
    await WidgetsBinding.instance.endOfFrame;
    final boundary = boundaryKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null || !boundary.hasSize || boundary.size.isEmpty) {
      throw StateError('Board capture had no size.');
    }

    final longest = math.max(boundary.size.width, boundary.size.height);
    final pixelRatio = (boardShareMaxPixels / longest).clamp(1.0, 3.0);
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    try {
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw StateError('Could not create image.');
      }
      return byteData.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  } finally {
    entry.remove();
  }
}

Widget _captureTree(ThemeData theme, UniversalBoard board) {
  return MediaQuery(
    data: const MediaQueryData(
      size: Size(boardShareWidth, 800),
      textScaler: TextScaler.noScaling,
      devicePixelRatio: 1,
      padding: EdgeInsets.zero,
      viewPadding: EdgeInsets.zero,
    ),
    child: Theme(
      data: theme,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: BoardShareSheet(board: board),
      ),
    ),
  );
}

/// Fixed-width board used only for the share image.
class BoardShareSheet extends StatelessWidget {
  const BoardShareSheet({super.key, required this.board});

  final UniversalBoard board;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onPrimary = scheme.onPrimary;

    return Material(
      color: scheme.surface,
      child: SizedBox(
        width: boardShareWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ColoredBox(
              color: scheme.primary,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Board ${board.shift}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: onPrimary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                    ),
                    if (board.duty != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Duty ${board.duty}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: onPrimary.withValues(alpha: 0.9),
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            UniversalBoardTimeline(
              board: board,
              scrollable: false,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            ),
          ],
        ),
      ),
    );
  }
}
