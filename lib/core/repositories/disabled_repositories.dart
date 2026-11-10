/// No-op repositories used in the brief window while Firebase mode is
/// enabled but auth has not resolved yet (all screens are behind login
/// during that time, so these never back visible UI).
library;

import '../../features/chat/chat_repository.dart';
import '../../features/habits/habit_repository.dart';
import '../../features/notes/note_repository.dart';
import '../../features/tasks/task_repository.dart';
import '../models/chat_message.dart';
import '../models/habit.dart';
import '../models/note.dart';
import '../models/task.dart';

final class DisabledTaskRepository implements TaskRepository {
  const DisabledTaskRepository();

  @override
  Stream<List<Task>> watchAll() => Stream.value(const <Task>[]);

  @override
  Future<List<Task>> getAll() async => const <Task>[];

  @override
  Future<void> add(Task task) async {}

  @override
  Future<void> update(Task task) async {}

  @override
  Future<void> delete(String id) async {}

  @override
  Future<void> deleteAll() async {}
}

final class DisabledNoteRepository implements NoteRepository {
  const DisabledNoteRepository();

  @override
  Stream<List<Note>> watchAll() => Stream.value(const <Note>[]);

  @override
  Future<List<Note>> getAll() async => const <Note>[];

  @override
  Future<void> add(Note note) async {}

  @override
  Future<void> update(Note note) async {}

  @override
  Future<void> delete(String id) async {}

  @override
  Future<void> deleteAll() async {}
}

final class DisabledHabitRepository implements HabitRepository {
  const DisabledHabitRepository();

  @override
  Stream<List<Habit>> watchAll() => Stream.value(const <Habit>[]);

  @override
  Future<List<Habit>> getAll() async => const <Habit>[];

  @override
  Future<void> add(Habit habit) async {}

  @override
  Future<void> update(Habit habit) async {}

  @override
  Future<void> delete(String id) async {}

  @override
  Future<void> deleteAll() async {}

  @override
  Stream<Map<String, Set<String>>> watchLogs() =>
      Stream.value(const <String, Set<String>>{});

  @override
  Future<void> toggleLog(String habitId, String dateKey) async {}
}

final class DisabledChatRepository implements ChatRepository {
  const DisabledChatRepository();

  @override
  Stream<List<ChatMessage>> watchMessages() =>
      Stream.value(const <ChatMessage>[]);

  @override
  Future<void> addMessage(ChatMessage message) async {}

  @override
  Future<void> clear() async {}
}
