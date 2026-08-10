import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/services/self_certified_sick_day_guard.dart';

void main() {
  test('already selected short-circuits', () async {
    final guard = SelfCertifiedSickDayGuard(
      canAddHalfYear: (_) async => true,
      canAddYearly: (_) async => true,
    );

    final result = await guard.evaluate(
      date: DateTime(2026, 3, 10),
      currentSickDayType: 'self-certified',
    );

    expect(result.decision, SelfCertifiedSickDayDecision.alreadySelected);
    expect(result.halfYearName, 'First Half (Jan-Jun)');
  });

  test('half-year limit builds warning', () async {
    final guard = SelfCertifiedSickDayGuard(
      canAddHalfYear: (_) async => false,
      canAddYearly: (_) async => true,
      countForHalfYear: (_, __) async => 2,
      countForYear: (_) async => 2,
    );

    final result = await guard.evaluate(
      date: DateTime(2026, 8, 4),
      currentSickDayType: null,
    );

    expect(result.decision, SelfCertifiedSickDayDecision.limitReached);
    expect(result.warningMessage, contains('Second Half (Jul-Dec)'));
    expect(result.halfYearCount, 2);
    expect(result.yearlyCount, 2);
  });

  test('allowed when under both limits', () async {
    final guard = SelfCertifiedSickDayGuard(
      canAddHalfYear: (_) async => true,
      canAddYearly: (_) async => true,
    );

    final result = await guard.evaluate(
      date: DateTime(2026, 2, 1),
      currentSickDayType: null,
    );

    expect(result.decision, SelfCertifiedSickDayDecision.allowed);
    expect(result.remainingHalfYear, isNull);
  });

  test('remainingAfterSave loads remaining counts', () async {
    final guard = SelfCertifiedSickDayGuard(
      remainingForHalfYear: (_, __) async => 1,
      remainingForYear: (_) async => 3,
    );

    final result = await guard.remainingAfterSave(
      date: DateTime(2026, 2, 1),
    );

    expect(result.remainingHalfYear, 1);
    expect(result.remainingYearly, 3);
  });
}
