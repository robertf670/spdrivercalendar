import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spdrivercalendar/core/constants/app_constants.dart';
import 'package:spdrivercalendar/features/ratings/duty_rate_menu_actions.dart';
import 'package:spdrivercalendar/models/event.dart';

Event _duty({required DateTime day}) {
  return Event(
    id: 'e1',
    title: 'PZ1/39',
    startDate: day,
    startTime: const TimeOfDay(hour: 8, minute: 0),
    endDate: day,
    endTime: const TimeOfDay(hour: 16, minute: 0),
  );
}

Future<void> _pumpMenu(WidgetTester tester, Event event) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: DutyRateMenuActions(event: event),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('shows Rate duty after sign-off', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final day = DateTime.now().subtract(const Duration(days: 1));
    await _pumpMenu(tester, _duty(day: day));
    expect(find.text('Rate duty'), findsOneWidget);
  });

  testWidgets('hides Rate duty when settings are off', (tester) async {
    SharedPreferences.setMockInitialValues({
      AppConstants.dutyRatingsEnabledKey: false,
    });
    final day = DateTime.now().subtract(const Duration(days: 1));
    await _pumpMenu(tester, _duty(day: day));
    expect(find.text('Rate duty'), findsNothing);
  });

  testWidgets('hides Rate duty before sign-off', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final day = DateTime.now().add(const Duration(days: 2));
    await _pumpMenu(tester, _duty(day: day));
    expect(find.text('Rate duty'), findsNothing);
  });
}
