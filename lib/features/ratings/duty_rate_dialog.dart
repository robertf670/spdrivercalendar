import 'package:flutter/material.dart';
import 'package:spdrivercalendar/features/ratings/duty_rating_key.dart';
import 'package:spdrivercalendar/features/ratings/duty_rating_service.dart';
import 'package:spdrivercalendar/features/ratings/duty_rating_vote.dart';

Future<DutyRatingVote?> showDutyRateDialog(
  BuildContext context, {
  required DutyRatingTarget target,
  DutyRatingVote? existing,
}) {
  return showDialog<DutyRatingVote>(
    context: context,
    builder: (context) => DutyRateDialog(target: target, existing: existing),
  );
}

class DutyRateDialog extends StatefulWidget {
  const DutyRateDialog({
    super.key,
    required this.target,
    this.existing,
  });

  final DutyRatingTarget target;
  final DutyRatingVote? existing;

  @override
  State<DutyRateDialog> createState() => _DutyRateDialogState();
}

class _DutyRateDialogState extends State<DutyRateDialog> {
  late int _score;
  late final TextEditingController _noteController;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _score = widget.existing?.score ?? 7;
    _noteController = TextEditingController(text: widget.existing?.note ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _remove() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove rating?'),
        content: const Text(
          'This takes your score and note off the community average.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await DutyRatingService.deleteOwnVote(widget.target);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Could not remove rating. Try again.';
      });
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final vote = await DutyRatingService.saveVote(
        target: widget.target,
        score: _score,
        note: _noteController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(vote);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Could not save rating. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final dialogWidth = width * 0.9 < 500 ? width * 0.9 : 500.0;
    final isUpdate = widget.existing != null;
    final era = DutyRatingKey.eraLabel(widget.target.era);

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: Text(isUpdate ? 'Update rating' : 'Rate duty'),
      content: SizedBox(
        width: dialogWidth,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.target.dutyCode} · ${DutyRatingKey.dayTypeLabel(widget.target.dayType)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (era.isNotEmpty)
                Text(era, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 16),
              Text('Score', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (var score = 1; score <= 10; score++)
                    ChoiceChip(
                      label: Text('$score'),
                      selected: _score == score,
                      onSelected: _saving
                          ? null
                          : (_) => setState(() => _score = score),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _noteController,
                enabled: !_saving,
                maxLength: DutyRatingVote.maxNoteLength,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        if (isUpdate)
          TextButton(
            onPressed: _saving ? null : _remove,
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Remove'),
          ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isUpdate ? 'Update' : 'Save'),
        ),
      ],
    );
  }
}
