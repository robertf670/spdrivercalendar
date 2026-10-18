import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/services/zone2_duties.dart';

void main() {
  test('Route 13 shifts cannot be added before 10 Oct 2026', () {
    expect(Zone2Duties.canAddShiftsOn(DateTime(2026, 10, 9)), isFalse);
    expect(Zone2Duties.canAddShiftsOn(DateTime(2026, 10, 9, 23, 59)), isFalse);
  });

  test('Route 13 shifts can be added from 10 Oct 2026', () {
    expect(Zone2Duties.canAddShiftsOn(DateTime(2026, 10, 10)), isTrue);
    expect(Zone2Duties.canAddShiftsOn(DateTime(2026, 10, 18)), isTrue);
  });

  test('Zone 2 and Route 13 are the same zone', () {
    expect(Zone2Duties.zoneLabel, 'Route 13');
    expect(Zone2Duties.isZone('Route 13'), isTrue);
    expect(Zone2Duties.isZone('Zone 2'), isTrue);
    expect(Zone2Duties.normalizeZoneLabel('Zone 2'), 'Route 13');
    expect(Zone2Duties.fileZoneNumber('Route 13'), '2');
    expect(Zone2Duties.fileZoneNumber('Zone 2'), '2');
    expect(Zone2Duties.fileZoneNumber('Zone 1'), '1');
    expect(Zone2Duties.fileZoneNumber('2'), '2');
  });

  test('canonicalises PZ2 and 2/ shorthand to 13/', () {
    expect(Zone2Duties.canonical('PZ2/01'), '13/01');
    expect(Zone2Duties.canonical('PZ2/1X'), '13/1X');
    expect(Zone2Duties.canonical('PZ2/01A (OT)'), '13/01A');
    expect(Zone2Duties.canonical('2/01'), '13/01');
    expect(Zone2Duties.canonical('13/33'), '13/33');
  });

  test('aliases cover old PZ2 titles', () {
    expect(Zone2Duties.aliases('13/01'), ['13/01', 'PZ2/01']);
    expect(Zone2Duties.aliases('PZ2/33'), ['13/33', 'PZ2/33']);
    expect(Zone2Duties.codesMatch('PZ2/04', '13/04'), isTrue);
    expect(Zone2Duties.codesMatch('13/04', 'PZ2/04'), isTrue);
    expect(Zone2Duties.codesMatch('PZ1/01', '13/01'), isFalse);
  });

  test('13/01 is Route 13, not Uni/Euro', () {
    expect(Zone2Duties.isRoute13Code('13/01'), isTrue);
    expect(Zone2Duties.isRoute13Code('PZ2/01'), isTrue);
    expect(Zone2Duties.isUniEuroCode('13/01'), isFalse);
    expect(Zone2Duties.isUniEuroCode('307/01'), isTrue);
    expect(Zone2Duties.isUniEuroCode('807/90'), isTrue);
    expect(Zone2Duties.isUniEuroCode('22B/01'), isFalse);
  });

  test('rewrites stored PZ2 text to 13/ and keeps halves and OT', () {
    expect(Zone2Duties.rewriteStoredText('PZ2/01'), '13/01');
    expect(Zone2Duties.rewriteStoredText('PZ2/01A (OT)'), '13/01A (OT)');
    expect(Zone2Duties.rewriteStoredText('pz2/1X'), '13/1X');
    expect(Zone2Duties.rewriteStoredText('PZ1/01 and PZ2/04'), 'PZ1/01 and 13/04');
    expect(Zone2Duties.rewriteStoredText('13/01'), '13/01');
  });

  test('csv zone number maps Route 13 codes onto PZ2 files', () {
    expect(Zone2Duties.csvZoneNumberForDuty('13/01'), '2');
    expect(Zone2Duties.csvZoneNumberForDuty('PZ2/01'), '2');
    expect(Zone2Duties.csvZoneNumberForDuty('PZ1/01'), '1');
    expect(Zone2Duties.csvZoneNumberForDuty('PZ4/16'), '4');
  });
}
