import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/dialogs/add_holidays_dialog.dart';

void main() {
  testWidgets('fits 320px and routes holiday type selections', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var summer = false;
    var winter = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => AddHolidaysDialog(
                        loadBalances: () async => {
                          'annualLeaveToday': 20,
                          'annualLeaveRemaining': 18,
                          'annualLeaveBooked': 2,
                          'daysInLieuToday': 3,
                          'daysInLieuRemaining': 2,
                          'daysInLieuBooked': 1,
                        },
                        hasExistingHolidays: false,
                        existingHolidaysSection: const SizedBox.shrink(),
                        onShowBookedAnnualLeave: () {},
                        onShowBookedDaysInLieu: () {},
                        onSummerHoliday: () => summer = true,
                        onWinterHoliday: () => winter = true,
                        onOtherHoliday: () {},
                        onUnpaidLeave: () {},
                        onDayInLieu: () {},
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final dialogRect = tester.getRect(find.byType(Dialog));
    expect(dialogRect.left, greaterThanOrEqualTo(0));
    expect(dialogRect.right, lessThanOrEqualTo(320));
    expect(find.text('Add Holidays'), findsOneWidget);
    expect(find.text('Annual Leave'), findsOneWidget);
    expect(find.text('Summer Holiday'), findsOneWidget);

    await tester.tap(find.text('Summer Holiday'));
    await tester.pumpAndSettle();
    expect(summer, isTrue);

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Winter (1 Week)'));
    await tester.pumpAndSettle();
    expect(winter, isTrue);
  });
}
