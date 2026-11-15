import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/ui.dart';
import '../data/data_providers.dart';
import '../notes/note_format.dart';
import 'quick_find.dart';

/// Notion-style ⌘K: one overlay to find any task, page or habit and jump
/// straight to it. Reads the live provider streams, so results always match
/// what the rest of the app shows.
class QuickFindDelegate extends SearchDelegate<SearchHit?> {
  QuickFindDelegate(this.ref);

  final WidgetRef ref;

  List<SearchHit> _hits(String query) => quickFind(
        query: query,
        tasks: ref.read(tasksProvider).value ?? const [],
        notes: ref.read(notesProvider).value ?? const [],
        habits: ref.read(habitsProvider).value ?? const [],
      );

  @override
  List<Widget>? buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => query = '',
          ),
      ];

  @override
  Widget? buildLeading(BuildContext context) =>
      BackButton(onPressed: () => close(context, null));

  @override
  Widget buildResults(BuildContext context) => _list(context);

  @override
  Widget buildSuggestions(BuildContext context) => _list(context);

  Widget _list(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final hits = _hits(query);

    if (hits.isEmpty) {
      final q = query.trim();
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            q.isEmpty ? '' : l10n.searchNoResults(q),
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    String groupName(SearchHit hit) => switch (hit) {
          TaskHit() => l10n.navTasks,
          NoteHit() => l10n.notesTitle,
          HabitHit() => l10n.habitsTitle,
        };

    final tiles = <Widget>[];
    String? lastGroup;
    for (final hit in hits) {
      final group = groupName(hit);
      if (group != lastGroup) {
        tiles.add(Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
          child: Text(
            group,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ));
        lastGroup = group;
      }
      tiles.add(_hitTile(context, hit));
    }

    return ListView(children: tiles);
  }

  Widget _hitTile(BuildContext context, SearchHit hit) {
    final theme = Theme.of(context);
    final (icon, title, subtitle) = switch (hit) {
      TaskHit(:final task) => (
          Icons.check_circle_outline_rounded,
          task.title.isEmpty ? '…' : task.title,
          task.dueDate != null
              ? '${task.dueDate!.day}/${task.dueDate!.month}'
              : null,
        ),
      NoteHit(:final note) => (
          Icons.sticky_note_2_outlined,
          note.title.isEmpty ? context.l10n.noteUntitled : note.title,
          bodyPreview(note.body, maxLength: 60),
        ),
      HabitHit(:final habit) => (
          Icons.local_fire_department_outlined,
          habit.name,
          context.l10n.habitTimesPerWeek(habit.targetPerWeek),
        ),
    };
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: subtitle == null
          ? null
          : Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: () => close(context, hit),
    );
  }
}

/// Opens Quick Find and routes to the picked result.
Future<void> showQuickFind(BuildContext context, WidgetRef ref) async {
  final hit = await showSearch<SearchHit?>(
    context: context,
    delegate: QuickFindDelegate(ref),
  );
  if (hit == null || !context.mounted) return;
  switch (hit) {
    case TaskHit():
      context.go('/tasks');
    case NoteHit(:final note):
      context.go('/notes/${note.id}');
    case HabitHit():
      context.go('/habits');
  }
}
