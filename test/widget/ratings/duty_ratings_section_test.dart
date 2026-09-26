import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/ratings/duty_rating_aggregate.dart';
import 'package:spdrivercalendar/features/ratings/duty_ratings_section.dart';

void main() {
  testWidgets('empty ratings show the empty copy and View all', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DutyRatingsSection(
            summaries: [],
            notes: [],
          ),
        ),
      ),
    );

    expect(find.text('No ratings yet'), findsOneWidget);
    expect(find.text('View all'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('top and lowest ignore duties with fewer than 5 ratings',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DutyRatingsSection(
            summaries: const [
              DutyRatingSummaryData(
                dutyCode: 'PZ1/01',
                dayType: 'MON-FRI',
                era: 'current',
                zone: '1',
                ratingCount: 2,
                ratingSum: 20,
                histogram: {10: 2},
              ),
            ],
            notes: const [],
          ),
        ),
      ),
    );

    expect(find.text('Need 5 ratings before a duty can rank.'), findsOneWidget);
    expect(find.text('PZ1/01'), findsNothing);
  });
}
