import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/task.dart';
import '../../core/providers/core_providers.dart';
import '../../core/utils/date_time_ext.dart';
import '../../core/widgets/ui.dart';
import '../../l10n/generated/app_localizations.dart';
import '../data/data_providers.dart';
import 'task_filter.dart';
import 'task_form_sheet.dart';

/// Task list with filters, swipe-to-delete with undo, and inline completion.
class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  TaskFilter _filter = TaskFilter.all;

  Future<void> _toggle(Task task) async {
    final repo = ref.read(taskRepositoryProvider);
    if (task.done) {
      await repo.update(task.copyWith(done: false, updatedAt: DateTime.now()));
    } else {
      await repo.update(task.copyWith(done: true, updatedAt: DateTime.now()));
    }
  }

  Future<void> _delete(Task task) async {
    final l10n = context.l10n;
    final repo = ref.read(taskRepositoryProvider);
    await repo.delete(task.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.taskDeleted),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: l10n.commonUndo,
            onPressed: () => repo.add(task),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final tasksAsync = ref.watch(tasksProvider);
    final tasks = tasksAsync.value ?? const <Task>[];
    final visible = filterTasks(tasks, _filter, DateTime.now());

    final labels = {
      TaskFilter.all: l10n.taskFilterAll,
      TaskFilter.today: l10n.taskFilterToday,
      TaskFilter.upcoming: l10n.taskFilterUpcoming,
      TaskFilter.done: l10n.taskFilterDone,
    };
    final counts = {
      for (final f in TaskFilter.values) f: filterTasks(tasks, f, DateTime.now()).length,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tasksTitle),
        backgroundColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showTaskFormSheet(context),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.quickAddTask),
      ),
      body: tasksAsync.isLoading && tasks.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      for (final f in TaskFilter.values)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            selected: _filter == f,
                            label: Text('${labels[f]} · ${counts[f]}'),
                            onSelected: (_) => setState(() => _filter = f),
                            showCheckmark: false,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: visible.isEmpty
                      ? EmptyState(
                          icon: Icons.task_alt_rounded,
                          title: l10n.taskEmptyTitle,
                          body: l10n.taskEmptyBody,
                          actionLabel: l10n.quickAddTask,
                          onAction: () => showTaskFormSheet(context),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                          itemCount: visible.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final task = visible[index];
                            return Entrance(
                              delayMs: index < 8 ? index * 40 : 0,
                              child: Dismissible(
                                key: ValueKey('task-${task.id}'),
                                direction: DismissDirection.endToStart,
                                background: _DeleteBackground(theme: theme),
                                onDismissed: (_) => _delete(task),
                                child: TaskTile(
                                  task: task,
                                  onToggle: () => _toggle(task),
                                  onOpen: () => showTaskFormSheet(context, task: task),
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

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
    );
  }
}

/// A task row used by the tasks list.
class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onOpen,
  });

  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final priorityColors = const [
      Color(0xFF14B8A6),
      Color(0xFFF59E0B),
      Color(0xFFEF476F),
    ];
    final priorityColor = priorityColors[task.priority.index];

    final categoryLabels = {
      'general': l10n.catGeneral,
      'work': l10n.catWork,
      'study': l10n.catStudy,
      'health': l10n.catHealth,
      'personal': l10n.catPersonal,
    };

    final due = task.dueDate;
    final now = DateTime.now();
    final overdue = task.isOverdue(now);

    return NaraCard(
      onTap: onOpen,
      padding: EdgeInsets.zero,
      child: Row(
        children: [
          Container(
            width: 5,
            height: 64,
            decoration: BoxDecoration(
              color: priorityColor.withValues(alpha: task.done ? 0.3 : 1),
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(20),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      decoration:
                          task.done ? TextDecoration.lineThrough : null,
                      color: task.done
                          ? theme.colorScheme.onSurfaceVariant
                          : null,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (due != null) ...[
                        Icon(
                          overdue
                              ? Icons.warning_amber_rounded
                              : Icons.event_rounded,
                          size: 14,
                          color: overdue
                              ? theme.colorScheme.error
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _dueLabel(due, now, l10n, overdue),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: overdue ? theme.colorScheme.error : null,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          categoryLabels[task.category] ?? l10n.catGeneral,
                          style: theme.textTheme.labelSmall,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _CheckCircle(
              done: task.done,
              color: priorityColor,
              onToggle: onToggle,
            ),
          ),
        ],
      ),
    );
  }

  String _dueLabel(DateTime due, DateTime now, AppLocalizations l10n, bool overdue) {
    final day = due.dayStart;
    String dayPart;
    if (day.isSameDay(now)) {
      dayPart = l10n.commonToday;
    } else if (day.isSameDay(now.addDays(1))) {
      dayPart = l10n.commonTomorrow;
    } else if (day.isSameDay(now.addDays(-1))) {
      dayPart = l10n.commonYesterday;
    } else {
      const idMonths = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
      const enMonths = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final months = l10n.localeName.startsWith('id') ? idMonths : enMonths;
      dayPart = '${due.day} ${months[due.month]}';
    }
    if (due.hour == 0 && due.minute == 0) return dayPart;
    final hh = due.hour.toString().padLeft(2, '0');
    final mm = due.minute.toString().padLeft(2, '0');
    return '$dayPart · $hh:$mm';
  }
}

class _CheckCircle extends StatelessWidget {
  const _CheckCircle({
    required this.done,
    required this.color,
    required this.onToggle,
  });

  final bool done;
  final Color color;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: done ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: done ? color : color.withValues(alpha: 0.6), width: 2),
        ),
        child: done
            ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
            : const SizedBox(),
      ),
    );
  }
}
