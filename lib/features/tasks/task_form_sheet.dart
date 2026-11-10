import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/models/task.dart';
import '../../core/providers/core_providers.dart';
import '../../core/utils/date_time_ext.dart';
import '../../core/widgets/ui.dart';

const _uuid = Uuid();

const _categories = ['general', 'work', 'study', 'health', 'personal'];

/// Create/edit task bottom sheet with validation, priority, category, and
/// due-date shortcuts.
Future<void> showTaskFormSheet(BuildContext context, {Task? task}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
      child: TaskFormSheet(task: task),
    ),
  );
}

class TaskFormSheet extends ConsumerStatefulWidget {
  const TaskFormSheet({super.key, this.task});

  final Task? task;

  @override
  ConsumerState<TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends ConsumerState<TaskFormSheet> {
  late final TextEditingController _title;
  late final TextEditingController _note;
  late TaskPriority _priority;
  late String _category;
  DateTime? _due;

  bool get _editing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _title = TextEditingController(text: task?.title ?? '');
    _note = TextEditingController(text: task?.note ?? '');
    _priority = task?.priority ?? TaskPriority.medium;
    _category = task?.category ?? 'general';
    _due = task?.dueDate;
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickCustomDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _due ?? DateTime.now(),
      firstDate: DateTime.now().addDays(-1),
      lastDate: DateTime.now().addDays(365 * 2),
    );
    if (picked != null) {
      setState(() => _due = picked.dayStart);
    }
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final title = _title.text.trim();
    if (title.isEmpty) {
      showNaraSnack(context, l10n.taskTitleLabel, error: true);
      return;
    }
    final repo = ref.read(taskRepositoryProvider);
    final now = DateTime.now();
    try {
      if (_editing) {
        await repo.update(
          widget.task!.copyWith(
            title: title,
            note: _note.text.trim(),
            priority: _priority,
            category: _category,
            dueDate: _due,
            updatedAt: now,
          ),
        );
      } else {
        await repo.add(Task(
          id: _uuid.v4(),
          title: title,
          note: _note.text.trim(),
          priority: _priority,
          category: _category,
          dueDate: _due,
          createdAt: now,
          updatedAt: now,
        ));
      }
    } on Exception catch (_) {
      // Keep the sheet open so the user's input is not lost.
      if (mounted) showNaraSnack(context, l10n.commonErrorGeneric, error: true);
      return;
    }
    if (mounted) {
      showNaraSnack(context, _editing ? l10n.taskUpdated : l10n.taskAdded);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    final categoryLabels = {
      'general': l10n.catGeneral,
      'work': l10n.catWork,
      'study': l10n.catStudy,
      'health': l10n.catHealth,
      'personal': l10n.catPersonal,
    };

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _editing ? l10n.commonEdit : l10n.quickAddTask,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _title,
              autofocus: !_editing,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 1,
              decoration: InputDecoration(hintText: l10n.taskTitleLabel),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(hintText: l10n.taskNoteLabel),
            ),
            const SizedBox(height: 16),
            Text(l10n.taskPriorityLabel, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<TaskPriority>(
              segments: [
                ButtonSegment(
                  value: TaskPriority.low,
                  label: Text(l10n.priorityLow),
                ),
                ButtonSegment(
                  value: TaskPriority.medium,
                  label: Text(l10n.priorityMedium),
                ),
                ButtonSegment(
                  value: TaskPriority.high,
                  label: Text(l10n.priorityHigh),
                ),
              ],
              selected: {_priority},
              onSelectionChanged: (selection) =>
                  setState(() => _priority = selection.first),
            ),
            const SizedBox(height: 16),
            Text(l10n.taskCategoryLabel, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final category in _categories)
                  ChoiceChip(
                    label: Text(categoryLabels[category] ?? category),
                    selected: _category == category,
                    onSelected: (_) => setState(() => _category = category),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(l10n.taskDueLabel, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: Icon(
                    _due == null ? Icons.check_rounded : Icons.block_rounded,
                    size: 16,
                  ),
                  label: Text(l10n.taskNoDue),
                  onPressed: () => setState(() => _due = null),
                ),
                ActionChip(
                  label: Text(l10n.commonToday),
                  onPressed: () =>
                      setState(() => _due = DateTime.now().dayStart),
                ),
                ActionChip(
                  label: Text(l10n.commonTomorrow),
                  onPressed: () =>
                      setState(() => _due = DateTime.now().addDays(1).dayStart),
                ),
                ActionChip(
                  avatar: const Icon(Icons.edit_calendar_rounded, size: 16),
                  label: Text(
                    _due == null
                        ? l10n.datePickerNoDate
                        : '${_due!.day}/${_due!.month}',
                  ),
                  onPressed: _pickCustomDate,
                ),
              ],
            ),
            const SizedBox(height: 24),
            GradientButton(
              label: l10n.commonSave,
              icon: _editing ? Icons.save_rounded : Icons.add_rounded,
              onPressed: _save,
            ),
            if (_editing) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () async {
                  final repo = ref.read(taskRepositoryProvider);
                  Navigator.of(context).pop();
                  await repo.delete(widget.task!.id);
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
