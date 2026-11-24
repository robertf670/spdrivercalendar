import 'package:flutter/material.dart';
import 'package:spdrivercalendar/features/bills/services/bills_csv_service.dart';
import 'package:spdrivercalendar/features/bills/services/bills_duty_grouping.dart';
import 'package:spdrivercalendar/features/duty_corrections/duty_correction.dart';
import 'package:spdrivercalendar/features/calendar/utils/zone_board_mapper.dart';
import 'package:spdrivercalendar/features/settings/screens/route13_correction_editor.dart';
import 'package:spdrivercalendar/services/zone_board_service.dart';

/// Lists Zone 1, Route 13, Zone 3, and Zone 4 duties for a remote correction.
class Route13CorrectionsScreen extends StatefulWidget {
  const Route13CorrectionsScreen({super.key});

  @override
  State<Route13CorrectionsScreen> createState() =>
      _Route13CorrectionsScreenState();
}

class _DutyGroup {
  const _DutyGroup(this.label, this.duties);

  final String label;
  final List<String> duties;
}

class _Route13CorrectionsScreenState extends State<Route13CorrectionsScreen> {
  static const _zones = ['Zone 1', 'Route 13', 'Zone 3', 'Zone 4'];
  static const _dayTypes = ['M-F', 'Sat', 'Sun'];
  static const _eras = <String, String>{
    DutyCorrection.zone4CurrentEra: 'From 23 Aug 2026',
    DutyCorrection.zone4PreviousEra: '19 Oct 2025',
    DutyCorrection.zone4LegacyEra: 'Before Oct 2025',
  };

  final TextEditingController _search = TextEditingController();
  String _zone = 'Zone 1';
  String _era = DutyCorrection.zone4CurrentEra;
  String _dayType = 'M-F';
  late Future<List<String>> _duties;

  @override
  void initState() {
    super.initState();
    _duties = _load();
    _search.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String get _zoneNumber => _zone == 'Route 13' ? '2' : _zone.substring(5);

  DateTime get _eraDate => _zone == 'Zone 4'
      ? DutyCorrection.dateForEra(_era)
      : DateTime.now();

  String? get _correctionEra => _zone == 'Zone 4' ? _era : null;

  Future<List<String>> _load() async {
    final codes = await ZoneBoardService.listDutyCodes(
      zoneNumber: _zoneNumber,
      dayKey: ZoneBoardMapper.dayKeyForBrowseType(_dayType),
      date: _eraDate,
    );
    final bills = await BillsCsvService.load(
      zone: _zone,
      dayType: _dayType,
      eraDate: _eraDate,
      applyCorrections: false,
    );
    final byCode = {
      for (final code in codes) DutyCorrection.canonicalDuty(code): code,
    };
    final ordered = <String>[];
    for (final duty in bills.duties) {
      final code = byCode.remove(DutyCorrection.canonicalDuty(duty.shift));
      if (code != null) ordered.add(code);
    }
    final rest = byCode.values.toList()..sort(BillsDutyGrouping.compareShifts);
    ordered.addAll(rest);
    return ordered;
  }

  void _selectDay(String dayType) {
    setState(() {
      _dayType = dayType;
      _duties = _load();
    });
  }

  List<_DutyGroup> _groupsFor(List<String> duties) {
    final groups = <_DutyGroup>[];
    var bucket = <String>[];
    String? key;

    void flush() {
      if (bucket.isEmpty) return;
      final first = bucket.first.split('/').last;
      final last = bucket.last.split('/').last;
      groups.add(_DutyGroup(first == last ? first : '$first–$last', bucket));
      bucket = [];
    }

    for (final duty in duties) {
      final nextKey = BillsDutyGrouping.sectionKey(duty);
      if (key != null && nextKey != key) flush();
      key = nextKey;
      bucket.add(duty);
    }
    flush();
    return groups;
  }

  void _openDuty(String duty) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Route13CorrectionEditor(
          duty: duty,
          dayType: _dayType,
          zone: _zone,
          era: _correctionEra,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final query = _search.text.trim().toLowerCase();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Duty corrections'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _choiceField(
                value: _zone,
                options: _zones,
                onChanged: (zone) {
                  setState(() {
                    _zone = zone;
                    _duties = _load();
                  });
                },
              ),
              if (_zone == 'Zone 4') ...[
                const SizedBox(height: 8),
                _choiceField(
                  value: _era,
                  options: _eras.keys.toList(),
                  labelOf: (era) => _eras[era] ?? era,
                  onChanged: (era) {
                    setState(() {
                      _era = era;
                      _duties = _load();
                    });
                  },
                ),
              ],
              const SizedBox(height: 12),
              SegmentedButton<String>(
                expandedInsets: EdgeInsets.zero,
                showSelectedIcon: false,
                segments: [
                  for (final dayType in _dayTypes)
                    ButtonSegment<String>(
                      value: dayType,
                      label: Text(
                        dayType,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                selected: {_dayType},
                onSelectionChanged: (selected) => _selectDay(selected.first),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _search,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search duty',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear',
                          onPressed: _search.clear,
                          icon: const Icon(Icons.clear),
                        ),
                  filled: true,
                  fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: FutureBuilder<List<String>>(
                  future: _duties,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final duties = (snapshot.data ?? const <String>[])
                        .where(
                          (duty) =>
                              query.isEmpty || duty.toLowerCase().contains(query),
                        )
                        .toList();
                    if (duties.isEmpty) {
                      return const Center(child: Text('No Route 13 duties'));
                    }
                    final groups = _groupsFor(duties);
                    return ListView(
                      padding: const EdgeInsets.only(bottom: 16),
                      children: [
                        for (final group in groups) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
                            child: Text(
                              group.label,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                          Material(
                            color: scheme.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: scheme.outlineVariant),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              children: [
                                for (var i = 0; i < group.duties.length; i++) ...[
                                  if (i > 0)
                                    Divider(
                                      height: 1,
                                      color: scheme.outlineVariant,
                                    ),
                                  ListTile(
                                    title: Text(group.duties[i]),
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () => _openDuty(group.duties[i]),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _choiceField({
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
    String Function(String value)? labelOf,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      items: [
        for (final option in options)
          DropdownMenuItem(
            value: option,
            child: Text(
              labelOf?.call(option) ?? option,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: (selected) {
        if (selected != null) onChanged(selected);
      },
    );
  }
}
