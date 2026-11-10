import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/models/note.dart';
import '../../core/providers/core_providers.dart';
import '../../core/theme/nara_theme.dart';
import '../../core/widgets/ui.dart';
import '../data/data_providers.dart';

const _uuid = Uuid();

/// Full-screen note editor; `noteId == 'new'` or null creates a note.
class NoteEditorScreen extends ConsumerStatefulWidget {
  const NoteEditorScreen({super.key, this.noteId});

  final String? noteId;

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late final TextEditingController _title;
  late final TextEditingController _body;
  late int _colorIndex;
  bool _pinned = false;
  Note? _existing;
  bool _loaded = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    final id = widget.noteId;
    if (id == null || id == 'new') {
      _title = TextEditingController();
      _body = TextEditingController();
      _colorIndex = DateTime.now().millisecondsSinceEpoch % NaraPalette.notePastel.length;
    } else {
      // Controllers get filled in build once notesProvider has emitted;
      // until then _loaded stays false so an existing note never opens
      // blank (which would make autosave create a duplicate).
      _title = TextEditingController();
      _body = TextEditingController();
      _colorIndex = 0;
    }
    // Any text change (user typing OR programmatic fill) ends the wait, so a
    // late stream emission can never clobber what is on screen.
    _title.addListener(_stopWaiting);
    _body.addListener(_stopWaiting);
  }

  void _stopWaiting() => _loaded = true;

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
    if (title.isEmpty && body.isEmpty) {
      return false; // nothing worth saving
    }
    final repo = ref.read(noteRepositoryProvider);
    final now = DateTime.now();
    if (_existing != null) {
      await repo.update(
        _existing!.copyWith(
          title: title,
          body: body,
          colorIndex: _colorIndex,
          pinned: _pinned,
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
        createdAt: now,
        updatedAt: now,
      );
      await repo.add(_existing!);
    }
    _saved = true;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    // Watch (not read) so the load re-runs when the stream emits.
    _loadExisting(ref.watch(notesProvider));
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final palette = isDark ? NaraPalette.noteDeep : NaraPalette.notePastel;

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

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
