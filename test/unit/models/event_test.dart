import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/models/event.dart';

void main() {
  Event roundTrip(Event event) => Event.fromMap(event.toMap());

  Event minimalEvent() => Event(
        id: 'event-1',
        title: 'Work',
        startDate: DateTime(2026, 7, 23),
        startTime: const TimeOfDay(hour: 8, minute: 15),
        endDate: DateTime(2026, 7, 23),
        endTime: const TimeOfDay(hour: 16, minute: 45),
      );

  group('Event serialization', () {
    test('round-trips a minimal event', () {
      final restored = roundTrip(minimalEvent());

      expect(restored.id, 'event-1');
      expect(restored.title, 'Work');
      expect(restored.startDate, DateTime(2026, 7, 23));
      expect(restored.startTime, const TimeOfDay(hour: 8, minute: 15));
      expect(restored.endDate, DateTime(2026, 7, 23));
      expect(restored.endTime, const TimeOfDay(hour: 16, minute: 45));
      expect(restored.isHoliday, isFalse);
      expect(restored.isWorkForOthers, isFalse);
      expect(restored.bankHolidayRedundant, isFalse);
    });

    test('round-trips enhanced assigned duties and bus details', () {
      final event = minimalEvent()
        ..enhancedAssignedDuties = [
          AssignedDuty(
            dutyCode: '101',
            assignedBus: '42',
            startTime: '08:15',
            endTime: '12:00',
            location: 'Garage',
            isHalfDuty: true,
            isSecondHalf: false,
            startLocation: 'Depot',
            finishLocation: 'Town',
            startBreakLocation: 'Station',
            finishBreakLocation: 'Depot',
          ),
        ]
        ..additionalBusesByDuty = {
          '101': ['41', '40'],
        };

      final restored = roundTrip(event);
      final duty = restored.enhancedAssignedDuties!.single;

      expect(restored.assignedDuties, ['101']);
      expect(duty.dutyCode, '101');
      expect(duty.assignedBus, '42');
      expect(duty.startTime, '08:15');
      expect(duty.endTime, '12:00');
      expect(duty.location, 'Garage');
      expect(duty.isHalfDuty, isTrue);
      expect(duty.isSecondHalf, isFalse);
      expect(duty.startLocation, 'Depot');
      expect(duty.finishLocation, 'Town');
      expect(duty.startBreakLocation, 'Station');
      expect(duty.finishBreakLocation, 'Depot');
      expect(restored.additionalBusesByDuty, {
        '101': ['41', '40'],
      });
    });

    test('preserves nullable fields when they are absent', () {
      final restored = roundTrip(minimalEvent());

      expect(restored.workTime, isNull);
      expect(restored.breakStartTime, isNull);
      expect(restored.breakEndTime, isNull);
      expect(restored.routes, isNull);
      expect(restored.notes, isNull);
      expect(restored.noteImagePaths, isNull);
      expect(restored.enhancedAssignedDuties, isNull);
    });

    test('round-trips holiday, notes, images, and status fields', () {
      final event = Event(
        id: 'holiday-1',
        title: 'Winter Holiday',
        startDate: DateTime(2026, 12, 21),
        startTime: const TimeOfDay(hour: 0, minute: 0),
        endDate: DateTime(2026, 12, 21),
        endTime: const TimeOfDay(hour: 23, minute: 59),
        isHoliday: true,
        holidayType: 'winter',
        notes: 'Approved',
        trainingDescription: '  Route familiarisation  ',
        noteImagePaths: ['0.jpg', '1.jpg'],
        hasLateBreak: true,
        tookFullBreak: true,
        overtimeDuration: 30,
        hasLateFinish: true,
        lateFinishDuration: 15,
        sickDayType: 'self-certified',
        isWorkForOthers: true,
        bankHolidayRedundant: true,
      );

      final restored = roundTrip(event);

      expect(restored.isHoliday, isTrue);
      expect(restored.holidayType, 'winter');
      expect(restored.notes, 'Approved');
      expect(restored.trainingDescription, 'Route familiarisation');
      expect(restored.noteImagePaths, ['0.jpg', '1.jpg']);
      expect(restored.hasLateBreak, isTrue);
      expect(restored.tookFullBreak, isTrue);
      expect(restored.overtimeDuration, 30);
      expect(restored.hasLateFinish, isTrue);
      expect(restored.lateFinishDuration, 15);
      expect(restored.sickDayType, 'self-certified');
      expect(restored.isWorkForOthers, isTrue);
      expect(restored.bankHolidayRedundant, isTrue);
    });

    test('migrates legacy assigned duty strings when loading', () {
      final map = minimalEvent().toMap()
        ..['assignedDuties'] = ['101', '202']
        ..['enhancedAssignedDuties'] = null
        ..['firstHalfBus'] = '10'
        ..['secondHalfBus'] = '20'
        ..['title'] = 'SP';

      final restored = Event.fromMap(map);

      expect(
        restored.enhancedAssignedDuties!.map((duty) => duty.dutyCode),
        ['101', '202'],
      );
      expect(restored.enhancedAssignedDuties![0].assignedBus, '10');
      expect(restored.enhancedAssignedDuties![1].assignedBus, '20');
    });
  });
}
