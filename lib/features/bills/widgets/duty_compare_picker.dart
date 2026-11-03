import 'package:flutter/material.dart';
import 'package:spdrivercalendar/features/bills/models/bill_duty.dart';
import 'package:spdrivercalendar/features/bills/services/bills_csv_service.dart';
import 'package:spdrivercalendar/features/bills/utils/bills_default_zone.dart';
import 'package:spdrivercalendar/features/bills/widgets/bill_duty_index_list.dart';

/// A duty plus the bill it was taken from.
class DutyComparePick {
  const DutyComparePick({
    required this.duty,
    required this.zone,
    required this.dayType,
  });

  final BillDuty duty;
  final String zone;
  final String dayType;
}

/// Any zone, any day, then the same jump list as the bill.
class DutyComparePicker extends StatefulWidget {
  const DutyComparePicker({
    super.key,
    required this.initialZone,
    required this.initialDayType,
    required this.date,
    required this.cache,
    required this.onSelected,
  });

  final String initialZone;
  final String initialDayType;
  final DateTime date;
  final Map<String, List<BillDuty>> cache;
  final ValueChanged<DutyComparePick> onSelected;

  static const dayTypes = ['M-F', 'Sat', 'Sun'];

  @override
  State<DutyComparePicker> createState() => _DutyComparePickerState();
}

class _DutyComparePickerState extends State<DutyComparePicker> {
  final TextEditingController _search = TextEditingController();
  late String _zone;
  late String _dayType;
  String _query = '';
  bool _searchOpen = false;
  bool _loading = false;
  String? _error;
  List<BillDuty> _duties = const [];

  @override
  void initState() {
    super.initState();
    _zone = widget.initialZone;
    _dayType = widget.initialDayType;
    _applyCacheOrLoad();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String get _cacheKey => '$_zone|$_dayType';

  void _applyCacheOrLoad() {
    final cached = widget.cache[_cacheKey];
    if (cached != null) {
      _duties = cached;
      _loading = false;
      _error = null;
      return;
    }
    _loading = true;
    _error = null;
    _duties = const [];
    _load();
  }

  Future<void> _load() async {
    final key = _cacheKey;
    final result = await BillsCsvService.load(
      zone: _zone,
      dayType: _dayType,
      eraDate: widget.date,
    );
    if (!mounted || key != _cacheKey) return;
    setState(() {
      _loading = false;
      if (result.error != null) {
        _error = result.error;
        _duties = const [];
      } else {
        _error = null;
        _duties = result.duties;
        widget.cache[key] = result.duties;
      }
    });
  }

  void _setZone(String zone) {
    if (zone == _zone) return;
    setState(() {
      _zone = zone;
      _applyCacheOrLoad();
    });
  }

  void _setDayType(String dayType) {
    if (dayType == _dayType) return;
    setState(() {
      _dayType = dayType;
      _applyCacheOrLoad();
    });
  }

  @override
  Widget build(BuildContext context) {
    final matches =
        _duties.where((duty) => duty.matchesQuery(_query)).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _FilterMenu(
                  menuKey: const ValueKey('compare-zone-menu'),
                  value: _zone,
                  options: billsZones,
                  onSelected: _setZone,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _FilterMenu(
                  menuKey: const ValueKey('compare-day-menu'),
                  value: _dayType,
                  options: DutyComparePicker.dayTypes,
                  onSelected: _setDayType,
                ),
              ),
              IconButton(
                tooltip: _searchOpen ? 'Close search' : 'Search',
                onPressed: () {
                  setState(() {
                    _searchOpen = !_searchOpen;
                    if (!_searchOpen) {
                      _search.clear();
                      _query = '';
                    }
                  });
                },
                icon: Icon(_searchOpen ? Icons.close : Icons.search),
              ),
            ],
          ),
          if (_searchOpen) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _search,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Duty or time',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ],
          const SizedBox(height: 8),
          Expanded(child: _body(matches)),
        ],
      ),
    );
  }

  Widget _body(List<BillDuty> matches) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    if (matches.isEmpty) {
      return const Center(child: Text('No matching duties.'));
    }
    return BillDutyIndexList(
      duties: matches,
      boardCodes: const {},
      expandOnTap: false,
      onDutyTap: (duty) {
        widget.onSelected(
          DutyComparePick(duty: duty, zone: _zone, dayType: _dayType),
        );
      },
    );
  }
}

class _FilterMenu extends StatelessWidget {
  const _FilterMenu({
    required this.value,
    required this.options,
    required this.onSelected,
    this.menuKey,
  });

  final String value;
  final List<String> options;
  final ValueChanged<String> onSelected;
  final Key? menuKey;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Icon(
              Icons.expand_more,
              size: 18,
              color: scheme.onSurface.withValues(alpha: 0.55),
            ),
          ],
        ),
      ),
    );
  }
}
