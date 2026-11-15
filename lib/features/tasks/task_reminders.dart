import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/task.dart';
import '../../core/notifications/reminder_service.dart';
import '../data/data_providers.dart';
import '../settings/settings_providers.dart';

/// One-shot notification id for a task: a deterministic 31-bit hash so
/// reschedules and cancels hit the same notification across sessions.
/// (Collision risk between two tasks is negligible for a personal list.)
int taskNotificationId(Task task) => task.id.hashCode & 0x7fffffff;

/// Keeps scheduled due-date notifications in sync with the task stream.
///
/// Every task mutation — form sheet, AI-created tasks, undo, delete, "delete
/// all data" — flows through [tasksProvider], so listening there is the
/// single scheduling point: new/moved future due dates are (re)scheduled,
/// done/deleted/past ones are cancelled. Activate by watching from the app
/// shell so it lives as long as the UI does.
final taskReminderSyncProvider = Provider<void>((ref) {
  var scheduled = <int, DateTime>{};
  ref.listen(tasksProvider, (_, next) {
    final tasks = next.value;
    if (tasks == null) return; // wait for the first real emission

    final now = DateTime.now();
    final desired = <int, DateTime>{
      for (final task in tasks)
        if (!task.done &&
            task.dueDate != null &&
            task.dueDate!.isAfter(now))
          taskNotificationId(task): task.dueDate!,
    };

    final service = ReminderService.instance;
    final lang = resolveNotificationLanguage(ref.read(prefsProvider));
    for (final entry in desired.entries) {
      if (scheduled[entry.key] == entry.value) continue;
      unawaited(service.scheduleTaskReminder(
        notificationId: entry.key,
        title: tasks.firstWhere((t) => taskNotificationId(t) == entry.key).title,
        when: entry.value,
        langCode: lang,
      ));
    }
    for (final id in scheduled.keys.where((id) => !desired.containsKey(id))) {
      unawaited(service.cancel(id));
    }
    scheduled = desired;
  });
});
