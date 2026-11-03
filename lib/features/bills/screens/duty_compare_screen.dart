import 'package:flutter/material.dart';
import 'package:spdrivercalendar/features/bills/models/bill_duty.dart';
import 'package:spdrivercalendar/features/bills/services/board_lookup.dart';
import 'package:spdrivercalendar/features/bills/utils/duty_compare.dart';
import 'package:spdrivercalendar/features/bills/widgets/duty_compare_picker.dart';
import 'package:spdrivercalendar/features/bills/widgets/duty_compare_timeline.dart';
import 'package:spdrivercalendar/features/calendar/widgets/universal_board_timeline.dart';
import 'package:spdrivercalendar/models/universal_board.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';

/// Puts two bill duties on one clock before a swap.
class DutyCompareScreen extends StatefulWidget {
  const DutyCompareScreen({
    super.key,
    required this.duties,
    required this.zone,
    required this.dayType,
    required this.date,
    this.initialYoursShift,
  });

  final List<BillDuty> duties;
  final String zone;
  final String dayType;
  final DateTime date;
  final String? initialYoursShift;

  @override
  State<DutyCompareScreen> createState() => _DutyCompareScreenState();
}

class _Side {
  _Side({required this.zone, required this.dayType, this.duty});

  BillDuty? duty;
  String zone;
  String dayType;
  UniversalBoard? board;
}

class _DutyCompareScreenState extends State<DutyCompareScreen> {
  late final _Side _yours;
  late final _Side _theirs;
  final Map<String, List<BillDuty>> _billCache = {};
  bool _loadingBoards = false;
  bool _boardsOpen = false;
  bool _browsing = true;
  bool _targetYours = true;

  static const _yoursColor = AppTheme.primaryColor;
  static const _theirsColor = AppTheme.secondaryColor;

  @override
  void initState() {
    super.initState();
    BillDuty? yours;
    final shift = widget.initialYoursShift;
    if (shift != null) {
      for (final duty in widget.duties) {
        if (duty.shift == shift) {
          yours = duty;
          break;
        }
      }
    }
    _yours = _Side(zone: widget.zone, dayType: widget.dayType, duty: yours);
    _theirs = _Side(zone: widget.zone, dayType: widget.dayType);
    _targetYours = yours == null;
    if (widget.duties.isNotEmpty) {
      _billCache['${widget.zone}|${widget.dayType}'] = widget.duties;
    }
  }

  void _edit(bool yours) {
    setState(() {
      _targetYours = yours;
      _browsing = true;
    });
  }

  void _assign(DutyComparePick picked) {
    final side = _targetYours ? _yours : _theirs;
    setState(() {
      side.duty = picked.duty;
      side.zone = picked.zone;
      side.dayType = picked.dayType;
      side.board = null;
      _boardsOpen = false;
      _yours.board = null;
      _theirs.board = null;
      if (_yours.duty != null && _theirs.duty != null) {
        _browsing = false;
      } else {
        _targetYours = _yours.duty == null;
      }
    });
  }

  void _swap() {
    setState(() {
      final yoursDuty = _yours.duty;
      final yoursZone = _yours.zone;
      final yoursDay = _yours.dayType;
      final yoursBoard = _yours.board;
      _yours.duty = _theirs.duty;
      _yours.zone = _theirs.zone;
      _yours.dayType = _theirs.dayType;
      _yours.board = _theirs.board;
      _theirs.duty = yoursDuty;
      _theirs.zone = yoursZone;
      _theirs.dayType = yoursDay;
      _theirs.board = yoursBoard;
    });
  }

  Future<void> _loadBoards() async {
    final yours = _yours.duty;
    final theirs = _theirs.duty;
    if (yours == null || theirs == null) return;
    setState(() {
      _boardsOpen = true;
      _loadingBoards = true;
    });
    final yoursBoard = await BoardLookup.load(
      shift: yours.shift,
      dayType: _yours.dayType,
      date: widget.date,
    );
    final theirsBoard = await BoardLookup.load(
      shift: theirs.shift,
      dayType: _theirs.dayType,
      date: widget.date,
    );
    if (!mounted) return;
    setState(() {
      _loadingBoards = false;
      _yours.board = yoursBoard;
      _theirs.board = theirsBoard;
    });
  }

