import 'package:flutter_test/flutter_test.dart';
import 'package:nara/core/models/habit.dart';
import 'package:nara/core/models/note.dart';
import 'package:nara/core/models/task.dart';
import 'package:nara/features/search/quick_find.dart';

void main() {
  final now = DateTime(2026, 11, 15);

  Task task(String title, {String note = ''}) => Task(
        id: title,
        title: title,
        note: note,
        createdAt: now,
        updatedAt: now,
      );

  Note note(String title, {String body = '', List<String> tags = const []}) =>
      Note(
        id: title,
        title: title,
        body: body,
        tags: tags,
        createdAt: now,
        updatedAt: now,
      );

  Habit habit(String name) => Habit(id: name, name: name, createdAt: now);

  test('matches across tasks, pages (incl. tags) and habits', () {
    final hits = quickFind(
      query: 'pandan',
      tasks: [task('Beli pandan'), task('Rapat')],
      notes: [note('Ide kue', body: 'pandan layer'), note('Catatan kerja', tags: ['pandan'])],
      habits: [habit('Olahraga')],
    );

    expect(hits.whereType<TaskHit>().length, 1);
    expect(hits.whereType<NoteHit>().length, 2); // body + tag matches
    expect(hits.whereType<HabitHit>().length, 0);
  });

  test('is case-insensitive and trims the query', () => expect(
        quickFind(
          query: '  RAPAT  ',
          tasks: [task('Rapat desain')],
          notes: const [],
          habits: const [],
        ).length,
        1,
      ));

  test('empty query yields nothing', () {
    final hits = quickFind(
      query: '   ',
      tasks: [task('Rapat')],
      notes: [note('Ide')],
      habits: [habit('Baca')],
    );
    expect(hits, isEmpty);
  });

  test('limitPerGroup caps each group', () {
    final hits = quickFind(
      query: 'a',
      tasks: [task('a1'), task('a2'), task('a3')],
      notes: [note('aa'), note('ab'), note('ac'), note('ad')],
      habits: [habit('aa'), habit('ab')],
      limitPerGroup: 2,
    );
    expect(hits.whereType<TaskHit>().length, 2);
    expect(hits.whereType<NoteHit>().length, 2);
    expect(hits.whereType<HabitHit>().length, 2);
  });
}
