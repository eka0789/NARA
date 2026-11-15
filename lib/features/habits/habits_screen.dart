import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/models/habit.dart';
import '../../core/providers/core_providers.dart';
import '../../core/theme/nara_theme.dart';
import '../../core/utils/date_time_ext.dart';
import '../../core/widgets/ui.dart';
import '../data/data_providers.dart';
import 'habit_form_sheet.dart';
import 'habit_streak.dart';

/// Habit list: weekly consistency chart, streaks, weekly dots, and one-tap
/// daily check-in with a small celebration.
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
                  itemCount: habits.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return const Entrance(child: _WeekChartCard());
                    }
                    final habit = habits[index - 1];
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
                        onToggle: () {
                          if (!doneToday) HapticFeedback.lightImpact();
                          ref
                              .read(habitRepositoryProvider)
                              .toggleLog(habit.id, todayKey);
                        },
                        onEdit: () => showHabitFormSheet(context, habit: habit),
                      ),
                    );
                  },
                ),
    );
  }
}

/// "This week" card: 7-day check-in bars across all habits, today marked.
class _WeekChartCard extends ConsumerWidget {
  const _WeekChartCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final habits = ref.watch(habitsProvider).value ?? const <Habit>[];
    final logs = ref.watch(habitLogsProvider).value ?? const <String, Set<String>>{};
    final now = DateTime.now();

    final counts = weekCheckIns(
      habits.map((h) => logs[h.id] ?? const <String>{}),
      now,
    );
    final peak = counts.fold<int>(1, math.max);
    final total = counts.fold<int>(0, (a, b) => a + b);
    final weekStart = now.weekStart;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return NaraCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(l10n.habitWeekTitle, style: theme.textTheme.titleSmall),
              ),
              Text(
                l10n.habitWeekCheckIns(total),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration:
                reduceMotion ? Duration.zero : const Duration(milliseconds: 650),
            curve: Curves.easeOutCubic,
            builder: (context, t, _) => SizedBox(
              height: 84,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < 7; i++)
                    _DayBar(
                      dayLabel: DateFormat.E(l10n.localeName)
                          .format(weekStart.addDays(i)),
                      height: 4 + 46 * (counts[i] / peak) * t,
                      count: counts[i],
                      isToday: i == now.weekday - 1,
                      accent: theme.colorScheme.primary,
                      muted: theme.colorScheme.surfaceContainerHighest,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One bar (with weekday label) of the weekly consistency chart.
class _DayBar extends StatelessWidget {
  const _DayBar({
    required this.dayLabel,
    required this.height,
    required this.count,
    required this.isToday,
    required this.accent,
    required this.muted,
  });

  final String dayLabel;
  final double height;
  final int count;
  final bool isToday;
  final Color accent;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: count == 0
                ? muted.withValues(alpha: 0.55)
                : accent.withValues(alpha: isToday ? 1 : 0.45),
            borderRadius: BorderRadius.circular(6),
            gradient: isToday && count > 0 ? NaraGradients.brand : null,
          ),
          alignment: Alignment.center,
          child: count > 0
              ? Text(
                  '$count',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                )
              : null,
        ),
        const SizedBox(height: 6),
        Text(
          dayLabel,
          style: theme.textTheme.labelSmall?.copyWith(
            color: isToday ? accent : theme.colorScheme.onSurfaceVariant,
            fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
          ),
          maxLines: 1,
        ),
      ],
    );
  }
}

class _HabitCard extends StatefulWidget {
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
  State<_HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends State<_HabitCard> {
  bool _celebrating = false;

  void _stopCelebrating() {
    if (mounted) setState(() => _celebrating = false);
  }

  @override
  void didUpdateWidget(_HabitCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The stream flipping false→true is the ground truth that a check-in
    // landed (optimistic UI or AI action — celebrate either way).
    if (widget.doneToday &&
        !oldWidget.doneToday &&
        !MediaQuery.disableAnimationsOf(context)) {
      setState(() => _celebrating = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final habit = widget.habit;
    final color = NaraPalette.habitColors[habit.colorIndex.clamp(
      0,
      NaraPalette.habitColors.length - 1,
    )];

    final weekStart = widget.now.weekStart;
    final streak = widget.streak;
    final streakLabel = streak == 0
        ? l10n.habitNoStreak
        : streak == 1
            ? l10n.habitStreakOne
            : l10n.habitStreakDays(streak);

    return Stack(
      children: [
        NaraCard(
          onTap: widget.onEdit,
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
                    child:
                        Text(habit.emoji, style: const TextStyle(fontSize: 22)),
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
                  _CheckButton(
                    done: widget.doneToday,
                    color: color,
                    onToggle: widget.onToggle,
                  ),
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
                        final filled =
                            widget.days.contains(dateKey(day));
                        final isToday = day.isSameDay(widget.now);
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
        ),
        if (_celebrating)
          Positioned.fill(
            child: IgnorePointer(
              child: _ConfettiBurst(onFinished: _stopCelebrating),
            ),
          ),
      ],
    );
  }
}

/// A short confetti burst over the habit card after a successful check-in.
/// Particles are seeded once per burst and painted from a single [t] value,
/// so the whole effect is one animation controller — cheap and deterministic
/// to interrupt.
class _ConfettiBurst extends StatefulWidget {
  const _ConfettiBurst({required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<_ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<_ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Confetto> _confetti;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) widget.onFinished();
      });
    final random = math.Random();
    const colors = [
      Color(0xFF5B5BD6),
      Color(0xFF8B5CF6),
      Color(0xFF14B8A6),
      Color(0xFFF59E0B),
      Color(0xFFEF476F),
    ];
    _confetti = [
      for (var i = 0; i < 30; i++)
        _Confetto(
          angle: -math.pi / 2 + (random.nextDouble() - 0.5) * 2.4,
          speed: 130 + random.nextDouble() * 210,
          size: 3.5 + random.nextDouble() * 4.5,
          color: colors[random.nextInt(colors.length)],
          square: i.isEven,
          spin: (random.nextDouble() - 0.5) * 10,
        ),
    ];
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        size: Size.infinite,
        painter: _ConfettiPainter(t: _controller.value, confetti: _confetti),
      ),
    );
  }
}

class _Confetto {
  const _Confetto({
    required this.angle,
    required this.speed,
    required this.size,
    required this.color,
    required this.square,
    required this.spin,
  });

  final double angle;
  final double speed;
  final double size;
  final Color color;
  final bool square;
  final double spin;
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({required this.t, required this.confetti});

  final double t;
  final List<_Confetto> confetti;

  @override
  void paint(Canvas canvas, Size size) {
    final seconds = t * 1.3;
    final origin = Offset(size.width * 0.82, size.height * 0.14);
    final fade = (1 - t).clamp(0.0, 1.0);
    for (final c in confetti) {
      final distance = c.speed * seconds;
      final dx = origin.dx + math.cos(c.angle) * distance;
      final dy = origin.dy +
          math.sin(c.angle) * distance +
          420 * seconds * seconds; // gravity
      if (dy > size.height + 16) continue;
      final paint = Paint()
        ..color = c.color.withValues(alpha: fade)
        ..style = PaintingStyle.fill;
      if (c.square) {
        canvas
          ..save()
          ..translate(dx, dy)
          ..rotate(c.spin * seconds)
          ..drawRect(
            Rect.fromCenter(
              center: Offset.zero,
              width: c.size,
              height: c.size,
            ),
            paint,
          )
          ..restore();
      } else {
        canvas.drawCircle(Offset(dx, dy), c.size / 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.t != t;
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

