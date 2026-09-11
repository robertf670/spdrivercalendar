import 'package:flutter/material.dart';
import 'package:spdrivercalendar/features/bills/models/bill_duty.dart';
import 'package:spdrivercalendar/features/bills/services/bills_duty_grouping.dart';
import 'package:spdrivercalendar/features/bills/widgets/bill_duty_card.dart';

/// Compact grouped duty list with jump chips, like flipping a paper bill.
class BillDutyIndexList extends StatefulWidget {
  const BillDutyIndexList({
    super.key,
    required this.duties,
    required this.boardCodes,
    this.expandedShift,
    this.focusedShift,
    this.expandOnTap = true,
    this.onDutyTap,
    this.onViewBoard,
  });

  final List<BillDuty> duties;
  final Set<String> boardCodes;
  final String? expandedShift;
  final String? focusedShift;
  final bool expandOnTap;
  final ValueChanged<BillDuty>? onDutyTap;
  final ValueChanged<BillDuty>? onViewBoard;

  @override
  BillDutyIndexListState createState() => BillDutyIndexListState();
}

class BillDutyIndexListState extends State<BillDutyIndexList> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _groupKeys = {};
  final Map<String, GlobalKey> _dutyKeys = {};

  List<BillDutyGroup> get _groups => BillsDutyGrouping.group(widget.duties);

  String? get _stripPrefix => BillsDutyGrouping.sharedPrefix(widget.duties);

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _labelFor(BillDuty duty) {
    final prefix = _stripPrefix;
    if (prefix != null && duty.shift.startsWith('$prefix/')) {
      return duty.shortCode;
    }
    return duty.shift;
  }

  Future<void> jumpToGroup(String groupId) async {
    final context = _groupKeys[groupId]?.currentContext;
    if (context == null) return;
    await Scrollable.ensureVisible(
      context,
      alignment: 0.02,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> jumpToDuty(String shift) async {
    final context = _dutyKeys[shift]?.currentContext;
    if (context == null) return;
    await Scrollable.ensureVisible(
      context,
      alignment: 0.15,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groups;
    if (groups.isEmpty) {
      return const SizedBox.shrink();
    }

    final showJump = groups.length > 1 && widget.duties.length >= 16;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        if (showJump)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 0; i < groups.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    ActionChip(
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      label: Text(groups[i].label),
                      onPressed: () => jumpToGroup(groups[i].id),
                      backgroundColor: scheme.surfaceContainerHighest
                          .withValues(alpha: 0.7),
                    ),
                  ],
                ],
              ),
            ),
          ),
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final group in groups)
                  KeyedSubtree(
                    key: _groupKeys.putIfAbsent(group.id, GlobalKey.new),
                    child: _buildGroup(context, group),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGroup(BuildContext context, BillDutyGroup group) {
    final scheme = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final titleSize = width < 350 ? 12.0 : 13.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 10, 4, 6),
          child: Text(
            group.label,
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.55),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Column(
              children: [
                for (var i = 0; i < group.duties.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      color: scheme.outlineVariant.withValues(alpha: 0.45),
                    ),
                  _buildDuty(context, group.duties[i]),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDuty(BuildContext context, BillDuty duty) {
    final expanded = widget.expandedShift == duty.shift;
    final hasBoard = widget.boardCodes.contains(duty.shift);
    return KeyedSubtree(
      key: _dutyKeys.putIfAbsent(duty.shift, GlobalKey.new),
      child: Column(
        children: [
          BillDutyListRow(
            duty: duty,
            label: _labelFor(duty),
            selected: expanded || widget.focusedShift == duty.shift,
            hasBoard: hasBoard && !widget.expandOnTap,
            onTap: () => widget.onDutyTap?.call(duty),
          ),
          if (expanded && widget.expandOnTap)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
              child: BillDutyCard(
                duty: duty,
                hasBoard: hasBoard,
                highlighted: true,
                onTap: hasBoard ? () => widget.onViewBoard?.call(duty) : null,
              ),
            ),
        ],
      ),
    );
  }
}
