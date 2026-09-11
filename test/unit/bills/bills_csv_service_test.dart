import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/bills/models/bill_duty.dart';
import 'package:spdrivercalendar/features/bills/services/bills_csv_service.dart';

void main() {
  const header =
      'shift,duty,report,depart,location,startbreak,startbreaklocation,breakreport,finishbreak,finishbreaklocation,finish,finishlocation,signoff,spread,work,relief';

  group('BillDuty display helpers', () {
    test('strips seconds from times and formats durations', () {
      expect(BillDuty.displayTime('13:17:00'), '13:17');
      expect(BillDuty.displayTime('nan'), '');
      expect(BillDuty.displayTime('WORKOUT'), 'W/O');
      expect(BillDuty.displayDuration('08:18:00'), '8h 18m');
      expect(BillDuty.displayDuration('00:55:00'), '55m');
      expect(BillDuty.displayDuration('05:00:00'), '5h');
      expect(BillDuty.displayDuration('00:00:00'), '');
    });

    test('treats WORKOUT and nan startbreak as workout', () {
      final workout = BillsCsvService.parseCsv(
        '$header\nPZ4/01,007401,04:12:00,04:20:00,Garage,WORKOUT,nan,nan,nan,nan,09:50:00,Garage,09:50:00,05:38:00,05:38:00,00:00:00',
      ).single;
      expect(workout.isWorkout, isTrue);
      expect(workout.hasMealBreak, isFalse);

      final zone1Workout = BillsCsvService.parseCsv(
        '$header\nPZ1/01,007001,04:08:00,04:16:00,GARAGE,nan,nan,nan,nan,nan,09:39:00,GARAGE,09:39:00,05:31:00,05:31:00,00:00:00',
      ).single;
      expect(zone1Workout.isWorkout, isTrue);
      expect(zone1Workout.hasMealBreak, isFalse);
      expect(zone1Workout.takeUpLocation, 'Garage');
    });

    test('maps break locations and matches search queries', () {
      final duty = BillsCsvService.parseCsv(
        '$header\nPZ1/03,007003,04:22:00,04:30:00,GARAGE,09:10:00,39A-ASTONQ,10:10:00,10:10:00,39A-BWALK,11:40:00,39A-ASTONQ,12:00:00,07:38:00,06:38:00,01:00:00',
      ).single;

      expect(duty.hasMealBreak, isTrue);
      expect(duty.hasDistinctSignOff, isTrue);
      expect(duty.breakStartLocation, 'Aston Q');
      expect(duty.breakEndLocation, 'B Walk');
      expect(duty.displaySignOff, '12:00');
      expect(duty.matchesQuery('03'), isTrue);
      expect(duty.matchesQuery('b walk'), isTrue);
      expect(duty.matchesQuery('09:10'), isTrue);
      expect(duty.matchesQuery('zzz'), isFalse);
    });
  });

  group('BillsCsvService', () {
    test('skips empty and nan shift rows', () {
      final duties = BillsCsvService.parseCsv(
        '$header\n\nnan,007000,04:00:00,04:08:00,GARAGE,nan,nan,nan,nan,nan,09:00:00,GARAGE,09:00:00,05:00:00,05:00:00,00:00:00\nPZ1/02,007002,04:22:00,04:30:00,GARAGE,nan,nan,nan,nan,nan,09:30:00,39A-BWALK,09:50:00,05:28:00,05:28:00,00:00:00\n',
      );
      expect(duties, hasLength(1));
      expect(duties.single.shift, 'PZ1/02');
    });

    test('keeps Uni routes and merges extra M-F shifts', () {
      const sevenDay =
          'shift,duty,report,depart,location,startbreak,startbreaklocation,breakreport,finishbreak,finishbreaklocation,finish,finishlocation,signoff,spread,work,relief,routes\n807/06,007506,08:27:00,08:35:00,Garage,WORKOUT,nan,nan,nan,nan,13:45:00,PK Gate St,14:15:00,05:48:00,05:48:00,00:00:00,99\n';
      const mf =
          'shift,duty,report,depart,location,startbreak,startbreaklocation,breakreport,finishbreak,finishbreaklocation,finish,finishlocation,signoff,spread,work,relief,routes\n307/01,007509,06:37:00,06:45:00,Garage,10:35:00,Garage,14:32:00,14:35:00,Garage,18:12:00,Garage,18:12:00,11:35:00,07:38:00,03:57:00,X26/C1\n807/06,007506,08:27:00,08:35:00,Garage,WORKOUT,nan,nan,nan,nan,13:45:00,PK Gate St,14:15:00,05:48:00,05:48:00,00:00:00,99\n';

      final merged = BillsCsvService.mergeUniEuroCsvLines(sevenDay, mf);
      final duties = BillsCsvService.parseLines(merged);
      expect(duties.map((duty) => duty.shift), ['807/06', '307/01']);
      expect(duties.last.routesLabel, 'X26/C1');
    });
  });
}
