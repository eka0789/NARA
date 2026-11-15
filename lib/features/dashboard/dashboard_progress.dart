import '../../core/models/habit.dart';
import '../../core/models/task.dart';
import '../../core/utils/date_time_ext.dart';

/// Today's completion counts for the dashboard progress ring.
///
/// A habit counts as expected every day (total) and done when its day key is
/// logged today. Tasks count when they are (or were) commitments for today:
/// open tasks due today or overdue, and tasks already done that were due
/// today or earlier. Open future tasks are not part of today's ring.
(int done, int total) dailyProgress({
  required List<Task> tasks,
  required List<Habit> habits,
  required Map<String, Set<String>> habitLogs,
  required DateTime now,
}) {
  final todayEnd = now.dayStart.addDays(1);

  var taskDone = 0;
  var taskTotal = 0;
  for (final task in tasks) {
    final due = task.dueDate;
    if (due == null) continue;
    final dueOrOverdue = due.isBefore(todayEnd);
    if (task.done) {
      if (dueOrOverdue) {
        taskDone++;
        taskTotal++;
      }
    } else if (dueOrOverdue) {
      taskTotal++;
    }
  }

  final todayKey = dateKey(now);
  final habitDone = habits
      .where((h) => (habitLogs[h.id] ?? const <String>{}).contains(todayKey))
      .length;

  return (taskDone + habitDone, taskTotal + habits.length);
}
