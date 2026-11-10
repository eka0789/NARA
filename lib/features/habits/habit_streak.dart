/// Streak math for habit check-in day keys.
///
/// A streak is a run of consecutive calendar days. [streakFor] counts the
/// current run ending today (or yesterday when today is not yet checked in,
/// so a morning visit does not read as "broken"). [bestStreak] scans all
/// history up to today.
library;

import '../../core/utils/date_time_ext.dart';

int streakFor(Set<String> days, DateTime today) {
  if (days.isEmpty) return 0;
  var cursor = today.dayStart;
  if (!days.contains(dateKey(cursor))) {
    cursor = cursor.addDays(-1);
  }
  var streak = 0;
  while (days.contains(dateKey(cursor))) {
    streak++;
    cursor = cursor.addDays(-1);
  }
  return streak;
}

int bestStreak(Set<String> days, DateTime today) {
  if (days.isEmpty) return 0;
  final sorted = [
    for (final key in days)
      if (DateTime.tryParse(key) != null) DateTime.parse(key).dayStart,
  ]..sort();
  var best = 0;
  var run = 0;
  DateTime? previous;
  for (final day in sorted) {
    if (day.isAfter(today.dayStart)) break;
    run = (previous != null && day.isSameDay(previous.addDays(1))) ? run + 1 : 1;
    if (run > best) best = run;
    previous = day;
  }
  return best;
}
