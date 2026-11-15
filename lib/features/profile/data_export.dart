import 'dart:convert';

import '../../core/models/habit.dart';
import '../../core/models/note.dart';
import '../../core/models/task.dart';
import '../../core/models/user_profile.dart';

/// Builds a portable JSON export of everything the user owns: profile,
/// tasks, notes, habits and their check-in logs. The clipboard is the
/// transport (no extra plugin) — paste into any file or notes app as a
/// personal backup.
String buildExportJson({
  UserProfile? profile,
  required List<Task> tasks,
  required List<Note> notes,
  required List<Habit> habits,
  required Map<String, Set<String>> habitLogs,
}) {
  return const JsonEncoder.withIndent('  ').convert({
    'app': 'NARA',
    'exportedAt': DateTime.now().toIso8601String(),
    'profile': profile == null
        ? null
        : {'name': profile.name, 'email': profile.email},
    'tasks': [
      for (final task in tasks)
        {
          'title': task.title,
          'note': task.note,
          'done': task.done,
          'priority': task.priority.name,
          'category': task.category,
          'dueDate': task.dueDate?.toIso8601String(),
          'createdAt': task.createdAt.toIso8601String(),
        },
    ],
    'notes': [
      for (final note in notes)
        {
          'title': note.title,
          'body': note.body,
          'pinned': note.pinned,
          'tags': note.tags,
          'parentId': note.parentId,
          'updatedAt': note.updatedAt.toIso8601String(),
        },
    ],
    'habits': [
      for (final habit in habits)
        {
          'name': habit.name,
          'emoji': habit.emoji,
          'targetPerWeek': habit.targetPerWeek,
          'logs': [
            for (final day in habitLogs[habit.id] ?? const <String>{}) day,
          ]..sort(),
        },
    ],
  });
}
