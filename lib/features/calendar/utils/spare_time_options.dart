/// Start times offered when adding a spare duty (15-minute steps), plus Custom.
const spareCustomTimeOption = 'Custom';

bool isSpareCustomTimeOption(String value) => value == spareCustomTimeOption;

String formatSpareClockTime(int hour, int minute) {
  final hourStr = hour.toString().padLeft(2, '0');
  final minuteStr = minute.toString().padLeft(2, '0');
  return '$hourStr:$minuteStr';
}

List<String> spareTimeOptions({
  int firstHour = 4,
  int lastHour = 19,
}) {
  final times = <String>[];
  for (var hour = firstHour; hour <= lastHour; hour++) {
    for (var minute = 0; minute < 60; minute += 15) {
      if (hour == lastHour && minute > 0) continue;
      times.add(formatSpareClockTime(hour, minute));
    }
  }
  times.add(spareCustomTimeOption);
  return times;
}
