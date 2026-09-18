/// Spread-over helpers used by Statistics.
class SpreadPay {
  static const Duration threshold = Duration(hours: 10);

  static Duration overThreshold(Duration? spreadTime) {
    if (spreadTime == null || spreadTime <= threshold) {
      return Duration.zero;
    }
    return spreadTime - threshold;
  }

  static bool hasNoSpreadPay(String title) {
    final code = title.startsWith('Shift: ') ? title.substring(7) : title;
    return code.startsWith('SP') ||
        code == '22B/01' ||
        code == 'Union' ||
        code == 'Mentor';
  }

  /// Spread is Monday–Friday only, including duties worked on a weekday rest day.
  static bool isSpreadWeekday(int weekday) {
    return weekday >= DateTime.monday && weekday <= DateTime.friday;
  }

  static Duration? parseCsvDuration(String? raw) {
    if (raw == null) return null;
    final value = raw.trim();
    if (value.isEmpty || value.toLowerCase() == 'nan') return null;
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final hours = int.tryParse(parts[0]);
    final minutes = int.tryParse(parts[1]);
    if (hours == null || minutes == null) return null;
    return Duration(hours: hours, minutes: minutes);
  }

  static List<String> uniSpreadFiles(String dayOfWeek) {
    if (dayOfWeek == 'SAT' || dayOfWeek == 'SUN') {
      return const ['UNI_7DAYs.csv', 'UNI_M-F.csv'];
    }
    return const ['UNI_M-F.csv', 'UNI_7DAYs.csv'];
  }
}
