import '../../core/models/habit.dart';
import '../../core/models/note.dart';
import '../../core/models/task.dart';

/// One Quick Find result — which kind of thing matched and the thing itself.
sealed class SearchHit {
  const SearchHit();
}

final class TaskHit extends SearchHit {
  const TaskHit(this.task);

  final Task task;
}

final class NoteHit extends SearchHit {
  const NoteHit(this.note);

  final Note note;
}

final class HabitHit extends SearchHit {
  const HabitHit(this.habit);

  final Habit habit;
}

/// Quick Find across everything the user owns — the ⌘K of the app.
/// Case-insensitive substring match over the most useful fields (task
/// title/notes, page title/body/tags, habit name). Empty queries yield no
/// results so the UI can show its own starting state.
List<SearchHit> quickFind({
  required String query,
  required List<Task> tasks,
  required List<Note> notes,
  required List<Habit> habits,
  int limitPerGroup = 5,
}) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];

  final taskHits = [
    for (final task in tasks)
      if (task.title.toLowerCase().contains(q) ||
          task.note.toLowerCase().contains(q))
        TaskHit(task),
  ].take(limitPerGroup).toList();

  final noteHits = [
    for (final note in notes)
      if (note.matches(q)) NoteHit(note),
  ].take(limitPerGroup).toList();

  final habitHits = [
    for (final habit in habits)
      if (habit.name.toLowerCase().contains(q)) HabitHit(habit),
  ].take(limitPerGroup).toList();

  return [...taskHits, ...noteHits, ...habitHits];
}
