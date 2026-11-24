import 'package:flutter/material.dart';
import 'package:spdrivercalendar/features/bills/models/bill_duty.dart';
import 'package:spdrivercalendar/features/bills/services/bills_csv_service.dart';
import 'package:spdrivercalendar/features/calendar/services/zone2_duties.dart';
import 'package:spdrivercalendar/features/calendar/utils/zone_board_mapper.dart';
import 'package:spdrivercalendar/features/duty_corrections/duty_correction.dart';
import 'package:spdrivercalendar/features/duty_corrections/duty_correction_service.dart';
import 'package:spdrivercalendar/services/zone_board_service.dart';

class Route13CorrectionEditor extends StatefulWidget {
  const Route13CorrectionEditor({
    super.key,
    required this.duty,
    required this.dayType,
    required this.zone,
    this.era,
  });

  final String duty;
  final String dayType;
  final String zone;
  final String? era;

  @override
  State<Route13CorrectionEditor> createState() =>
      _Route13CorrectionEditorState();
}

class _StopEditors {
  _StopEditors({
    required this.index,
    required this.route,
    required this.place,
    required this.arrive,
    required this.depart,
    required this.baselineRoute,
    required this.baselinePlace,
    required this.baselineArrive,
    required this.baselineDepart,
  });

  final int index;
  final TextEditingController route;
  final TextEditingController place;
  final TextEditingController arrive;
  final TextEditingController depart;
  final String baselineRoute;
  final String baselinePlace;
  final String baselineArrive;
  final String baselineDepart;

  void dispose() {
    route.dispose();
    place.dispose();
    arrive.dispose();
    depart.dispose();
  }
}

