import 'package:spdrivercalendar/models/universal_board.dart';

/// Dated Euro duty changes that are not in the current bill files yet.
class EuroDutyRevisions {
  EuroDutyRevisions._();

  /// 307/03 and 307/04 change from this date.
  static final DateTime changesFrom = DateTime(2026, 11, 8);

  static const revised30703CsvLine =
      '307/03,007567,06:42:00,06:50:00,Garage,10:50:00,Garage,16:12:00,16:15:00,Garage,19:42:00,Garage,19:42:00,13:00:00,07:38:00,05:22:00,X32';

  static const revised30704CsvLine =
      '307/04,007573,05:52:00,06:00:00,Garage,10:10:00,Garage,15:19:00,15:22:00,Garage,18:35:00,Garage,18:35:00,12:43:00,07:34:00,05:09:00,X26/C1';

  static const _lines = <String, String>{
    '307/03': revised30703CsvLine,
    '307/04': revised30704CsvLine,
  };

  static bool isRevised(String shift, DateTime date) {
    return _lineFor(shift, date) != null;
  }

  static Duration? workFor(String shift, DateTime date) {
    return _columnDuration(_lineFor(shift, date), 14);
  }

  static Duration? spreadFor(String shift, DateTime date) {
    return _columnDuration(_lineFor(shift, date), 13);
  }

  /// Route column split on `/`. A single route is used for both halves.
  static List<String>? routesFor(String shift, DateTime date) {
    final line = _lineFor(shift, date);
    if (line == null) return null;
    final routes = line.split(',').last.trim();
    if (routes.isEmpty) return null;
    final parts = routes.split('/').map((part) => part.trim()).toList();
    if (parts.length == 1) return [parts.first, parts.first];
    return parts;
  }

  /// Replaces revised rows when [date] is on or after 8 Nov 2026.
  static String applyUniMfCsv(String csv, DateTime date) {
    if (!_onOrAfter(date)) return csv;
    final lines = csv.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final replacement = _lines[_shiftCode(line.split(',').first)];
      if (replacement == null) continue;
      final cr = line.endsWith('\r') ? '\r' : '';
      lines[i] = '$replacement$cr';
    }
    return lines.join('\n');
  }

  /// The 8 Nov 2026 board, or null while the current board still applies.
  static UniversalBoard? boardFor(String shift, DateTime date) {
    if (!isRevised(shift, date)) return null;
    return _boards[_shiftCode(shift)];
  }

  static String? _lineFor(String shift, DateTime date) {
    if (!_onOrAfter(date)) return null;
    return _lines[_shiftCode(shift)];
  }

  static Duration? _columnDuration(String? line, int index) {
    if (line == null) return null;
    final parts = line.split(',');
    if (index >= parts.length) return null;
    final time = parts[index].split(':');
    if (time.length < 2) return null;
    final hours = int.tryParse(time[0]);
    final minutes = int.tryParse(time[1]);
    if (hours == null || minutes == null) return null;
    return Duration(hours: hours, minutes: minutes);
  }

  static bool _onOrAfter(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return !day.isBefore(changesFrom);
  }

  static String _shiftCode(String shift) {
    var code = shift.trim();
    if (code.toUpperCase().startsWith('UNI:')) {
      code = code.substring(4).trim();
    }
    return code;
  }

  static final Map<String, UniversalBoard> _boards = {
    '307/03': _board30703,
    '307/04': _board30704,
  };

  static final UniversalBoard _board30703 = UniversalBoard(
    shift: '307/03',
    duty: '007567',
    sections: [
      BoardSection(
        type: 'firstHalf',
        entries: [
          BoardEntry(action: 'Report', time: '06:42'),
          BoardEntry(
            action: 'Depart Garage',
            time: '06:50',
            location: 'Garage',
          ),
          BoardEntry(
            action: 'Route',
            time: '07:35',
            location: 'Hewlett Packard',
            route: 'X32',
            notes: 'Via Lucan Village',
          ),
          BoardEntry(action: 'Arrive', time: '09:50', location: 'Belfield'),
          BoardEntry(
            action: 'Break',
            time: '10:50',
            location: 'Phibsboro Garage',
          ),
        ],
      ),
      BoardSection(
        type: 'secondHalf',
        entries: [
          BoardEntry(action: 'Report', time: '16:12'),
          BoardEntry(
            action: 'Depart Garage',
            time: '16:15',
            location: 'Phibsboro Garage',
          ),
          BoardEntry(
            action: 'Route',
            time: '17:15',
            location: 'UCD Belfield',
            route: 'X32',
            notes: 'Via Lucan Village',
          ),
          BoardEntry(
            action: 'Arrive',
            time: '19:00',
            location: 'Castletown',
          ),
          BoardEntry(
            action: 'Finish',
            time: '19:42',
            location: 'Phibsboro Garage',
          ),
        ],
      ),
    ],
  );

  static final UniversalBoard _board30704 = UniversalBoard(
    shift: '307/04',
    duty: '007573',
    sections: [
      BoardSection(
        type: 'firstHalf',
        entries: [
          BoardEntry(action: 'Report', time: '05:52'),
          BoardEntry(
            action: 'Depart Garage',
            time: '06:00',
            location: 'Garage',
          ),
          BoardEntry(
            action: 'Route',
            time: '07:00',
            location: 'Maynooth',
            route: 'X26',
            notes: 'Via Louisa Bridge',
          ),
          BoardEntry(
            action: 'Arrive',
            time: '09:20',
            location: 'UCD Belfield',
          ),
          BoardEntry(
            action: 'Break',
            time: '10:10',
            location: 'Phibsboro Garage',
          ),
        ],
      ),
      BoardSection(
        type: 'secondHalf',
        entries: [
          BoardEntry(action: 'Report', time: '15:19'),
          BoardEntry(
            action: 'Depart Garage',
            time: '15:22',
            location: 'Garage',
          ),
          BoardEntry(
            action: 'Route',
            time: '16:07',
            location: 'Sandymount',
            route: 'C1',
          ),
          BoardEntry(
            action: 'Arrive',
            time: '17:45',
            location: 'Adamstown Stn',
          ),
          BoardEntry(
            action: 'Finish',
            time: '18:35',
            location: 'Phibsboro Garage',
          ),
        ],
      ),
    ],
  );
}
