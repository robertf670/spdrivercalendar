import 'package:flutter/material.dart';

/// Strong fill + label contrast for accent [ElevatedButton]s in dialogs.
///
/// Material 3 applies a [surfaceTint] on [ElevatedButton]; on custom greens/purples
/// that reads as a pale grey fill in dark mode with poor text contrast.
ButtonStyle dialogAccentElevatedStyle(
  BuildContext context,
  Color backgroundColor,
) {
  final cs = Theme.of(context).colorScheme;
  return ElevatedButton.styleFrom(
    backgroundColor: backgroundColor,
    foregroundColor: Colors.white,
    disabledBackgroundColor: cs.surfaceContainerHighest,
    disabledForegroundColor: cs.onSurface.withValues(alpha: 0.38),
    surfaceTintColor: Colors.transparent,
    shadowColor: Colors.black26,
    elevation: 2,
  );
}

/// Footer actions laid out with [Wrap] so long labels at large text scale do
/// not overflow.
Widget dialogFooterActions({
  required List<Widget> children,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: SizedBox(
      width: double.infinity,
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: children,
      ),
    ),
  );
}
