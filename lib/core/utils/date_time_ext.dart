/// Date helpers shared across features. All "day" comparisons are local-time.
library;

/// Canonical day key used for habit logs: `yyyy-MM-dd` in local time.
String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

extension DateTimeExt on DateTime {
  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  DateTime get dayStart => DateTime(year, month, day);

  DateTime addDays(int days) => DateTime(year, month, day + days);

  /// Monday of the current week (local time).
  DateTime get weekStart {
    final weekday = this.weekday; // 1 = Monday
    return dayStart.addDays(1 - weekday);
  }
}
