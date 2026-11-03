import 'package:flutter/material.dart';
import 'package:spdrivercalendar/features/bills/utils/duty_compare.dart';

/// Both duties on one clock, so a swap is a shape and not a list of numbers.
class DutyCompareTimeline extends StatelessWidget {
  const DutyCompareTimeline({
    super.key,
    required this.compare,
    required this.yoursColor,
    required this.theirsColor,
  });

  final DutyCompare compare;
  final Color yoursColor;
  final Color theirsColor;

  @override
  Widget build(BuildContext context) {
    if (!compare.hasClock) {
      return Text(
        'These duties do not both have a report and a finish.',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    final scheme = Theme.of(context).colorScheme;
    final axisStart = compare.axisStart!;
    final axisEnd = compare.axisEnd!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _lane(
          context,
          label: 'Yours',
          color: yoursColor,
          span: compare.yoursSpan!,
          axisStart: axisStart,
          axisEnd: axisEnd,
        ),
        const SizedBox(height: 8),
        _lane(
          context,
          label: 'Theirs',
          color: theirsColor,
          span: compare.theirsSpan!,
          axisStart: axisStart,
          axisEnd: axisEnd,
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const SizedBox(width: 52),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DutyCompare.formatClock(axisStart),
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurface.withValues(alpha: 0.55),
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    DutyCompare.formatClock(axisEnd),
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurface.withValues(alpha: 0.55),
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _lane(
    BuildContext context, {
    required String label,
    required Color color,
    required DutyDaySpan span,
    required int axisStart,
    required int axisEnd,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        SizedBox(
          width: 52,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
        Expanded(
          child: SizedBox(
            height: 18,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final total = axisEnd - axisStart;
                double at(int minute) =>
                    ((minute - axisStart) / total) * width;

                Widget segment(int from, int to) {
                  final left = at(from).clamp(0.0, width);
                  final right = at(to).clamp(0.0, width);
                  final size = right - left;
                  if (size <= 0) return const SizedBox.shrink();
                  return Positioned(
                    left: left,
                    width: size,
                    top: 0,
                    bottom: 0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  );
                }

                final pieces = <Widget>[
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ];
                if (span.hasBreak) {
                  pieces
                    ..add(segment(span.start, span.breakStart!))
                    ..add(segment(span.breakEnd!, span.end));
                } else {
                  pieces.add(segment(span.start, span.end));
                }

                return Stack(children: pieces);
              },
            ),
          ),
        ),
      ],
    );
  }
}
