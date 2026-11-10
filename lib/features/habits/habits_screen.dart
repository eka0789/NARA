import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/habit.dart';
import '../../core/providers/core_providers.dart';
import '../../core/theme/nara_theme.dart';
import '../../core/utils/date_time_ext.dart';
import '../../core/widgets/ui.dart';
import '../data/data_providers.dart';
import 'habit_form_sheet.dart';
import 'habit_streak.dart';

/// Habit list: streaks, weekly dots, and one-tap daily check-in.
class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final habitsAsync = ref.watch(habitsProvider);
    final habits = habitsAsync.value ?? const <Habit>[];
    final logs = ref.watch(habitLogsProvider).value ?? const <String, Set<String>>{};
    final now = DateTime.now();
    final todayKey = dateKey(now);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.habitsTitle),
        backgroundColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showHabitFormSheet(context),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.habitNew),
      ),
      body: habitsAsync.isLoading && habits.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : habits.isEmpty
              ? EmptyState(
                  icon: Icons.local_fire_department_rounded,
                  title: l10n.habitEmptyTitle,
                  body: l10n.habitEmptyBody,
                  actionLabel: l10n.habitNew,
                  onAction: () => showHabitFormSheet(context),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                  itemCount: habits.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final habit = habits[index];
                    final days = logs[habit.id] ?? const <String>{};
                    final doneToday = days.contains(todayKey);
                    final streak = streakFor(days, now);
                    return Entrance(
                      delayMs: index < 8 ? index * 40 : 0,
                      child: _HabitCard(
                        habit: habit,
                        days: days,
                        now: now,
                        doneToday: doneToday,
                        streak: streak,
                        onToggle: () => ref
                            .read(habitRepositoryProvider)
                            .toggleLog(habit.id, todayKey),
                        onEdit: () => showHabitFormSheet(context, habit: habit),
                      ),
                    );
                  },
                ),
    );
  }
}

class _HabitCard extends StatelessWidget {
  const _HabitCard({
    required this.habit,
    required this.days,
    required this.now,
    required this.doneToday,
    required this.streak,
    required this.onToggle,
    required this.onEdit,
  });

  final Habit habit;
  final Set<String> days;
  final DateTime now;
  final bool doneToday;
  final int streak;
  final VoidCallback onToggle;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final color = NaraPalette.habitColors[habit.colorIndex.clamp(
      0,
      NaraPalette.habitColors.length - 1,
    )];

    final weekStart = now.weekStart;
    final streakLabel = streak == 0
        ? l10n.habitNoStreak
        : streak == 1
            ? l10n.habitStreakOne
            : l10n.habitStreakDays(streak);

    return NaraCard(
      onTap: onEdit,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(habit.emoji, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (streak > 0) ...[
                          Icon(
                            Icons.local_fire_department_rounded,
                            size: 15,
                            color: const Color(0xFFF59E0B),
                          ),
                          const SizedBox(width: 2),
                        ],
                        Flexible(
                          child: Text(
                            streakLabel,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.habitTimesPerWeek(habit.targetPerWeek),
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _CheckButton(done: doneToday, color: color, onToggle: onToggle),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.weeklyProgress,
                  style: theme.textTheme.labelSmall,
                ),
              ),
              for (var i = 0; i < 7; i++)
                Builder(
                  builder: (context) {
                    final day = weekStart.addDays(i);
                    final filled = days.contains(dateKey(day));
                    final isToday = day.isSameDay(now);
                    return Container(
                      width: 22,
                      height: 22,
                      margin: const EdgeInsets.only(left: 6),
                      decoration: BoxDecoration(
                        color: filled
                            ? color
                            : theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                        border: isToday && !filled
                            ? Border.all(color: color, width: 1.6)
                            : null,
                      ),
                      child: filled
                          ? const Icon(
                              Icons.check_rounded,
                              size: 14,
                              color: Colors.white,
                            )
                          : null,
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CheckButton extends StatelessWidget {
  const _CheckButton({
    required this.done,
    required this.color,
    required this.onToggle,
  });

  final bool done;
  final Color color;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: done ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          boxShadow: done
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              done ? Icons.check_rounded : Icons.add_rounded,
              size: 16,
              color: done ? Colors.white : color,
            ),
            const SizedBox(width: 4),
            Text(
              done ? l10n.habitDoneToday : l10n.habitCheckIn,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: done ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
