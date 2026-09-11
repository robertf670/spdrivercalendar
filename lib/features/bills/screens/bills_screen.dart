import 'package:flutter/material.dart';
import 'package:spdrivercalendar/features/bills/models/bill_duty.dart';
import 'package:spdrivercalendar/features/bills/services/bills_csv_service.dart';
import 'package:spdrivercalendar/features/bills/services/board_lookup.dart';
import 'package:spdrivercalendar/features/bills/widgets/bill_duty_index_list.dart';
import 'package:spdrivercalendar/features/calendar/services/roster_service.dart';
import 'package:spdrivercalendar/features/calendar/widgets/universal_board_timeline.dart';
import 'package:spdrivercalendar/models/universal_board.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';

enum _BillsHubTab { bills, boards }

class BillsScreen extends StatefulWidget {
  const BillsScreen({
    super.key,
    this.now,
    this.initialZone,
    this.initialDayType,
  });

  /// Used to default the day type from "today". Tests can inject a fixed date.
  final DateTime? now;
  final String? initialZone;
  final String? initialDayType;

  @override
  BillsScreenState createState() => BillsScreenState();
}

class BillsScreenState extends State<BillsScreen> {
  static const _zones = ['Zone 1', 'Zone 2', 'Zone 3', 'Zone 4', 'Uni/Euro'];
  static const _dayTypes = ['M-F', 'Sat', 'Sun'];

  late String _selectedDayType;
  late String _selectedZone;
  _BillsHubTab _tab = _BillsHubTab.bills;

  bool _isLoading = false;
  List<BillDuty> _duties = [];
  Set<String> _boardCodes = {};
  String? _errorMessage;
  bool _isComingSoon = false;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _searchOpen = false;
  String? _focusedShift;
  String? _expandedShift;
  final GlobalKey<BillDutyIndexListState> _indexKey = GlobalKey();
  BillDuty? _selectedBoardDuty;
  UniversalBoard? _selectedBoard;
  bool _loadingBoard = false;
  String? _boardError;