  String _detail(_Side side, {required bool active}) {
    final duty = side.duty;
    if (duty == null) return active ? 'Next' : '';
    final time = duty.timeRange;
    if (side.dayType == 'M-F') return time;
    if (time.isEmpty) return side.dayType;
    return '${side.dayType} · $time';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final yours = _yours.duty;
    final theirs = _theirs.duty;
    final compare = yours != null && theirs != null
        ? DutyCompare.of(yours, theirs)
        : null;
    final showResult = !_browsing && compare != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compare duties'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _DutySlot(
                      caption: 'Yours',
                      color: _yoursColor,
                      duty: yours,
                      detail: _detail(_yours, active: _browsing && _targetYours),
                      active: _browsing && _targetYours,
                      onTap: () => _edit(true),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Swap sides',
                    onPressed: yours == null && theirs == null ? null : _swap,
                    icon: const Icon(Icons.swap_horiz),
                  ),
                  Expanded(
                    child: _DutySlot(
                      caption: 'Theirs',
                      color: _theirsColor,
                      duty: theirs,
                      detail: _detail(_theirs, active: _browsing && !_targetYours),
                      active: _browsing && !_targetYours,
                      onTap: () => _edit(false),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: IndexedStack(
                index: showResult ? 1 : 0,
                sizing: StackFit.expand,
                children: [
                  DutyComparePicker(
                    initialZone: widget.zone,
                    initialDayType: widget.dayType,
                    date: widget.date,
                    cache: _billCache,
                    onSelected: _assign,
                  ),
                  ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    children: [
                      if (compare != null) ...[
                        _Headline(text: compare.headline),
                        const SizedBox(height: 16),
                        DutyCompareTimeline(
                          compare: compare,
                          yoursColor: _yoursColor,
                          theirsColor: _theirsColor,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'A gap in the bar is the break.',
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                        const SizedBox(height: 16),
                        for (final line in compare.lines) ...[
                          _CompareLine(line: line),
                          const SizedBox(height: 8),
                        ],
                        const SizedBox(height: 8),
                        if (!_boardsOpen)
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _loadBoards,
                              child: const Text('Show running boards'),
                            ),
                          )
                        else if (_loadingBoards)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else ...[
                          _BoardBlock(
                            caption: 'Yours',
                            shift: compare.yours.shift,
                            color: _yoursColor,
                            board: _yours.board,
                          ),
                          const SizedBox(height: 16),
                          _BoardBlock(
                            caption: 'Theirs',
                            shift: compare.theirs.shift,
                            color: _theirsColor,
                            board: _theirs.board,
                          ),
                        ],
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DutySlot extends StatelessWidget {
  const _DutySlot({
    required this.caption,
    required this.color,
    required this.duty,
    required this.detail,
    required this.active,
    required this.onTap,
  });

  final String caption;
  final Color color;
  final BillDuty? duty;
  final String detail;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final picked = duty;
    return Material(
      color: color.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: color.withValues(alpha: active ? 1 : 0.45),
          width: active ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                caption,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                picked?.shift ?? 'Choose',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (detail.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurface.withValues(alpha: 0.7),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Headline extends StatelessWidget {
  const _Headline({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
        ),
      ),
    );
  }
}

class _CompareLine extends StatelessWidget {
  const _CompareLine({required this.line});

  final DutyCompareLine line;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final same = line.isSame;
            final delta = line.deltaMinutes;
            final note = same
                ? 'Same'
                : (delta == null || delta == 0)
                    ? ''
                    : DutyCompare.formatDelta(delta);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.7)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    line.label,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                if (note.isNotEmpty)
                  Text(
                    note,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: same
                          ? scheme.onSurface.withValues(alpha: 0.45)
                          : scheme.onSurface,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    line.yours.isEmpty ? '—' : line.yours,
                    style: TextStyle(
                      color: _DutyCompareScreenState._yoursColor,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    line.theirs.isEmpty ? '—' : line.theirs,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      color: _DutyCompareScreenState._theirsColor,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BoardBlock extends StatelessWidget {
  const _BoardBlock({
    required this.caption,
    required this.shift,
    required this.color,
    required this.board,
  });

  final String caption;
  final String shift;
  final Color color;
  final UniversalBoard? board;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '$caption · $shift',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        if (board == null)
          Text('No running board for $shift on this day.')
        else
          UniversalBoardTimeline(board: board!, scrollable: false),
      ],
    );
  }
}

