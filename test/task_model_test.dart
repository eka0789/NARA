import 'package:flutter_test/flutter_test.dart';
import 'package:nara/core/models/task.dart';
import 'package:nara/core/utils/date_time_ext.dart';
import 'package:nara/features/tasks/task_filter.dart';

void main() {
  final now = DateTime(2026, 11, 10, 9);

  Task task(
    String id, {
    bool done = false,
    DateTime? due,
    TaskPriority priority = TaskPriority.medium,
    String category = 'general',
  }) {
    return Task(
      id: id,
      title: 'Task $id',
      done: done,
      dueDate: due,
      priority: priority,
      category: category,
      createdAt: DateTime(2026, 11, 1),
      updatedAt: DateTime(2026, 11, 1),
    );
  }

  group('Task model', () {
    test('map round trip preserves all fields', () {
      final original = Task(
        id: 't1',
        title: 'Belanja',
        note: 'Telur, beras',
        done: true,
        priority: TaskPriority.high,
        category: 'work',
        dueDate: DateTime(2026, 11, 12, 14, 30),
        createdAt: DateTime(2026, 11, 1, 8),
        updatedAt: DateTime(2026, 11, 2, 9),
      );
      final restored = Task.fromMap(original.toMap());
      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.note, original.note);
      expect(restored.done, original.done);
      expect(restored.priority, original.priority);
      expect(restored.category, original.category);
      expect(restored.dueDate, original.dueDate);
      expect(restored.createdAt, original.createdAt);
      expect(restored.updatedAt, original.updatedAt);
    });

    test('copyWith can null out dueDate', () {
      final withDue = task('t1', due: DateTime(2026, 11, 11));
      final cleared = withDue.copyWith(dueDate: null);
      expect(cleared.dueDate, isNull);
    });

    test('isOverdue only for open past tasks', () {
      final overdue = task('t1', due: DateTime(2026, 11, 9));
      final future = task('t2', due: DateTime(2026, 11, 11));
      final donePast = task('t3', due: DateTime(2026, 11, 9), done: true);
      expect(overdue.isOverdue(now), isTrue);
      expect(future.isOverdue(now), isFalse);
      expect(donePast.isOverdue(now), isFalse);
    });
  });

  group('filterTasks', () {
    test('today includes due-today and overdue, excludes future/done', () {
      final tasks = [
        task('a', due: DateTime(2026, 11, 10)),
        task('b', due: DateTime(2026, 11, 9)), // overdue
        task('c', due: DateTime(2026, 11, 11)),
        task('d', due: DateTime(2026, 11, 10), done: true),
        task('e'), // no due date
      ];
      final visible = filterTasks(tasks, TaskFilter.today, now);
      expect(visible.map((t) => t.id), ['b', 'a']);
    });

    test('upcoming is future-dated only', () {
      final tasks = [
        task('a', due: DateTime(2026, 11, 11)),
        task('b', due: DateTime(2026, 11, 10)),
      ];
      final visible = filterTasks(tasks, TaskFilter.upcoming, now);
      expect(visible.map((t) => t.id), ['a']);
    });

    test('all puts overdue first then priority then date', () {
      final tasks = [
        task('low-future', priority: TaskPriority.low, due: DateTime(2026, 11, 11)),
        task('high-future', priority: TaskPriority.high, due: DateTime(2026, 11, 11)),
        task('overdue', priority: TaskPriority.low, due: DateTime(2026, 11, 9)),
        task('done', done: true),
      ];
      final visible = filterTasks(tasks, TaskFilter.all, now);
      expect(visible.map((t) => t.id).toList(), [
        'overdue',
        'high-future',
        'low-future',
        'done',
      ]);
    });
  });

  group('DateTimeExt', () {
    test('weekStart returns Monday', () {
      final tuesday = DateTime(2026, 11, 10); // Tuesday
      final monday = tuesday.weekStart;
      expect(monday.weekday, DateTime.monday);
      expect(dateKey(monday), '2026-11-09');
    });

    test('isSameDay ignores time', () {
      expect(
        DateTime(2026, 11, 10, 8).isSameDay(DateTime(2026, 11, 10, 23)),
        isTrue,
      );
      expect(
        DateTime(2026, 11, 10).isSameDay(DateTime(2026, 11, 11)),
        isFalse,
      );
    });
  });
}