  DateTime get _now => widget.now ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedZone = widget.initialZone ?? 'Zone 1';
    _selectedDayType = widget.initialDayType ?? _dayTypeForDate(_now);
    _searchController.addListener(() {
      final query = _searchController.text;
      if (query == _searchQuery) return;
      setState(() => _searchQuery = query);
    });
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static String _dayTypeForDate(DateTime date) {
    if (RosterService.isSaturdayService(date) ||
        date.weekday == DateTime.saturday) {
      return 'Sat';
    }
    if (date.weekday == DateTime.sunday) return 'Sun';
    return 'M-F';
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isComingSoon = false;
    });

    final result = await BillsCsvService.load(
      zone: _selectedZone,
      dayType: _selectedDayType,
      eraDate: _now,
    );
    final boardCodes = await BoardLookup.dutyCodesFor(
      zone: _selectedZone,
      dayType: _selectedDayType,
      date: _now,
    );

    if (!mounted) return;

    final selectedShift = _selectedBoardDuty?.shift;
    BillDuty? selectedMatch;
    if (selectedShift != null) {
      for (final duty in result.duties) {
        if (duty.shift == selectedShift) {
          selectedMatch = duty;
          break;
        }
      }
    }

    setState(() {
      _duties = result.duties;
      _boardCodes = boardCodes;
      _isComingSoon = result.isComingSoon;
      _errorMessage = result.error;
      _isLoading = false;
      if (selectedShift != null && selectedMatch == null) {
        _selectedBoardDuty = null;
        _selectedBoard = null;
        _boardError = null;
      }
    });

    if (selectedMatch != null) {
      await _openBoard(selectedMatch, switchTab: false);
    }
  }

  List<BillDuty> get _filteredDuties {
    return _duties.where((duty) => duty.matchesQuery(_searchQuery)).toList();
  }

  Future<void> _openBoard(BillDuty duty, {bool switchTab = true}) async {
    setState(() {
      if (switchTab) _tab = _BillsHubTab.boards;
      _focusedShift = duty.shift;
      _selectedBoardDuty = duty;
      _loadingBoard = true;
      _boardError = null;
      _selectedBoard = null;
    });

    final board = await BoardLookup.load(
      shift: duty.shift,
      dayType: _selectedDayType,
      date: _now,
    );

    if (!mounted) return;
    setState(() {
      _loadingBoard = false;
      _selectedBoard = board;
      if (board == null) {
        _boardError = 'No running board for ${duty.shift} on this day type.';
      }
    });
  }

  void _showBill(BillDuty duty) {
    setState(() {
      _tab = _BillsHubTab.bills;
      _searchOpen = false;
      _searchController.clear();
      _focusedShift = duty.shift;
      _expandedShift = duty.shift;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _indexKey.currentState?.jumpToDuty(duty.shift);
    });
  }

  void _onIndexDutyTap(BillDuty duty) {
    if (_tab == _BillsHubTab.boards) {
      _openBoard(duty, switchTab: false);
      return;
    }
    setState(() {
      _expandedShift = _expandedShift == duty.shift ? null : duty.shift;
      _focusedShift = duty.shift;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _indexKey.currentState?.jumpToDuty(duty.shift);
    });
  }

  void _clearBoardSelection() {
    setState(() {
      _selectedBoardDuty = null;
      _selectedBoard = null;
      _boardError = null;
    });
  }

  Map<String, double> _sizes(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 350) {
      return {'padding': 8.0, 'gap': 8.0, 'fontSize': 12.0};
    }
    if (width < 400) {
      return {'padding': 10.0, 'gap': 10.0, 'fontSize': 13.0};
    }
    if (width < 450) {
      return {'padding': 12.0, 'gap': 12.0, 'fontSize': 13.0};
    }
    return {'padding': 16.0, 'gap': 12.0, 'fontSize': 14.0};
  }

  @override
  Widget build(BuildContext context) {
    final sizes = _sizes(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bills & Boards'),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: _searchOpen ? 'Close search' : 'Search',
            icon: Icon(_searchOpen ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _searchOpen = !_searchOpen;
                if (!_searchOpen) {
                  _searchController.clear();
                }
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            sizes['padding']!,
            sizes['padding']!,
            sizes['padding']!,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildFilterCard(context, sizes),
              SizedBox(height: sizes['gap']!),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterCard(
    BuildContext context,
    Map<String, double> sizes,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      padding: EdgeInsets.all(sizes['padding']!),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _menuField(
                  value: _selectedZone,
                  options: _zones,
                  menuKey: const ValueKey('bills-zone-menu'),
                  onSelected: (zone) {
                    if (zone == _selectedZone) return;
                    setState(() {
                      _selectedZone = zone;
                      _focusedShift = null;
                      _expandedShift = null;
                      _selectedBoardDuty = null;
                      _selectedBoard = null;
                      _boardError = null;
                    });
                    _loadData();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _menuField(
                  value: _selectedDayType,
                  options: _dayTypes,
                  onSelected: (dayType) {
                    if (dayType == _selectedDayType) return;
                    setState(() {
                      _selectedDayType = dayType;
                      _expandedShift = null;
                    });
                    _loadData();
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: sizes['gap']!),
          _viewToggle(),
          if (_searchOpen) ...[
            SizedBox(height: sizes['gap']!),
            TextField(
              controller: _searchController,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Duty, time, or location',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _searchController.clear,
                      ),
                isDense: true,
                filled: true,
                fillColor:
                    scheme.surfaceContainerHighest.withValues(alpha: 0.45),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _menuField({
    required String value,
    required List<String> options,
    required ValueChanged<String> onSelected,
    Key? menuKey,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    return PopupMenuButton<String>(
      key: menuKey,
      initialValue: value,
      tooltip: value,
      position: PopupMenuPosition.under,
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final option in options)
          PopupMenuItem<String>(
            value: option,
            child: Text(option),
          ),
      ],
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: width < 350 ? 10 : 12,
          vertical: width < 350 ? 10 : 12,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.45)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: width < 350 ? 13 : 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.expand_more,
              size: 20,
              color: scheme.onSurface.withValues(alpha: 0.55),
            ),
          ],
        ),
      ),
    );
  }

  Widget _viewToggle() {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.45)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Row(
          children: [
            Expanded(
              child: _viewToggleCell(
                label: 'Bills',
                selected: _tab == _BillsHubTab.bills,
                onTap: () => setState(() => _tab = _BillsHubTab.bills),
              ),
            ),
            Expanded(
              child: _viewToggleCell(
                label: 'Boards',
                selected: _tab == _BillsHubTab.boards,
                onTap: () => setState(() => _tab = _BillsHubTab.boards),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _viewToggleCell({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    return Material(
      color: selected ? AppTheme.primaryColor : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: width < 350 ? 10 : 12,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: width < 350 ? 13 : 14,
              fontWeight: FontWeight.w700,
              color: selected
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.primaryColor),
            SizedBox(height: 16),
            Text('Loading duties…'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return _messageState(
        icon: Icons.error_outline,
        title: _errorMessage!,
        actionLabel: 'Retry',
        onAction: _loadData,
        isError: true,
      );
    }

    if (_isComingSoon) {
      return _messageState(
        icon: Icons.directions_bus_outlined,
        title: 'Zone 2 coming soon',
        subtitle:
            'Route 13 bills and boards will show here when they are published.',
      );
    }

    if (_tab == _BillsHubTab.boards) {
      return _buildBoardsTab();
    }
    return _buildBillsTab();
  }

  Widget _buildBillsTab() {
    final duties = _filteredDuties;
    if (_duties.isEmpty) {
      return _messageState(
        icon: Icons.receipt_long_outlined,
        title: 'No duties on this bill',
      );
    }
    if (duties.isEmpty) {
      return _messageState(
        icon: Icons.search_off,
        title: 'No duties match “$_searchQuery”',
      );
    }

    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '${duties.length} ${duties.length == 1 ? 'duty' : 'duties'}',
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        Expanded(
          child: BillDutyIndexList(
            key: _indexKey,
            duties: duties,
            boardCodes: _boardCodes,
            expandedShift: _expandedShift,
            focusedShift: _focusedShift,
            onDutyTap: _onIndexDutyTap,
            onViewBoard: _openBoard,
          ),
        ),
      ],
    );
  }

  Widget _buildBoardsTab() {
    if (_selectedBoardDuty != null) {
      return _buildBoardViewer();
    }

    final duties = _filteredDuties
        .where((duty) => _boardCodes.contains(duty.shift))
        .toList();

    if (_duties.isEmpty) {
      return _messageState(
        icon: Icons.view_timeline_outlined,
        title: 'No boards on this bill',
      );
    }
    if (duties.isEmpty) {
      return _messageState(
        icon: Icons.search_off,
        title: _searchQuery.isEmpty
            ? 'No boards for this zone and day type'
            : 'No boards match “$_searchQuery”',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            'Pick a duty',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        Expanded(
          child: BillDutyIndexList(
            key: _indexKey,
            duties: duties,
            boardCodes: _boardCodes,
            focusedShift: _focusedShift,
            expandOnTap: false,
            onDutyTap: _onIndexDutyTap,
          ),
        ),
      ],
    );
  }

  Widget _buildBoardViewer() {
    final duty = _selectedBoardDuty!;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(4, 4, 8, 10),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              IconButton(
                tooltip: 'All boards',
                icon: const Icon(Icons.arrow_back),
                onPressed: _clearBoardSelection,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      duty.shift,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      [
                        if (duty.displayReport.isNotEmpty &&
                            duty.displaySignOff.isNotEmpty)
                          '${duty.displayReport}  →  ${duty.displaySignOff}',
                        '$_selectedDayType · $_selectedZone',
                      ].join('  ·  '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: scheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => _showBill(duty),
                child: const Text('See bill'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: _boardContent()),
      ],
    );
  }

  Widget _boardContent() {
    if (_loadingBoard) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_boardError != null || _selectedBoard == null) {
      return _messageState(
        icon: Icons.view_timeline_outlined,
        title: _boardError ?? 'No running board for this duty',
      );
    }
    return UniversalBoardTimeline(
      board: _selectedBoard!,
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 16),
    );
  }

  Widget _messageState({
    required IconData icon,
    required String title,
    String? subtitle,
    String? actionLabel,
    VoidCallback? onAction,
    bool isError = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 48,
              color: isError ? scheme.error : scheme.primary.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: scheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onAction, child: Text(actionLabel)),
            ],
          ],
        ),
      ),
    );
  }
}
