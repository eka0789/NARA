import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/models/note.dart';
import '../../core/providers/core_providers.dart';
import '../../core/theme/nara_theme.dart';
import '../../core/widgets/ui.dart';
import '../data/data_providers.dart';
import 'note_repository.dart';
import 'note_templates.dart';

const _uuid = Uuid();

/// Full-screen page editor; `noteId == 'new'` or null creates a page,
/// optionally under a parent (`parentId`) and starting from a template —
/// the Notion-style "new page" flow.
class NoteEditorScreen extends ConsumerStatefulWidget {
  const NoteEditorScreen({super.key, this.noteId, this.parentId});

  final String? noteId;

  /// When creating a new page: the parent page's id (sub-page).
  final String? parentId;

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late final TextEditingController _title;
  late final TextEditingController _body;
  // Captured once (reading `ref` is illegal after dispose): the editor's
  // autosave runs from `dispose`, where `ref.read` would throw.
  late final NoteRepository _repo;
  late int _colorIndex;
  late List<String> _tags;
  bool _pinned = false;
  Note? _existing;
  bool _loaded = false;
  bool _saved = false;
  bool _templateAsked = false;

  @override
  void initState() {
    super.initState();
    _repo = ref.read(noteRepositoryProvider);
    final id = widget.noteId;
    if (id == null || id == 'new') {
      _title = TextEditingController();
      _body = TextEditingController();
      _colorIndex = DateTime.now().millisecondsSinceEpoch % NaraPalette.notePastel.length;
      _tags = const [];
      // Notion-style: offer a template the first time a new page opens.
      WidgetsBinding.instance.addPostFrameCallback((_) => _askTemplate());
    } else {
      // Controllers get filled in build once notesProvider has emitted;
      // until then _loaded stays false so an existing note never opens
      // blank (which would make autosave create a duplicate).
      _title = TextEditingController();
      _body = TextEditingController();
      _colorIndex = 0;
      _tags = const [];
    }
    // Any text change (user typing OR programmatic fill) ends the wait, so a
    // late stream emission can never clobber what is on screen.
    _title.addListener(_stopWaiting);
    _body.addListener(_stopWaiting);
  }

  void _stopWaiting() => _loaded = true;

