import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/timing_points/utils/timing_points_parser.dart';

void main() {
  final routes = TimingPointsParser.parse(
    File('assets/timingpoints.txt').readAsStringSync(),
  );

  test('keeps existing route destinations', () {
    expect(routes.map((route) => route.routeNumber), containsAll(['39', '13']));
    final thirtyNine = routes.firstWhere((route) => route.routeNumber == '39');
    expect(
      TimingPointsParser.destinationsOf(thirtyNine),
      ['Ongar', 'Burlington Road'],
    );
  });

  test('Route 13 has Harristown points to Mountjoy and Grange Castle', () {
    final route13 = routes.firstWhere((route) => route.routeNumber == '13');
    expect(
      TimingPointsParser.destinationsOf(route13),
      ['Mountjoy Square', 'Grange Castle'],
    );
    expect(
      TimingPointsParser.pointsForDestination(route13, 'Mountjoy Square'),
      [
        'Convent Road / Boot Road',
        'Convent Road / St. Anthony\'s Avenue',
        'Fonthill Rd / St. John\'s',
        'Naas Road / Red Cow Hotel',
        'Naas Road / Robin Hood Ind Est',
        'Naas Road / John F. Kennedy Drive',
        'Naas Road / Luas Kylemore',
        'Naas Road / Kylemore Road',
        'Naas Road / Carriglea I.E.',
        'Naas Road / Luas Bluebell',
        'Emmet Road / South Circular Road',
        'James Street / Echlin Street',
        'Parnell Square / Rotunda Hospital',
      ],
    );
    expect(
      TimingPointsParser.pointsForDestination(route13, 'Grange Castle'),
      [
        'Emmet Road / Bulfin Road',
        'Emmet Road / Camac Close',
        'Naas Road / Luas Kylemore',
        'Naas Road / Robin Hood Road',
        'Naas Road / Long Mile Road (John F. Kennedy Dr)',
        'Naas Road / Club Road',
        'Naas Road / Red Cow Hotel',
        'Naas Road / Luas Red Cow',
        'Fonthill Rd / Boot Road',
        'Fonthill Rd / St. John\'s',
      ],
    );
    expect(
      route13.note,
      'These are the timing points from Harristown previously. Donnybrook/Phibsboro did not officially set timing points.',
    );
  });

  test('NOTE lines do not create a route by themselves', () {
    final parsed = TimingPointsParser.parse(
      'NOTE 99: Unused note\n'
      '39 -> Ongar, Manor Street\n',
    );
    expect(parsed.map((route) => route.routeNumber), ['39']);
    expect(parsed.single.note, isNull);
  });
}
