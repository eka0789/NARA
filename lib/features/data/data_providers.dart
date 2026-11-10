import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/habit.dart';
import '../../core/models/note.dart';
import '../../core/models/task.dart';
import '../../core/providers/core_providers.dart';

/// Reactive data streams shared across features (dashboard, lists, chat AI).
final tasksProvider =
    StreamProvider<List<Task>>((ref) => ref.watch(taskRepositoryProvider).watchAll());

final notesProvider =
    StreamProvider<List<Note>>((ref) => ref.watch(noteRepositoryProvider).watchAll());

final habitsProvider =
    StreamProvider<List<Habit>>((ref) => ref.watch(habitRepositoryProvider).watchAll());

final habitLogsProvider = StreamProvider<Map<String, Set<String>>>(
    (ref) => ref.watch(habitRepositoryProvider).watchLogs());
