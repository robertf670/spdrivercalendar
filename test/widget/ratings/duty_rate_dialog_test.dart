import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/ratings/duty_rate_dialog.dart';
import 'package:spdrivercalendar/features/ratings/duty_rating_key.dart';
import 'package:spdrivercalendar/features/ratings/duty_rating_vote.dart';

void main() {
  testWidgets('existing rating can be removed as well as updated', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: DutyRateDialog(
          target: DutyRatingTarget(
            dutyCode: 'PZ1/39',
            dayType: 'MON-FRI',
            era: 'current',
            date: '2026-09-25',
          ),
          existing: DutyRatingVote(
            id: 'vote-1',
            userId: 'user-1',
            dutyCode: 'PZ1/39',
            dayType: 'MON-FRI',
            era: 'current',
            date: '2026-09-25',
            score: 7,
            note: 'Long day',
          ),
        ),
      ),
    );

    expect(find.text('Update rating'), findsOneWidget);
    expect(find.text('Remove'), findsOneWidget);
    expect(find.text('Update'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
