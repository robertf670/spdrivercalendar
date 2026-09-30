import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/core/constants/training_constants.dart';
import 'package:spdrivercalendar/features/calendar/services/work_shift_duty_loader.dart';

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
  test('includes workout duties for regular zone work shifts', () async {
    final loader = WorkShiftDutyLoader(
      bundle: _FakeBundle({
        'assets/M-F_DUTIES_PZ1.csv':
            'shift,a,b,c,d,startbreak\n01,x,x,x,x,10:00\n02,x,x,x,x,workout\n',
      }),
    );

    final shifts = await loader.loadShiftNumbers(
      selectedZone: 'Zone 1',
      shiftDate: DateTime(2026, 8, 4),
      donnybrook1Enabled: false,
    );

    expect(shifts, ['01', '02']);
  });

  test('fixed duty zones return an empty shift list', () async {
    final loader = WorkShiftDutyLoader(bundle: _FakeBundle({}));
    final shifts = await loader.loadShiftNumbers(
      selectedZone: 'Union',
      shiftDate: DateTime(2026, 8, 4),
      donnybrook1Enabled: false,
    );
    expect(shifts, isEmpty);
  });

  test('training excludes EA Type Training and appends custom option', () async {
    final loader = WorkShiftDutyLoader(
      bundle: _FakeBundle({
        'assets/training_duties.csv':
            'shift\nCPC\nEA Type Training\nRoute 13 Training\n',
      }),
    );

    final shifts = await loader.loadShiftNumbers(
      selectedZone: 'Training',
      shiftDate: DateTime(2026, 8, 4), // Tuesday
      donnybrook1Enabled: false,
    );

    expect(shifts, contains('CPC'));
    expect(shifts, contains('Route 13 Training'));
    expect(shifts, isNot(contains('EA Type Training')));
    expect(shifts.last, TrainingConstants.customTrainingShiftOption);
  });

  test('Zone 2 stays empty before 10 Oct even when Sunday CSV has duties',
      () async {
    const csv =
        'shift,duty,report,depart,location,startbreak\nPZ2/01,007201,06:07:00,06:15:00,Garage,WORKOUT\n';
    final loader = WorkShiftDutyLoader(
      bundle: _FakeBundle({
        'assets/SUN_DUTIES_PZ2.csv': csv,
      }),
    );

    final before = await loader.loadShiftNumbers(
      selectedZone: 'Zone 2',
      shiftDate: DateTime(2026, 10, 4), // Sunday
      donnybrook1Enabled: false,
    );
    expect(before, isEmpty);

    final after = await loader.loadShiftNumbers(
      selectedZone: 'Zone 2',
      shiftDate: DateTime(2026, 10, 11), // Sunday
      donnybrook1Enabled: false,
    );
    expect(after, ['PZ2/01']);
  });

  test('Zone 2 Saturday duties load from 10 Oct 2026', () async {
    final loader = WorkShiftDutyLoader(
      bundle: _FakeBundle({
        'assets/SAT_DUTIES_PZ2.csv':
            'shift,duty,report,depart,location,startbreak\nPZ2/01,007201,05:22:00,05:30:00,Garage,WORKOUT\nPZ2/30,007230,18:41:00,19:00:00,MISQ,WORKOUT\n',
      }),
    );

    final shifts = await loader.loadShiftNumbers(
      selectedZone: 'Zone 2',
      shiftDate: DateTime(2026, 10, 10), // Saturday
      donnybrook1Enabled: false,
    );
    expect(shifts, ['PZ2/01', 'PZ2/30']);
  });

  test('Zone 2 Monday-Friday duties load from 10 Oct 2026', () async {
    final loader = WorkShiftDutyLoader(
      bundle: _FakeBundle({
        'assets/M-F_DUTIES_PZ2.csv':
            'shift,duty,report,depart,location,startbreak\nPZ2/01,007201,05:02:00,05:10:00,Garage,08:05\nPZ2/34,007234,19:26:00,19:45:00,MISQ,WORKOUT\n',
      }),
    );

    final shifts = await loader.loadShiftNumbers(
      selectedZone: 'Zone 2',
      shiftDate: DateTime(2026, 10, 12), // Monday
      donnybrook1Enabled: false,
    );
    expect(shifts, ['PZ2/01', 'PZ2/34']);
  });
}
