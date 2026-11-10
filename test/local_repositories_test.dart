import 'package:flutter_test/flutter_test.dart';
import 'package:nara/core/models/habit.dart';
import 'package:nara/core/models/task.dart';
import 'package:nara/core/storage/local_keys.dart';
import 'package:nara/core/storage/local_store.dart';
import 'package:nara/features/habits/habit_repository.dart';
import 'package:nara/features/tasks/task_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late LocalStore store;
  late LocalTaskRepository tasks;
  late LocalHabitRepository habits;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = LocalStore(await SharedPreferences.getInstance());
    tasks = LocalTaskRepository(store);
    habits = LocalHabitRepository(store);
  });

  group('LocalTaskRepository', () {
    test('add, watch, update, delete', () async {
      final task = Task(
        id: 't1',
        title: 'First',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      await tasks.add(task);

      final first = await tasks.watchAll().first;
      expect(first, hasLength(1));
      expect(first.single.title, 'First');

      await tasks.update(task.copyWith(done: true, title: 'Updated'));
      final afterUpdate = await tasks.getAll();
      expect(afterUpdate.single.done, isTrue);
      expect(afterUpdate.single.title, 'Updated');

      await tasks.delete('t1');
      expect(await tasks.getAll(), isEmpty);
    });

    test('deleteAll clears everything', () async {
      for (var i = 0; i < 3; i++) {
        await tasks.add(Task(
          id: 't$i',
          title: 'T$i',
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ));
      }
      await tasks.deleteAll();
      expect(await tasks.getAll(), isEmpty);
      expect(store.readList(LocalKeys.tasks), isEmpty);
    });
  });

  group('LocalHabitRepository (logs)', () {
    test('toggleLog adds and removes a day', () async {
      await habits.add(Habit(id: 'h1', name: 'Read', createdAt: DateTime(2026)));
      await habits.toggleLog('h1', '2026-11-10');

      var logs = await habits.watchLogs().first;
      expect(logs['h1'], contains('2026-11-10'));

      await habits.toggleLog('h1', '2026-11-10');
      logs = await habits.watchLogs().first;
      expect(logs['h1'] ?? {}, isNot(contains('2026-11-10')));
    });

    test('deleting a habit removes its logs', () async {
      await habits.add(Habit(id: 'h1', name: 'Read', createdAt: DateTime(2026)));
      await habits.toggleLog('h1', '2026-11-10');
      await habits.delete('h1');

      final logs = await habits.watchLogs().first;
      expect(logs.containsKey('h1'), isFalse);
      expect(await habits.getAll(), isEmpty);
    });
  });
}
