import '../models/habit.dart';
import '../models/task.dart';

/// Actions the assistant can perform in the app on the user's behalf.
sealed class AssistantAction {
  const AssistantAction();
}

/// Creates a task, optionally with a due date.
final class CreateTaskAction extends AssistantAction {
  const CreateTaskAction({required this.title, this.dueDate});

  final String title;
  final DateTime? dueDate;
}

/// Creates a note.
final class CreateNoteAction extends AssistantAction {
  const CreateNoteAction({required this.title, this.body = ''});

  final String title;
  final String body;
}

/// Checks in a habit for today.
final class CheckInHabitAction extends AssistantAction {
  const CheckInHabitAction({required this.habitId, required this.habitName});

  final String habitId;
  final String habitName;
}

/// Reply produced by the on-device engine.
class AssistantReply {
  const AssistantReply({required this.text, this.actions = const []});

  final String text;
  final List<AssistantAction> actions;
}

/// Snapshot of the user's data the assistant reasons over.
class AssistantContext {
  const AssistantContext({
    required this.langCode,
    required this.now,
    this.name = '',
    this.tasks = const [],
    this.habits = const [],
    this.habitLogs = const {},
  });

  /// 'id' or 'en'.
  final String langCode;
  final DateTime now;
  final String name;
  final List<Task> tasks;
  final List<Habit> habits;
  final Map<String, Set<String>> habitLogs;

  bool get isIndonesian => langCode.startsWith('id');
}
