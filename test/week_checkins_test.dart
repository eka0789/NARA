import 'package:flutter_test/flutter_test.dart';
import 'package:nara/core/utils/date_time_ext.dart';
import 'package:nara/features/habits/habit_streak.dart';

void main() {
  test('weekCheckIns sums every habit per day, Monday..Sunday', () {
    final wednesday = DateTime(2026, 11, 11); // a Wednesday
    final counts = weekCheckIns([
      // Habit A: Mon + Wed
      {'2026-11-09', '2026-11-11', '2026-11-20'},
      // Habit B: Wed only
      const {'2026-11-11'},
      // Habit C: empty
      const {},
    ], wednesday);

    expect(counts, [1, 0, 2, 0, 0, 0, 0]);
    expect(counts.length, 7);
  });

  test('counts never include next week or the deleted-habit gap', () {
    final sunday = DateTime(2026, 11, 15); // a Sunday
    final counts = weekCheckIns([
      {'2026-11-09', '2026-11-15', '2026-11-16'}, // Mon, Sun, next Mon
      {'2026-11-16'},
    ], sunday);
    expect(counts, [1, 0, 0, 0, 0, 0, 1]);
    expect(dateKey(sunday.weekStart), '2026-11-09');
  });

  test('no data yields seven zero buckets', () {
    final counts = weekCheckIns(const [], DateTime(2026, 11, 15));
    expect(counts, List.filled(7, 0));
  });
}