class _Route13CorrectionEditorState extends State<Route13CorrectionEditor> {
  late final Future<_EditorData> _load;
  final _fields = <String, TextEditingController>{};
  final _baselines = <String, String>{};
  final _stops = <_StopEditors>[];
  var _built = false;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _load = _read();
  }

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    for (final stop in _stops) {
      stop.dispose();
    }
    super.dispose();
  }

  Future<_EditorData> _read() async {
    final dayKey = ZoneBoardMapper.dayKeyForBrowseType(widget.dayType);
    final eraDate = widget.era == null
        ? DateTime.now()
        : DutyCorrection.dateForEra(widget.era);
    final day = await ZoneBoardService.rawDay(
      dutyTitle: widget.duty,
      dayKey: dayKey,
      date: eraDate,
    );
    final bills = await BillsCsvService.load(
      zone: widget.zone,
      dayType: widget.dayType,
      eraDate: eraDate,
      applyCorrections: false,
    );
    BillDuty? bill;
    for (final duty in bills.duties) {
      if (duty.shift == widget.duty ||
          Zone2Duties.codesMatch(duty.shift, widget.duty)) {
        bill = duty;
        break;
      }
    }
    final correction = await DutyCorrectionService.forDuty(
      widget.duty,
      dayKey,
      era: widget.era,
    );
    return _EditorData(day: day, bill: bill, correction: correction, dayKey: dayKey);
  }

  void _ensureForm(_EditorData data) {
    if (_built) return;
    _built = true;
    final bill = data.bill;
    final correction = data.correction;
    final header = data.day ?? const <String, dynamic>{};

    void addClock({
      required String key,
      required String bundled,
      String? corrected,
    }) {
      final baseline = BillDuty.displayTime(bundled);
      final shown = corrected == null ? baseline : BillDuty.displayTime(corrected);
      _baselines[key] = baseline;
      _fields[key] = TextEditingController(text: shown);
    }

    void addText({
      required String key,
      required String bundled,
      String? corrected,
    }) {
      final baseline = BillDuty.mappedLocation(bundled);
      final shown = corrected == null
          ? baseline
          : BillDuty.mappedLocation(corrected);
      _baselines[key] = baseline;
      _fields[key] = TextEditingController(text: shown.isEmpty ? (corrected ?? bundled) : shown);
    }

    addClock(
      key: 'report',
      bundled: bill?.report ?? header['report']?.toString() ?? '',
      corrected: correction?.bill.report ?? correction?.report,
    );
    addClock(
      key: 'depart',
      bundled: bill?.depart ?? header['depart']?.toString() ?? '',
      corrected: correction?.bill.depart ?? correction?.depart,
    );
    addText(
      key: 'location',
      bundled: bill?.location ?? '',
      corrected: correction?.bill.location,
    );
    addClock(
      key: 'startBreak',
      bundled: bill?.startBreak ?? '',
      corrected: correction?.bill.startBreak,
    );
    addText(
      key: 'startBreakLocation',
      bundled: bill?.startBreakLocation ?? '',
      corrected: correction?.bill.startBreakLocation,
    );
    addClock(
      key: 'breakReport',
      bundled: bill?.breakReport ?? '',
      corrected: correction?.bill.breakReport,
    );
    addClock(
      key: 'finishBreak',
      bundled: bill?.finishBreak ?? '',
      corrected: correction?.bill.finishBreak,
    );
    addText(
      key: 'finishBreakLocation',
      bundled: bill?.finishBreakLocation ?? '',
      corrected: correction?.bill.finishBreakLocation,
    );
    addClock(
      key: 'finish',
      bundled: bill?.finish ?? '',
      corrected: correction?.bill.finish,
    );
    addText(
      key: 'finishLocation',
      bundled: bill?.finishLocation ?? '',
      corrected: correction?.bill.finishLocation,
    );
    addClock(
      key: 'signOff',
      bundled: bill?.signOff ?? header['signoff']?.toString() ?? '',
      corrected: correction?.bill.signOff ?? correction?.signoff,
    );

    final board = header['board'];
    final rows = board is List ? board : const [];
    final patches = {
      for (final patch in correction?.boardRows ?? const <BoardRowPatch>[])
        patch.index: patch,
    };
    for (var index = 0; index < rows.length; index++) {
      final raw = rows[index];
      if (raw is! List || raw.isEmpty) continue;
      final cells = raw.map((cell) => cell?.toString() ?? '').toList();
      if (cells.isNotEmpty && cells.first == '---') continue;
      while (cells.length < 6) {
        cells.add('');
      }
      final patch = patches[index];
      _stops.add(
        _StopEditors(
          index: index,
          baselineRoute: cells[0],
          baselinePlace: cells[3],
          baselineArrive: cells[4],
          baselineDepart: cells[5],
          route: TextEditingController(text: patch?.route ?? cells[0]),
          place: TextEditingController(text: patch?.place ?? cells[3]),
          arrive: TextEditingController(text: patch?.arrive ?? cells[4]),
          depart: TextEditingController(text: patch?.depart ?? cells[5]),
        ),
      );
    }
  }

  Future<void> _save(_EditorData data) async {
    String? clock(String key) {
      final value = _fields[key]!.text;
      final normalized = _normalizeClock(value);
      if (normalized == null) {
        _snack('Use a time like 21:36 for ${_label(key)}');
        return null;
      }
      return normalized;
    }

    final clocks = <String, String>{};
    for (final key in const [
      'report',
      'depart',
      'startBreak',
      'breakReport',
      'finishBreak',
      'finish',
      'signOff',
    ]) {
      final normalized = clock(key);
      if (normalized == null) return;
      clocks[key] = normalized;
    }

    for (final stop in _stops) {
      for (final pair in [
        ('Arrive', stop.arrive),
        ('Depart', stop.depart),
      ]) {
        if (_normalizeClock(pair.$2.text) == null) {
          _snack('Use a time like 21:36 for ${pair.$1}');
          return;
        }
      }
    }

    String? changedClock(String key) {
      final shown = clocks[key]!;
      if (shown == _baselines[key]) return null;
      return _csvClock(shown);
    }

    String? changedText(String key) {
      final shown = _fields[key]!.text.trim();
      if (shown == _baselines[key]) return null;
      return shown;
    }

    final bill = BillFieldPatch(
      report: changedClock('report'),
      depart: changedClock('depart'),
      location: changedText('location'),
      startBreak: changedClock('startBreak'),
      startBreakLocation: changedText('startBreakLocation'),
      breakReport: changedClock('breakReport'),
      finishBreak: changedClock('finishBreak'),
      finishBreakLocation: changedText('finishBreakLocation'),
      finish: changedClock('finish'),
      finishLocation: changedText('finishLocation'),
      signOff: changedClock('signOff'),
    );

    final rows = <BoardRowPatch>[];
    for (final stop in _stops) {
      final route = stop.route.text.trim();
      final place = stop.place.text.trim();
      final arrive = _normalizeClock(stop.arrive.text)!;
      final depart = _normalizeClock(stop.depart.text)!;
      if (route == stop.baselineRoute &&
          place == stop.baselinePlace &&
          arrive == stop.baselineArrive &&
          depart == stop.baselineDepart) {
        continue;
      }
      rows.add(
        BoardRowPatch(
          index: stop.index,
          route: route,
          place: place,
          arrive: arrive,
          depart: depart,
        ),
      );
    }

    final correction = DutyCorrection(
      duty: widget.duty,
      dayKey: data.dayKey,
      era: widget.era,
      report: clocks['report'] == _baselines['report'] ? null : clocks['report'],
      depart: clocks['depart'] == _baselines['depart'] ? null : clocks['depart'],
      signoff: clocks['signOff'] == _baselines['signOff'] ? null : clocks['signOff'],
      boardRows: rows,
      bill: bill,
    );

    setState(() => _saving = true);
    try {
      await DutyCorrectionService.save(correction);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      _snack('Could not save: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.duty} ${widget.dayType}'),
        actions: [
          FutureBuilder<_EditorData>(
            future: _load,
            builder: (context, snapshot) {
              final data = snapshot.data;
              if (data == null) return const SizedBox.shrink();
              return IconButton(
                tooltip: 'Save',
                onPressed: _saving ? null : () => _save(data),
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<_EditorData>(
        future: _load,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data;
          if (data == null || data.day == null) {
            return const Center(child: Text('This duty has no board for that day'));
          }
          _ensureForm(data);
          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _sectionTitle('Bill'),
                _panel(
                  children: [
                    _pair('Report', 'report', 'Take up', 'depart'),
                    _field('Take up place', 'location'),
                    _pair('Break start', 'startBreak', 'Break depart', 'finishBreak'),
                    _field('Break place', 'startBreakLocation'),
                    _field('Break report', 'breakReport'),
                    _field('Break end place', 'finishBreakLocation'),
                    _pair('Finish', 'finish', 'Sign off', 'signOff'),
                    _field('Finish place', 'finishLocation'),
                  ],
                ),
                const SizedBox(height: 20),
                _sectionTitle('Board'),
                for (final stop in _stops) ...[
                  const SizedBox(height: 8),
                  _stopCard(stop),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }

  Widget _panel({required List<Widget> children}) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              children[i],
            ],
          ],
        ),
      ),
    );
  }

  Widget _pair(String leftLabel, String leftKey, String rightLabel, String rightKey) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _valueField(leftLabel, _fields[leftKey]!)),
        const SizedBox(width: 8),
        Expanded(child: _valueField(rightLabel, _fields[rightKey]!)),
      ],
    );
  }

  Widget _field(String label, String key) {
    return _valueField(label, _fields[key]!);
  }

  Widget _valueField(String label, TextEditingController controller) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(12);
    final enabled = OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: scheme.outline),
    );
    final focused = OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: scheme.primary, width: 2),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            fillColor: scheme.surface,
            border: enabled,
            enabledBorder: enabled,
            focusedBorder: focused,
          ),
        ),
      ],
    );
  }

  bool _isNote(_StopEditors stop) {
    return stop.baselineRoute.isEmpty &&
        stop.baselineArrive.isEmpty &&
        stop.baselineDepart.isEmpty;
  }

  Widget _stopCard(_StopEditors stop) {
    final scheme = Theme.of(context).colorScheme;
    final note = _isNote(stop);
    final title = stop.baselinePlace.isEmpty
        ? 'Stop ${stop.index + 1}'
        : stop.baselinePlace;
    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: note
            ? _valueField('Note', stop.place)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 88,
                        child: _valueField('Route', stop.route),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: _valueField('Place', stop.place)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _valueField('Arrive', stop.arrive)),
                      const SizedBox(width: 8),
                      Expanded(child: _valueField('Depart', stop.depart)),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  String _label(String key) {
    switch (key) {
      case 'report':
        return 'Report';
      case 'depart':
        return 'Take up';
      case 'startBreak':
        return 'Break start';
      case 'breakReport':
        return 'Break report';
      case 'finishBreak':
        return 'Break depart';
      case 'finish':
        return 'Finish';
      case 'signOff':
        return 'Sign off';
      default:
        return key;
    }
  }
}

class _EditorData {
  const _EditorData({
    required this.day,
    required this.bill,
    required this.correction,
    required this.dayKey,
  });

  final Map<String, dynamic>? day;
  final BillDuty? bill;
  final DutyCorrection? correction;
  final String dayKey;
}

String? _normalizeClock(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return '';
  if (value.toUpperCase() == 'W/O' || value.toLowerCase() == 'workout') {
    return 'W/O';
  }
  final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value);
  if (match == null) return null;
  final hour = int.parse(match.group(1)!);
  final minute = int.parse(match.group(2)!);
  if (hour > 23 || minute > 59) return null;
  return '${hour.toString().padLeft(2, '0')}:${match.group(2)}';
}

String _csvClock(String normalized) {
  if (normalized.isEmpty) return '';
  if (normalized == 'W/O') return 'WORKOUT';
  return '$normalized:00';
}
