import 'package:flutter_test/flutter_test.dart';
import 'package:nara/features/habits/habit_streak.dart';

void main() {
  final today = DateTime(2026, 11, 10);

  Set<String> days(List<DateTime> dates) =>
      dates.map((d) => d.toIso8601String().substring(0, 10)).toSet();

  group('streakFor', () {
    test('empty history', () {
      expect(streakFor({}, today), 0);
    });

    test('counts run ending today', () {
      final log = days([
        DateTime(2026, 11, 8),
        DateTime(2026, 11, 9),
        DateTime(2026, 11, 10),
      ]);
      expect(streakFor(log, today), 3);
    });

    test('today missing does not break yesterday-ending streak', () {
      final log = days([
        DateTime(2026, 11, 8),
        DateTime(2026, 11, 9),
      ]);
      expect(streakFor(log, today), 2);
    });

    test('gap breaks the streak', () {
      final log = days([
        DateTime(2026, 11, 6),
        DateTime(2026, 11, 7),
        DateTime(2026, 11, 9),
        DateTime(2026, 11, 10),
      ]);
      expect(streakFor(log, today), 2);
    });
  });

  group('bestStreak', () {
    test('finds longest historical run', () {
      final log = days([
        DateTime(2026, 10, 1),
        DateTime(2026, 10, 2),
        DateTime(2026, 10, 3),
        DateTime(2026, 10, 4),
        DateTime(2026, 10, 6),
        DateTime(2026, 10, 7),
      ]);
      expect(bestStreak(log, today), 4);
    });

    test('ignores future dates', () {
      final log = days([
        DateTime(2026, 11, 10),
        DateTime(2026, 11, 11),
        DateTime(2026, 11, 12),
      ]);
      expect(bestStreak(log, today), 1);
    });
  });
}
