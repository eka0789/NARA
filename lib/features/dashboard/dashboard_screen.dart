import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/ai/assistant_context.dart';
import '../../core/models/habit.dart';
import '../../core/models/note.dart';
import '../../core/models/task.dart';
import '../../core/providers/core_providers.dart';
import '../../core/utils/date_time_ext.dart';
import '../../core/widgets/ui.dart';
import '../../l10n/generated/app_localizations.dart';
import '../chat/chat_providers.dart';
import '../data/data_providers.dart';
import '../habits/habit_streak.dart';
import '../tasks/task_form_sheet.dart';

/// Home: greeting, AI suggestion, stats, quick actions, today's tasks,
/// habit check-ins.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _greeting(AppLocalizations l10n, DateTime now) {
    if (now.hour < 11) return l10n.greetingMorning;
    if (now.hour < 15) return l10n.greetingAfternoon;
    if (now.hour < 19) return l10n.greetingEvening;
    return l10n.greetingNight;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final now = DateTime.now();
    final profile = ref.watch(profileProvider).value;
    final tasks = ref.watch(tasksProvider).value ?? const <Task>[];
    final notes = ref.watch(notesProvider).value ?? const <Note>[];
    final habits = ref.watch(habitsProvider).value ?? const <Habit>[];
    final logs = ref.watch(habitLogsProvider).value ?? const <String, Set<String>>{};

    final todayKey = dateKey(now);
    final tasksToday =
        tasks.where((t) => !t.done && t.dueDate != null && t.dueDate!.isSameDay(now)).length;
    final habitsDone = habits
        .where((h) => (logs[h.id] ?? const <String>{}).contains(todayKey))
        .length;
    final bestStreakValue = habits.isEmpty
        ? 0
        : habits
            .map((h) => bestStreak(logs[h.id] ?? const {}, now))
            .fold<int>(0, (a, b) => a > b ? a : b);

    final assistantContext = AssistantContext(
      langCode: Localizations.localeOf(context).languageCode,
      now: now,
      name: profile?.name ?? '',
      tasks: tasks,
      // Without habits + logs the dashboard suggestion could never use its
      // habit branches (dead feature).
      habits: habits,
      habitLogs: logs,
    );
    final suggestion = ref.watch(assistantEngineProvider).dailySuggestion(assistantContext);

    final dueToday = tasks
        .where((t) => !t.done && t.dueDate != null && t.dueDate!.isSameDay(now))
        .toList()
      ..sort((a, b) => b.priority.index.compareTo(a.priority.index));

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_greeting(l10n, now)}${(profile?.name.isNotEmpty ?? false) ? ',' : ''}',
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        profile?.name.isNotEmpty == true ? profile!.name : 'NARA',
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(l10n, now),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => context.go('/profile'),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: NaraGradients.softBlob(theme),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      profile?.avatarEmoji ?? '🙂',
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // AI suggestion
            Entrance(
              child: NaraCard(
                padding: EdgeInsets.zero,
                onTap: () => context.go('/chat'),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.primary.withValues(alpha: 0.10),
                        theme.colorScheme.tertiary.withValues(alpha: 0.08),
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: NaraGradients.brand,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.auto_awesome,
                            color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.suggestionTitle,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              suggestion,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          color: theme.colorScheme.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Stats
            Entrance(
              delayMs: 60,
              child: Row(
                children: [
                  Expanded(
                    child: StatTile(
                      icon: Icons.checklist_rounded,
                      value: '$tasksToday',
                      label: l10n.dashTasksToday,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatTile(
                      icon: Icons.local_fire_department_rounded,
                      value: '$habitsDone',
                      label: l10n.dashHabitsToday,
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatTile(
                      icon: Icons.emoji_events_rounded,
                      value: '$bestStreakValue',
                      label: l10n.dashBestStreak,
                      color: const Color(0xFFEF476F),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatTile(
                      icon: Icons.sticky_note_2_rounded,
                      value: '${notes.length}',
                      label: l10n.dashNotes,
                      color: const Color(0xFF14B8A6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Quick actions
            Entrance(
              delayMs: 100,
              child: Row(
                children: [
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.add_task_rounded,
                      label: l10n.quickAddTask,
                      onTap: () => showTaskFormSheet(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.edit_note_rounded,
                      label: l10n.quickAddNote,
                      onTap: () => context.go('/notes/new'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.local_fire_department_rounded,
                      label: l10n.quickCheckIn,
                      onTap: () => context.go('/habits'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Today's tasks
            Entrance(
              delayMs: 140,
              child: Column(
                children: [
                  SectionHeader(
                    title: l10n.dashTodayTasks,
                    actionLabel: l10n.dashSeeAll,
                    onAction: () => context.go('/tasks'),
                  ),
                  if (dueToday.isEmpty)
                    NaraCard(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          const Text('🌤️', style: TextStyle(fontSize: 26)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              l10n.dashEmptyTasks,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...dueToday.take(3).map(
                          (task) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _TodayTaskTile(task: task),
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(AppLocalizations l10n, DateTime now) {
    // dateFmt comes from generated intl date symbols via l10n;
    // keep it simple and language-neutral:
    const idMonths = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    const enMonths = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const idDays = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    const enDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final isId = l10n.localeName.startsWith('id');
    final months = isId ? idMonths : enMonths;
    final days = isId ? idDays : enDays;
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month]} ${now.year}';
  }
}

class _TodayTaskTile extends ConsumerWidget {
  const _TodayTaskTile({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final priorityColors = const [
      Color(0xFF14B8A6),
      Color(0xFFF59E0B),
      Color(0xFFEF476F),
    ];

    return NaraCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          _RoundCheck(
            color: priorityColors[task.priority.index],
            onToggle: () async {
              final repo = ref.read(taskRepositoryProvider);
              await repo.update(
                task.copyWith(done: true, updatedAt: DateTime.now()),
              );
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              task.title,
              style: theme.textTheme.titleSmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _timeLabel(task.dueDate, l10n),
            style: theme.textTheme.labelMedium,
          ),
        ],
      ),
    );
  }

  String _timeLabel(DateTime? due, AppLocalizations l10n) {
    if (due == null) return '';
    final hh = due.hour.toString().padLeft(2, '0');
    final mm = due.minute.toString().padLeft(2, '0');
    if (due.hour == 0 && due.minute == 0) return l10n.commonToday;
    return '$hh:$mm';
  }
}

class _RoundCheck extends StatelessWidget {
  const _RoundCheck({required this.color, required this.onToggle});

  final Color color;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onToggle,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: color, width: 2),
        ),
        child: const SizedBox(),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return NaraCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}
