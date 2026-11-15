import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nara/core/models/habit.dart';
import 'package:nara/core/models/note.dart';
import 'package:nara/core/models/task.dart';
import 'package:nara/core/models/user_profile.dart';
import 'package:nara/features/profile/data_export.dart';

void main() {
  test('export covers every entity with readable field names', () {
    final now = DateTime(2026, 11, 15, 10);
    final json = buildExportJson(
      profile: UserProfile(uid: 'u1', name: 'Eka', email: 'eka@example.com'),
      tasks: [
        Task(
          id: 't1',
          title: 'Belanja',
          done: true,
          priority: TaskPriority.high,
          category: 'personal',
          dueDate: now,
          createdAt: now,
          updatedAt: now,
        ),
      ],
      notes: [
        Note(id: 'n1', title: 'Ide', body: 'kue pandan', pinned: true, createdAt: now, updatedAt: now),
      ],
      habits: [Habit(id: 'h1', name: 'Baca', emoji: '📖', createdAt: now)],
      habitLogs: {
        'h1': {'2026-11-15', '2026-11-14'},
        'ghost': {'2026-11-13'}, // habit deleted — must not appear
      },
    );

    final data = jsonDecode(json) as Map<String, dynamic>;
    expect(data['app'], 'NARA');
    expect((data['profile'] as Map)['name'], 'Eka');
    expect((data['tasks'] as List).length, 1);
    expect(((data['tasks'] as List).first as Map)['priority'], 'high');
    expect((data['notes'] as List).length, 1);
    expect((data['habits'] as List).length, 1);
    final logs = ((data['habits'] as List).first as Map)['logs'] as List;
    expect(logs, ['2026-11-14', '2026-11-15']); // sorted, ghost dropped
  });

  test('null profile and empty data produce valid empty export', () {
    final json = buildExportJson(
      tasks: const [],
      notes: const [],
      habits: const [],
      habitLogs: const {},
    );
    final data = jsonDecode(json) as Map<String, dynamic>;
    expect(data['profile'], isNull);
    expect(data['tasks'], isEmpty);
    expect(json, contains('"app": "NARA"'));
  });
}
