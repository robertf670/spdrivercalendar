import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/services/overtime_duty_shift_loader.dart';

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
  test('excludes workout and nan break duties from zone lists', () async {
    final loader = OvertimeDutyShiftLoader(
      bundle: _FakeBundle({
        'assets/M-F_DUTIES_PZ1.csv':
            'shift,a,b,c,d,startbreak\n01,x,x,x,x,10:00\n02,x,x,x,x,workout\n03,x,x,x,x,nan\n04,x,x,x,x,11:00\n',
      }),
    );

    final shifts = await loader.loadShiftNumbers(
      selectedZone: 'Zone 1',
      shiftDate: DateTime(2026, 8, 4), // Tuesday
    );

    expect(shifts, ['01', '04']);
  });

  test('loads unique Uni/Euro duties on Sunday from seven-day file only', () async {
    final loader = OvertimeDutyShiftLoader(
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

  test('generates spare time options through 16:00', () async {
    final loader = OvertimeDutyShiftLoader(bundle: _FakeBundle({}));
    final shifts = await loader.loadShiftNumbers(
      selectedZone: 'Spare',
      shiftDate: DateTime(2026, 8, 4),
    );

    expect(shifts.first, '04:00');
    expect(shifts.last, '16:00');
    expect(shifts, isNot(contains('16:15')));
  });
}
