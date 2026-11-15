import 'package:flutter_test/flutter_test.dart';
import 'package:nara/core/models/habit.dart';
import 'package:nara/core/models/task.dart';
import 'package:nara/features/dashboard/dashboard_progress.dart';

void main() {
  final now = DateTime(2026, 11, 15, 14); // today, 2 PM
  final today = DateTime(2026, 11, 15);
  final yesterday = DateTime(2026, 11, 14);
  final tomorrow = DateTime(2026, 11, 16);

  Task task(String id, {bool done = false, DateTime? due}) => Task(
        id: id,
        title: id,
        done: done,
        dueDate: due,
        createdAt: now,
        updatedAt: now,
      );

  Habit habit(String id) => Habit(id: id, name: id, createdAt: now);

  test('habits contribute expected + done counts', () {
    final logs = {
      'a': {'2026-11-15'},
      'b': {'2026-11-14'}, // yesterday only
    };
    final (done, total) = dailyProgress(
      tasks: const [],
      habits: [habit('a'), habit('b'), habit('c')],
      habitLogs: logs,
      now: now,
    );
    expect(done, 1);
    expect(total, 3);
  });

  test('today-due and overdue tasks count; future tasks do not', () {
    final (done, total) = dailyProgress(
      tasks: [
        task('t1', due: today), // open, due today
        task('t2', due: yesterday), // overdue
        task('t3', due: tomorrow), // future — excluded
        task('t4', done: true, due: today), // done today
        task('t5'), // no due date — excluded
      ],
      habits: const [],
      habitLogs: const {},
      now: now,
    );
    expect(done, 1); // only t4 is done
    expect(total, 3); // t1, t2, t4
  });

  test('a done task due earlier still counts as done', () {
    final (done, total) = dailyProgress(
      tasks: [task('t1', done: true, due: yesterday)],
      habits: const [],
      habitLogs: const {},
      now: now,
    );
    expect(done, 1);
    expect(total, 1);
  });

  test('empty day yields 0/0', () {
    final (done, total) = dailyProgress(
      tasks: const [],
      habits: const [],
      habitLogs: const {},
      now: now,
    );
    expect(done, 0);
    expect(total, 0);
  });
}
