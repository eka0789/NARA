import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/models/habit.dart';
import '../../core/providers/core_providers.dart';
import '../../core/theme/nara_theme.dart';
import '../../core/widgets/ui.dart';

const _uuid = Uuid();

const _emojiChoices = [
  '💧', '🏃', '📖', '🧘', '💪', '🌱', '☀️', '🌙', '🥗', '✍️', '🎯', '🧠',
];

/// Create/edit habit bottom sheet: name, emoji, color, weekly target.
Future<void> showHabitFormSheet(BuildContext context, {Habit? habit}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
      child: HabitFormSheet(habit: habit),
    ),
  );
}

class HabitFormSheet extends ConsumerStatefulWidget {
  const HabitFormSheet({super.key, this.habit});

  final Habit? habit;

  @override
  ConsumerState<HabitFormSheet> createState() => _HabitFormSheetState();
}

class _HabitFormSheetState extends ConsumerState<HabitFormSheet> {
  late final TextEditingController _name;
  late String _emoji;
  late int _colorIndex;
  late int _targetPerWeek;

  bool get _editing => widget.habit != null;

  @override
  void initState() {
    super.initState();
    final habit = widget.habit;
    _name = TextEditingController(text: habit?.name ?? '');
    _emoji = habit?.emoji ?? _emojiChoices.first;
    _colorIndex = habit?.colorIndex ?? 0;
    _targetPerWeek = habit?.targetPerWeek ?? 7;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final name = _name.text.trim();
    if (name.isEmpty) {
      showNaraSnack(context, l10n.habitNameLabel, error: true);
      return;
    }
    final repo = ref.read(habitRepositoryProvider);
    try {
      if (_editing) {
        await repo.update(
          widget.habit!.copyWith(
            name: name,
            emoji: _emoji,
            colorIndex: _colorIndex,
            targetPerWeek: _targetPerWeek,
          ),
        );
      } else {
        await repo.add(
          Habit(
            id: _uuid.v4(),
            name: name,
            emoji: _emoji,
            colorIndex: _colorIndex,
            targetPerWeek: _targetPerWeek,
            createdAt: DateTime.now(),
          ),
        );
      }
    } on Exception catch (_) {
      // Keep the sheet open so the user's input is not lost.
      if (mounted) showNaraSnack(context, l10n.commonErrorGeneric, error: true);
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _editing ? l10n.commonEdit : l10n.habitsTitle,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: NaraPalette.habitColors[_colorIndex %
                        NaraPalette.habitColors.length]
                        .withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: Text(_emoji, style: const TextStyle(fontSize: 26)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _name,
                    autofocus: !_editing,
                    textCapitalization: TextCapitalization.sentences,
                    decoration:
                        InputDecoration(hintText: l10n.habitNameLabel),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(l10n.habitEmojiLabel, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final emoji in _emojiChoices)
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() => _emoji = emoji),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: _emoji == emoji
                            ? theme.colorScheme.primary.withValues(alpha: 0.14)
                            : theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: _emoji == emoji
                            ? Border.all(
                                color: theme.colorScheme.primary, width: 1.6)
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(emoji, style: const TextStyle(fontSize: 20)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(l10n.habitTargetLabel, style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _targetPerWeek.toDouble(),
                    min: 1,
                    max: 7,
                    divisions: 6,
                    label: l10n.habitTimesPerWeek(_targetPerWeek),
                    onChanged: (value) =>
                        setState(() => _targetPerWeek = value.round()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GradientButton(
              label: l10n.commonSave,
              icon: Icons.save_rounded,
              onPressed: _save,
            ),
            if (_editing) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () async {
                  final repo = ref.read(habitRepositoryProvider);
                  Navigator.of(context).pop();
                  await repo.delete(widget.habit!.id);
                },
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: theme.colorScheme.error,
                ),
                label: Text(
                  l10n.commonDelete,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
