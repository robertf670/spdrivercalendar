import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/services/work_for_others_shift_loader.dart';

class _FakeBundle extends CachingAssetBundle {
  _FakeBundle(this.assets);

  final Map<String, String> assets;

  @override
  Future<ByteData> load(String key) async {
    throw UnimplementedError('load not used');
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final value = assets[key];
    if (value == null) {
      throw Exception('Missing asset $key');
    }
    return value;
  }
}

void main() {
  test('loads unique Uni/Euro duties from the seven-day file on Sunday', () async {
    final loader = WorkForOthersShiftLoader(
      bundle: _FakeBundle({
        'assets/UNI_7DAYs.csv': 'duty\n807/01\n807/02\n807/01\n',
        'assets/UNI_M-F.csv': 'duty\n999/99\n',
      }),
    );

    final shifts = await loader.loadShiftNumbers(
      selectedZone: 'Uni/Euro',
      shiftDate: DateTime(2026, 8, 2), // Sunday
    );

    expect(shifts, ['807/01', '807/02']);
  });

  test('merges weekday Uni files and preserves first-seen order', () async {
    final loader = WorkForOthersShiftLoader(
      bundle: _FakeBundle({
        'assets/UNI_7DAYs.csv': 'duty\n807/01\n',
        'assets/UNI_M-F.csv': 'duty\n807/01\n811/02\n',
      }),
    );

    final shifts = await loader.loadShiftNumbers(
      selectedZone: 'Uni/Euro',
      shiftDate: DateTime(2026, 8, 4), // Tuesday
    );

    expect(shifts, ['807/01', '811/02']);
  });

  test('loads zone duties from the roster filename for the day', () async {
    final loader = WorkForOthersShiftLoader(
      bundle: _FakeBundle({
        'assets/M-F_DUTIES_PZ1.csv': 'shift\n01\n02\nshift\n02\n',
      }),
    );

    final shifts = await loader.loadShiftNumbers(
      selectedZone: 'Zone 1',
      shiftDate: DateTime(2026, 8, 4), // Tuesday
    );

    expect(shifts, ['01', '02']);
  });
}