  void _askTemplate() {
    if (_templateAsked || !mounted) return;
    _templateAsked = true;
    final l10n = context.l10n;
    final templates = noteTemplates(l10n, DateTime.now());
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.templatePickTitle,
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              for (final template in templates)
                ListTile(
                  leading: Icon(
                    switch (template.id) {
                      'journal' => Icons.wb_sunny_outlined,
                      'meeting' => Icons.groups_outlined,
                      'project' => Icons.flag_outlined,
                      _ => Icons.edit_note_rounded,
                    },
                    color: Theme.of(sheetContext).colorScheme.primary,
                  ),
                  title: Text(template.title),
                  dense: true,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _title.text = template.title;
                    _body.text = template.body;
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _loadExisting(AsyncValue<List<Note>> notesAsync) {
    if (_loaded || widget.noteId == null || widget.noteId == 'new') {
      _loaded = true;
      return;
    }
    final notes = notesAsync.value;
    if (notes == null) return; // wait for the first emission
    final note = notes.where((n) => n.id == widget.noteId).firstOrNull;
    if (note != null) {
      _existing = note;
      _title.text = note.title;
      _body.text = note.body;
      _colorIndex = note.colorIndex;
      _pinned = note.pinned;
      _tags = List.of(note.tags);
    }
    _loaded = true;
  }

  @override
  void dispose() {
    // Autosave on exit so users never lose a thought.
    if (!_saved) {
      _save();
    }
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<bool> _save() async {
    final title = _title.text.trim();
    final body = _body.text.trim();
    if (title.isEmpty && body.isEmpty && _tags.isEmpty) {
      return false; // nothing worth saving
    }
    final repo = _repo;
    final now = DateTime.now();
    if (_existing != null) {
      await repo.update(
        _existing!.copyWith(
          title: title,
          body: body,
          colorIndex: _colorIndex,
          pinned: _pinned,
          tags: _tags,
          updatedAt: now,
        ),
      );
    } else {
      _existing = Note(
        id: _uuid.v4(),
        title: title,
        body: body,
        colorIndex: _colorIndex,
        pinned: _pinned,
        parentId: widget.parentId,
        tags: _tags,
        createdAt: now,
        updatedAt: now,
      );
      await repo.add(_existing!);
    }
    _saved = true;
    return true;
  }

  Future<void> _addTags() async {
    final controller = TextEditingController(text: _tags.join(', '));
    final confirmed = await showDialog<List<String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.noteTagAdd),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: context.l10n.noteTagHint),
          onSubmitted: (value) =>
              Navigator.pop(dialogContext, _parseTags(value)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, _parseTags(controller.text)),
            child: Text(context.l10n.commonSave),
          ),
        ],
      ),
    );
    if (confirmed == null || !mounted) return;
    setState(() => _tags = confirmed);
  }

  static List<String> _parseTags(String raw) {
    final tags = <String>[];
    for (final part in raw.split(',')) {
      final tag = part.trim();
      if (tag.isEmpty) continue;
      if (!tags.any((t) => t.toLowerCase() == tag.toLowerCase())) {
        tags.add(tag);
      }
    }
    return tags;
  }

  @override
  Widget build(BuildContext context) {
    // Watch (not read) so the load re-runs when the stream emits.
    final notesAsync = ref.watch(notesProvider);
    _loadExisting(notesAsync);
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final palette = isDark ? NaraPalette.noteDeep : NaraPalette.notePastel;
    final parent = widget.parentId == null
        ? null
        : (notesAsync.value ?? const <Note>[])
            .where((n) => n.id == widget.parentId)
            .firstOrNull;
    final canAddSubPage =
        widget.noteId != null && widget.noteId != 'new';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _save();
        if (!context.mounted) return;
        context.go('/notes');
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.notesTitle),
          actions: [
            if (canAddSubPage)
              IconButton(
                tooltip: l10n.subPageNew,
                onPressed: () => context.push(
                  '/notes/new?parent=${widget.noteId}',
                ),
                icon: const Icon(Icons.subdirectory_arrow_right_rounded),
              ),
            IconButton(
              tooltip: l10n.commonSave,
              onPressed: () async {
                final ok = await _save();
                if (!context.mounted) return;
                if (ok) showNaraSnack(context, l10n.noteUpdated);
                context.go('/notes');
              },
              icon: const Icon(Icons.check_rounded),
            ),
          ],
        ),
        body: Column(
          children: [
            if (parent != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: Row(
                  children: [
                    Icon(
                      Icons.subdirectory_arrow_right_rounded,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        parent.title.isEmpty ? l10n.noteUntitled : parent.title,
                        style: theme.textTheme.labelSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  for (var i = 0; i < palette.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(99),
                        onTap: () => setState(() => _colorIndex = i),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: palette[i],
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _colorIndex == i
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outlineVariant,
                              width: _colorIndex == i ? 2.5 : 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 4),
                  ActionChip(
                    avatar: Icon(
                      _pinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                      size: 16,
                    ),
                    label: Text(_pinned ? l10n.notePinned : l10n.commonEdit),
                    onPressed: () => setState(() => _pinned = !_pinned),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  children: [
                    TextField(
                      controller: _title,
                      textCapitalization: TextCapitalization.sentences,
                      style: theme.textTheme.titleLarge,
                      decoration: InputDecoration(
                        hintText: l10n.noteTitleLabel,
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                    TagRow(
                      tags: _tags,
                      onRemoved: (tag) =>
                          setState(() => _tags = [..._tags]..remove(tag)),
                      onAdd: _addTags,
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: TextField(
                        controller: _body,
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        style: theme.textTheme.bodyLarge,
                        decoration: InputDecoration(
                          hintText: l10n.noteBodyLabel,
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Editable tag chips + an "add tag" affordance, shared by the page editor.
class TagRow extends StatelessWidget {
  const TagRow({
    super.key,
    required this.tags,
    required this.onRemoved,
    required this.onAdd,
  });

  final List<String> tags;
  final void Function(String tag) onRemoved;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final tag in tags)
            InputChip(
              label: Text('#$tag', style: theme.textTheme.labelSmall),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onDeleted: () => onRemoved(tag),
            ),
          ActionChip(
            avatar: const Icon(Icons.sell_outlined, size: 15),
            label: Text(
              l10n.noteTagAdd,
              style: theme.textTheme.labelSmall,
            ),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
