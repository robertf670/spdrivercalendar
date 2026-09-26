import 'package:flutter/material.dart';
import 'package:spdrivercalendar/features/ratings/duty_rate_dialog.dart';
import 'package:spdrivercalendar/features/ratings/duty_rating_key.dart';
import 'package:spdrivercalendar/features/ratings/duty_rating_service.dart';
import 'package:spdrivercalendar/features/ratings/duty_rating_vote.dart';
import 'package:spdrivercalendar/models/event.dart';

enum DutyRateMenuStyle { column, compact }

class DutyRateMenuActions extends StatefulWidget {
  const DutyRateMenuActions({
    super.key,
    required this.event,
    this.style = DutyRateMenuStyle.column,
  });

  final Event event;
  final DutyRateMenuStyle style;

  @override
  State<DutyRateMenuActions> createState() => _DutyRateMenuActionsState();
}

class _DutyRateMenuActionsState extends State<DutyRateMenuActions> {
  late Future<_DutyRateMenuData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant DutyRateMenuActions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.event.id != widget.event.id) {
      _future = _load();
    }
  }

  Future<_DutyRateMenuData> _load() async {
    final enabled = await DutyRatingService.isEnabled();
    final targets = DutyRatingKey.targetsForCalendarEvent(widget.event);
    final afterSignOff = DutyRatingKey.eventIsAfterSignOff(widget.event);
    final canShow = DutyRatingKey.canShowRateAction(
      settingsEnabled: enabled,
      isRateable: targets.isNotEmpty,
      afterSignOff: afterSignOff,
    );
    if (!canShow) {
      return const _DutyRateMenuData(canShow: false);
    }
    final votes = await DutyRatingService.getVotesForTargets(targets);
    return _DutyRateMenuData(canShow: true, targets: targets, votes: votes);
  }

  Future<void> _open(
    DutyRatingTarget target,
    DutyRatingVote? existing,
  ) async {
    await showDutyRateDialog(context, target: target, existing: existing);
    if (!mounted) return;
    setState(() {
      _future = _load();
    });
  }

  Future<void> _openFromCompact(_DutyRateMenuData data) async {
    if (data.targets.length == 1) {
      final target = data.targets.single;
      await _open(target, data.votes[target.summaryId]);
      return;
    }

    final selected = await showDialog<DutyRatingTarget>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Rate duty'),
          children: [
            for (final target in data.targets)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, target),
                child: Text(
                  _labelFor(
                    target,
                    data.votes[target.summaryId],
                    showDuty: true,
                  ),
                ),
              ),
          ],
        );
      },
    );
    if (selected == null || !mounted) return;
    await _open(selected, data.votes[selected.summaryId]);
  }

  String _labelFor(
    DutyRatingTarget target,
    DutyRatingVote? vote, {
    required bool showDuty,
  }) {
    if (vote == null) {
      return showDuty ? 'Rate ${target.dutyCode}' : 'Rate duty';
    }
    return showDuty
        ? 'Your rating: ${vote.score} (${target.dutyCode})'
        : 'Your rating: ${vote.score}';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_DutyRateMenuData>(
      future: _future,
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (data == null || !data.canShow) {
          return const SizedBox.shrink();
        }

        if (widget.style == DutyRateMenuStyle.compact) {
          final anyRated = data.targets.any(
            (target) => data.votes.containsKey(target.summaryId),
          );
          final label = data.targets.length == 1
              ? _labelFor(
                  data.targets.single,
                  data.votes[data.targets.single.summaryId],
                  showDuty: false,
                )
              : anyRated
                  ? 'Your ratings'
                  : 'Rate duty';
          return TextButton(
            onPressed: () => _openFromCompact(data),
            child: Text(label),
          );
        }

        return Column(
          children: [
            for (final target in data.targets) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => _open(target, data.votes[target.summaryId]),
                child: Text(
                  _labelFor(
                    target,
                    data.votes[target.summaryId],
                    showDuty: data.targets.length > 1,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _DutyRateMenuData {
  const _DutyRateMenuData({
    required this.canShow,
    this.targets = const [],
    this.votes = const {},
  });

  final bool canShow;
  final List<DutyRatingTarget> targets;
  final Map<String, DutyRatingVote> votes;
}
