import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/note.dart';
import '../../core/providers/core_providers.dart';
import '../../core/theme/nara_theme.dart';
import '../../core/utils/date_time_ext.dart';
import '../../core/widgets/ui.dart';
import '../data/data_providers.dart';
import 'note_format.dart';

/// Notion-style page browser: hierarchical pages (sub-pages), tag filters,
/// search, pinned-first ordering, and swipe-free card actions.
class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  String _query = '';
  String? _folderId; // null = top level
  String? _tagFilter; // null = all tags

  void _enterFolder(String noteId) => setState(() {
        _folderId = noteId;
        _query = '';
        _tagFilter = null;
      });

  void _exitFolder() => setState(() {
        _folderId = null;
        _query = '';
        _tagFilter = null;
      });

  List<Note> _childrenOf(List<Note> notes, String? parentId) =>
      notes.where((n) => n.parentId == parentId).toList();

  int _childCount(List<Note> notes, String noteId) =>
      notes.where((n) => n.parentId == noteId).length;

  /// All ids in the subtree rooted at [noteId] (excluding the root itself) —
  /// used by cascade delete so sub-pages never orphan.
  List<String> _descendantIds(List<Note> notes, String noteId) {
    final ids = <String>[];
    for (final child in _childrenOf(notes, noteId)) {
      ids
        ..add(child.id)
        ..addAll(_descendantIds(notes, child.id));
    }
    return ids;
  }

  Future<void> _delete(Note note) async {
    final l10n = context.l10n;
    final notes = ref.read(notesProvider).value ?? const <Note>[];
    final children = _descendantIds(notes, note.id);
    final repo = ref.read(noteRepositoryProvider);

    if (children.isNotEmpty) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.deleteNestedTitle),
          content: Text(l10n.deleteNestedBody(children.length)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).colorScheme.error,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.commonDelete),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    await repo.delete(note.id);
    for (final id in children) {
      await repo.delete(id);
    }
    // Deleted the folder we are currently browsing → go back to root.
    if (note.id == _folderId) _exitFolder();

    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            children.isEmpty
                ? l10n.noteDeleted
                : '${l10n.noteDeleted} (+${children.length})',
          ),
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
    final allNotes = notesAsync.value ?? const <Note>[];

    final folder = _folderId == null
        ? null
        : allNotes.where((n) => n.id == _folderId).firstOrNull;
    final visibleBase = _childrenOf(allNotes, _folderId);

    final tagUniverse = <String>{
      for (final note in allNotes) ...note.tags,
    }.toList()
      ..sort();

    final filtered = [
      for (final note in visibleBase)
        if ((_query.isEmpty || note.matches(_query)) &&
            (_tagFilter == null || note.tags.contains(_tagFilter)))
          note,
    ]..sort((a, b) {
        if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });

    return Scaffold(
      appBar: AppBar(
        leading: _folderId == null
            ? null
            : BackButton(onPressed: _exitFolder),
        title: Text(
          folder == null
              ? l10n.notesTitle
              : (folder.title.isEmpty ? l10n.noteUntitled : folder.title),
        ),
        backgroundColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go(
          _folderId == null ? '/notes/new' : '/notes/new?parent=$_folderId',
        ),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.quickAddNote),
      ),
      body: notesAsync.isLoading && allNotes.isEmpty
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
                if (tagUniverse.isNotEmpty)
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            selected: _tagFilter == null,
                            label: Text(l10n.taskFilterAll),
                            showCheckmark: false,
                            onSelected: (_) =>
                                setState(() => _tagFilter = null),
                          ),
                        ),
                        for (final tag in tagUniverse)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              selected: _tagFilter == tag,
                              label: Text('#$tag'),
                              showCheckmark: false,
                              onSelected: (_) =>
                                  setState(() => _tagFilter = tag),
                            ),
                          ),
                      ],
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
                                childCount:
                                    _childCount(allNotes, note.id),
                                onOpen: () =>
                                    context.go('/notes/${note.id}'),
                                onOpenFolder: () => _enterFolder(note.id),
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
    required this.childCount,
    required this.onOpen,
    required this.onOpenFolder,
    required this.onDelete,
    required this.onPin,
  });

  final Note note;
  final int childCount;
  final VoidCallback onOpen;
  final VoidCallback onOpenFolder;
  final VoidCallback onDelete;
  final VoidCallback onPin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;
    final palette = isDark ? NaraPalette.noteDeep : NaraPalette.notePastel;
    final color = palette[note.colorIndex.clamp(0, palette.length - 1)];
    final (checkDone, checkTotal) = checklistProgress(note.body);
    final visibleTags = note.tags.take(2).toList();
    final extraTags = note.tags.length - visibleTags.length;

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
                  note.pinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                  size: 17,
                  color: note.pinned
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (checkTotal > 0) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  checkDone == checkTotal
                      ? Icons.check_circle_rounded
                      : Icons.check_circle_outline_rounded,
                  size: 14,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  '$checkDone/$checkTotal',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
          Expanded(
            child: Text(
              bodyPreview(note.body),
              style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
              overflow: TextOverflow.fade,
            ),
          ),
          if (visibleTags.isNotEmpty) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              children: [
                for (final tag in visibleTags)
                  Text(
                    '#$tag',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                if (extraTags > 0)
                  Text(
                    '+$extraTags',
                    style: theme.textTheme.labelSmall,
                  ),
              ],
            ),
          ],
          Row(
            children: [
              Text(
                _dateLabel(context, note.updatedAt),
                style: theme.textTheme.labelSmall,
              ),
              const Spacer(),
              if (childCount > 0)
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: onOpenFolder,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.subdirectory_arrow_right_rounded,
                          size: 15,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        Text(
                          '$childCount',
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(width: 6),
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

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
