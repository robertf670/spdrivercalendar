import 'package:flutter/widgets.dart';

/// Side inset for a phone dialog. About 10% of the screen, a little less
/// when text is large, and never more than 40.
double dialogHorizontalInset(BuildContext context) {
  return dialogHorizontalInsetFor(
    screenWidth: MediaQuery.sizeOf(context).width,
    textScale: MediaQuery.textScalerOf(context).scale(1.0),
  );
}

@visibleForTesting
double dialogHorizontalInsetFor({
  required double screenWidth,
  required double textScale,
}) {
  // About 10% of the width for both sides, and a little less when text
  // is large. Never wider than the old 40px inset, so a phone just over
  // 350px wide keeps more room instead of jumping straight to 40.
  final sideFraction = textScale > 1.12 ? 0.03 : 0.05;
  final inset = screenWidth * sideFraction;
  if (inset < 8) return 8;
  if (inset > 40) return 40;
  return inset;
}
