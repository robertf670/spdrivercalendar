import 'package:spdrivercalendar/services/self_certified_sick_days_service.dart';

/// Outcome of checking whether a self-certified sick day can be saved.
enum SelfCertifiedSickDayDecision {
  alreadySelected,
  limitReached,
  allowed,
}

class SelfCertifiedSickDayCheckResult {
  const SelfCertifiedSickDayCheckResult({
    required this.decision,
    required this.year,
    required this.halfYear,
    required this.halfYearName,
    this.warningMessage,
    this.halfYearCount,
    this.yearlyCount,
    this.remainingHalfYear,
    this.remainingYearly,
  });

  final SelfCertifiedSickDayDecision decision;
  final int year;
  final String halfYear;
  final String halfYearName;
  final String? warningMessage;
  final int? halfYearCount;
  final int? yearlyCount;
  final int? remainingHalfYear;
  final int? remainingYearly;
}

typedef SelfCertifiedCanAdd = Future<bool> Function(DateTime date);
typedef SelfCertifiedCountLookup = Future<int> Function(int year, String halfYear);
typedef SelfCertifiedYearCountLookup = Future<int> Function(int year);
typedef SelfCertifiedRemainingLookup = Future<int> Function(int year, String halfYear);
typedef SelfCertifiedYearRemainingLookup = Future<int> Function(int year);

/// Evaluates self-certified sick-day limits before persisting a status change.
class SelfCertifiedSickDayGuard {
  SelfCertifiedSickDayGuard({
    SelfCertifiedCanAdd? canAddHalfYear,
    SelfCertifiedCanAdd? canAddYearly,
    SelfCertifiedCountLookup? countForHalfYear,
    SelfCertifiedYearCountLookup? countForYear,
    SelfCertifiedRemainingLookup? remainingForHalfYear,
    SelfCertifiedYearRemainingLookup? remainingForYear,
  })  : _canAddHalfYear =
            canAddHalfYear ?? SelfCertifiedSickDaysService.canAddSelfCertifiedDay,
        _canAddYearly = canAddYearly ??
            SelfCertifiedSickDaysService.canAddSelfCertifiedDayYearly,
        _countForHalfYear =
            countForHalfYear ?? SelfCertifiedSickDaysService.getCountForHalfYear,
        _countForYear =
            countForYear ?? SelfCertifiedSickDaysService.getCountForYear,
        _remainingForHalfYear = remainingForHalfYear ??
            SelfCertifiedSickDaysService.getRemainingForHalfYear,
        _remainingForYear =
            remainingForYear ?? SelfCertifiedSickDaysService.getRemainingForYear;

  final SelfCertifiedCanAdd _canAddHalfYear;
  final SelfCertifiedCanAdd _canAddYearly;
  final SelfCertifiedCountLookup _countForHalfYear;
  final SelfCertifiedYearCountLookup _countForYear;
  final SelfCertifiedRemainingLookup _remainingForHalfYear;
  final SelfCertifiedYearRemainingLookup _remainingForYear;

  Future<SelfCertifiedSickDayCheckResult> evaluate({
    required DateTime date,
    required String? currentSickDayType,
  }) async {
    final year = date.year;
    final halfYear = SelfCertifiedSickDaysService.getHalfYear(date);
    final halfYearName =
        halfYear == 'first' ? 'First Half (Jan-Jun)' : 'Second Half (Jul-Dec)';

    if (currentSickDayType == 'self-certified') {
      return SelfCertifiedSickDayCheckResult(
        decision: SelfCertifiedSickDayDecision.alreadySelected,
        year: year,
        halfYear: halfYear,
        halfYearName: halfYearName,
      );
    }

    final canAddHalfYear = await _canAddHalfYear(date);
    final canAddYearly = await _canAddYearly(date);

    if (!canAddHalfYear || !canAddYearly) {
      final halfYearCount = await _countForHalfYear(year, halfYear);
      final yearlyCount = await _countForYear(year);

      final String warningMessage;
      if (!canAddHalfYear && !canAddYearly) {
        warningMessage =
            'You have already used your limit of 2 self-certified days in the $halfYearName and 4 for the year. You cannot add more self-certified days.';
      } else if (!canAddHalfYear) {
        warningMessage =
            'You have already used your limit of 2 self-certified days in the $halfYearName. You cannot add more self-certified days for this half-year.';
      } else {
        warningMessage =
            'You have already used your limit of 4 self-certified days for the year. You cannot add more self-certified days.';
      }

      return SelfCertifiedSickDayCheckResult(
        decision: SelfCertifiedSickDayDecision.limitReached,
        year: year,
        halfYear: halfYear,
        halfYearName: halfYearName,
        warningMessage: warningMessage,
        halfYearCount: halfYearCount,
        yearlyCount: yearlyCount,
      );
    }

    return SelfCertifiedSickDayCheckResult(
      decision: SelfCertifiedSickDayDecision.allowed,
      year: year,
      halfYear: halfYear,
      halfYearName: halfYearName,
    );
  }

  /// Remaining counts after a successful save (matches prior snackbar wording).
  Future<SelfCertifiedSickDayCheckResult> remainingAfterSave({
    required DateTime date,
  }) async {
    final year = date.year;
    final halfYear = SelfCertifiedSickDaysService.getHalfYear(date);
    final halfYearName =
        halfYear == 'first' ? 'First Half (Jan-Jun)' : 'Second Half (Jul-Dec)';

    return SelfCertifiedSickDayCheckResult(
      decision: SelfCertifiedSickDayDecision.allowed,
      year: year,
      halfYear: halfYear,
      halfYearName: halfYearName,
      remainingHalfYear: await _remainingForHalfYear(year, halfYear),
      remainingYearly: await _remainingForYear(year),
    );
  }
}
