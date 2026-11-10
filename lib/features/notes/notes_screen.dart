import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/note.dart';
import '../../core/providers/core_providers.dart';
import '../../core/theme/nara_theme.dart';
import '../../core/utils/date_time_ext.dart';
import '../../core/widgets/ui.dart';
import '../data/data_providers.dart';

/// Searchable two-column note grid with pinned-first ordering.
class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  String _query = '';

  Future<void> _delete(Note note) async {
    final l10n = context.l10n;
    final repo = ref.read(noteRepositoryProvider);
    await repo.delete(note.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.noteDeleted),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: l10n.commonUndo,
            onPressed: () => repo.add(note),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final notesAsync = ref.watch(notesProvider);
    final notes = notesAsync.value ?? const <Note>[];

    final filtered = [
      for (final note in notes)
        if (_query.isEmpty || note.matches(_query)) note,
    ]..sort((a, b) {
        if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notesTitle),
        backgroundColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/notes/new'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.quickAddNote),
      ),
      body: notesAsync.isLoading && notes.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: TextField(
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      hintText: l10n.notesSearchHint,
                      prefixIcon: const Icon(Icons.search_rounded),
                    ),
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? EmptyState(
                          icon: Icons.sticky_note_2_rounded,
                          title: l10n.noteEmptyTitle,
                          body: l10n.noteEmptyBody,
                          actionLabel: l10n.quickAddNote,
                          onAction: () => context.go('/notes/new'),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.86,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final note = filtered[index];
                            return Entrance(
                              delayMs: index < 8 ? index * 40 : 0,
                              child: _NoteCard(
                                note: note,
                                onOpen: () => context.go('/notes/${note.id}'),
                                onDelete: () => _delete(note),
                                onPin: () => ref
                                    .read(noteRepositoryProvider)
                                    .update(
                                      note.copyWith(
                                        pinned: !note.pinned,
                                        updatedAt: DateTime.now(),
                                      ),
                                    ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.note,
    required this.onOpen,
    required this.onDelete,
    required this.onPin,
  });

  final Note note;
  final VoidCallback onOpen;
  final VoidCallback onDelete;
  final VoidCallback onPin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;
    final palette = isDark ? NaraPalette.noteDeep : NaraPalette.notePastel;
    final color = palette[note.colorIndex.clamp(0, palette.length - 1)];

    return NaraCard(
      onTap: onOpen,
      color: color,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  note.title.isEmpty ? l10n.noteUntitled : note.title,
                  style: theme.textTheme.titleSmall?.copyWith(height: 1.25),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: onPin,
                child: Icon(
                  note.pinned
                      ? Icons.push_pin_rounded
                      : Icons.push_pin_outlined,
                  size: 17,
                  color: note.pinned
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              note.body,
              style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
              overflow: TextOverflow.fade,
            ),
          ),
          Row(
            children: [
              Text(
                _dateLabel(context, note.updatedAt),
                style: theme.textTheme.labelSmall,
              ),
              const Spacer(),
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: onDelete,
                child: Icon(
                  Icons.delete_outline_rounded,
                  size: 17,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _dateLabel(BuildContext context, DateTime date) {
    final now = DateTime.now();
    if (date.isSameDay(now)) return context.l10n.commonToday;
    return '${date.day}/${date.month}';
  }
}
