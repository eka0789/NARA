import '../../core/models/task.dart';
import '../../core/utils/date_time_ext.dart';

/// Task list filters.
enum TaskFilter { all, today, upcoming, done }

/// Pure filter+sort logic so the list behaves identically everywhere and is
/// unit-testable.
///
/// Ordering rules:
/// - open tasks: overdue first, then by due date, then by priority (high→low)
/// - done tasks go last (only relevant for [TaskFilter.all]).
List<Task> filterTasks(List<Task> tasks, TaskFilter filter, DateTime now) {
  bool Function(Task) predicate;
  switch (filter) {
    case TaskFilter.all:
      predicate = (_) => true;
    case TaskFilter.today:
      predicate = (t) =>
          !t.done &&
          t.dueDate != null &&
          (t.dueDate!.isSameDay(now) || t.dueDate!.isBefore(now.dayStart));
    case TaskFilter.upcoming:
      predicate = (t) =>
          !t.done && t.dueDate != null && t.dueDate!.isAfter(now.dayStart);
    case TaskFilter.done:
      predicate = (t) => t.done;
  }

  final selected = tasks.where(predicate).toList();
  int rank(Task t) {
    if (t.done) return 2;
    if (t.isOverdue(now)) return 0;
    return 1;
  }

  int dueValue(Task t) =>
      t.dueDate?.millisecondsSinceEpoch ??
      DateTime(now.year, now.month, now.day + 3650).millisecondsSinceEpoch;

  selected.sort((a, b) {
    final byRank = rank(a).compareTo(rank(b));
    if (byRank != 0) return byRank;
    final byPriority = b.priority.index.compareTo(a.priority.index);
    if (byPriority != 0) return byPriority;
    return dueValue(a).compareTo(dueValue(b));
  });
  return selected;
}
