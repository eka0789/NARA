import 'package:flutter_test/flutter_test.dart';
import 'package:nara/core/ai/assistant_context.dart';
import 'package:nara/core/ai/assistant_engine.dart';
import 'package:nara/core/models/habit.dart';
import 'package:nara/core/models/task.dart';
import 'package:nara/core/utils/date_time_ext.dart';

void main() {
  final engine = AssistantEngine();

  AssistantContext ctx({
    String lang = 'id',
    List<Task> tasks = const [],
    List<Habit> habits = const [],
    Map<String, Set<String>> logs = const {},
  }) {
    return AssistantContext(
      langCode: lang,
      now: DateTime(2026, 11, 10, 9), // Tuesday, 09:00
      name: 'Sari',
      tasks: tasks,
      habits: habits,
      habitLogs: logs,
    );
  }

  Task task(
    String id,
    String title, {
    bool done = false,
    DateTime? due,
    TaskPriority priority = TaskPriority.medium,
  }) {
    return Task(
      id: id,
      title: title,
      done: done,
      dueDate: due,
      priority: priority,
      createdAt: DateTime(2026, 11, 1),
      updatedAt: DateTime(2026, 11, 1),
    );
  }

  group('AssistantEngine — task creation (Indonesian)', () {
    test('creates a task for tomorrow', () {
      final reply = engine.respond('buat tugas belanja bulanan besok', ctx());
      final action = reply.actions.whereType<CreateTaskAction>().firstOrNull;
      expect(action, isNotNull);
      expect(action!.title, 'belanja bulanan');
      expect(action.dueDate, DateTime(2026, 11, 11));
      expect(reply.text, contains('belanja bulanan'));
    });

    test('creates a task today with a time', () {
      final reply = engine.respond('tugas rapat hari ini jam 14:30', ctx());
      final action = reply.actions.whereType<CreateTaskAction>().firstOrNull;
      expect(action, isNotNull);
      expect(action!.title, 'rapat');
      expect(action.dueDate, DateTime(2026, 11, 10, 14, 30));
    });

    test('quoted titles survive date stripping', () {
      final reply = engine.respond(
        'buat tugas "belanja besok sekalian" lusa',
        ctx(),
      );
      final action = reply.actions.whereType<CreateTaskAction>().firstOrNull;
      expect(action!.title, 'belanja besok sekalian');
      expect(action.dueDate, DateTime(2026, 11, 12));
    });

    test('english reminder creates a task', () {
      final reply = engine.respond(
        'remind me to stretch tomorrow at 5pm',
        ctx(lang: 'en'),
      );
      final action = reply.actions.whereType<CreateTaskAction>().firstOrNull;
      expect(action, isNotNull);
      expect(action!.title, 'stretch');
      expect(action.dueDate, DateTime(2026, 11, 11, 17));
    });

    test('plain chat without trigger verbs does not create tasks', () {
      final reply = engine.respond('tugas itu berat ya', ctx());
      expect(reply.actions, isEmpty);
    });
  });

  group('AssistantEngine — other intents', () {
    test('lists open tasks', () {
      final reply = engine.respond(
        'lihat tugas saya',
        ctx(tasks: [
          task('1', 'High one', priority: TaskPriority.high),
          task('2', 'Done one', done: true),
        ]),
      );
      expect(reply.text, contains('High one'));
      expect(reply.text, isNot(contains('Done one')));
    });

    test('creates a note', () {
      final reply = engine.respond('catat bahwa ide aplikasi kue pandan', ctx());
      final action = reply.actions.whereType<CreateNoteAction>().firstOrNull;
      expect(action, isNotNull);
      expect(action!.title, 'ide aplikasi kue pandan');
    });

    test('checks in a habit by name', () {
      final habit = Habit(id: 'h1', name: 'Olahraga', emoji: '🏃', createdAt: DateTime(2026));
      final reply = engine.respond('sudah olahraga hari ini', ctx(habits: [habit]));
      final action = reply.actions.whereType<CheckInHabitAction>().firstOrNull;
      expect(action, isNotNull);
      expect(action!.habitId, 'h1');
    });

    test('reports habit status with streaks', () {
      final habit = Habit(id: 'h1', name: 'Baca', emoji: '📖', createdAt: DateTime(2026));
      final logs = {
        'h1': {'2026-11-08', '2026-11-09', '2026-11-10'},
      };
      final reply = engine.respond('bagaimana kebiasaanku?', ctx(habits: [habit], logs: logs));
      expect(reply.text, contains('Baca'));
      expect(reply.text, contains('3'));
    });

    test('motivation returns a quote', () {
      final reply = engine.respond('aku butuh semangat', ctx());
      expect(reply.text.length, greaterThan(20));
    });

    test('help lists capabilities', () {
      final reply = engine.respond('bisa apa aja?', ctx());
      expect(reply.text, contains('tugas'));
    });

    test('fallback offers examples', () {
      final reply = engine.respond('xyzzy random text', ctx());
      expect(reply.text, isNotEmpty);
    });
  });

  group('AssistantEngine — dailySuggestion', () {
    test('prioritizes overdue tasks', () {
      final overdue = task('1', 'Late', due: DateTime(2026, 11, 9));
      final text = engine.dailySuggestion(ctx(tasks: [overdue]));
      expect(text, isNotEmpty);
    });

    test('suggests habit check-in when nothing pending', () {
      final habit = Habit(id: 'h1', name: 'Baca', createdAt: DateTime(2026));
      final text = engine.dailySuggestion(ctx(habits: [habit]));
      expect(text, isNotEmpty);
    });
  });

  group('date helpers', () {
    test('dateKey round trip', () {
      final day = DateTime(2026, 3, 5);
      expect(dateKey(day), '2026-03-05');
      expect(DateTime.parse(dateKey(day)).day, 5);
    });
  });
}
