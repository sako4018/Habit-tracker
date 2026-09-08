import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/habit.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/contribution_heatmap.dart';
import '../widgets/heatmap_legend.dart';
import '../widgets/number_strip.dart';
import '../widgets/progress_ring.dart';
import '../widgets/section_label.dart';
import 'year_contribution_screen.dart';

/// Тук живее аналитиката, която съзнателно е махната от "Днес".
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  static const _windowDays = 30;

  /// Дял отметнати дни за навика през последните [_windowDays].
  static double _rateFor(Habit habit, DateTime today) {
    var done = 0;

    for (var i = 0; i < _windowDays; i++) {
      if (habit.isDoneOn(today.subtract(Duration(days: i)))) {
        done++;
      }
    }

    return done / _windowDays;
  }

  /// Дни през последната година с поне едно отметнато.
  static int _activeDays(List<Habit> habits, DateTime today) {
    var count = 0;

    for (var i = 0; i < 365; i++) {
      final day = today.subtract(Duration(days: i));

      if (habits.any((habit) => habit.isDoneOn(day))) {
        count++;
      }
    }

    return count;
  }

  @override
  Widget build(BuildContext context) {
    final habits = context.watch<AppState>().habits;

    final today = DateTime.now();

    final totalCheckIns = habits.fold<int>(
      0,
      (sum, habit) => sum + habit.totalCompleted,
    );

    final bestStreak = habits.isEmpty
        ? 0
        : habits
            .map((habit) => habit.bestStreak)
            .reduce((a, b) => a > b ? a : b);

    final overallRate = habits.isEmpty
        ? 0.0
        : habits
                .map((habit) => _rateFor(habit, today))
                .reduce((a, b) => a + b) /
            habits.length;

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text('Статистика'),
      ),

      body: habits.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Добави навици, за да видиш статистика.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 15,
                  ),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
              children: [
                // -----------------------------------------------------
                // Героят: единствената heatmap в приложението
                // -----------------------------------------------------
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SectionLabel('Активност ${today.year}'),
                          Text(
                            '${_activeDays(habits, today)} активни дни',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      ContributionHeatmap(habits: habits),

                      const SizedBox(height: 12),

                      const HeatmapLegend(),

                      const SizedBox(height: 4),

                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => YearContributionScreen(
                                habits: habits,
                              ),
                            ),
                          );
                        },
                        behavior: HitTestBehavior.opaque,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              Text(
                                'Цялата година',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 13,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 11,
                                color: AppColors.textMuted,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // -----------------------------------------------------
                // Един пръстен, една идея
                // -----------------------------------------------------
                _Card(
                  child: Row(
                    children: [
                      ProgressRing(
                        value: overallRate,
                        label: '${(overallRate * 100).round()}%',
                      ),
                      const SizedBox(width: 20),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Успеваемост',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Отметнати навици за\nпоследните 30 дни',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 13,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                NumberStrip(
                  numbers: [
                    StripNumber(
                      value: '$bestStreak',
                      label: 'Най-дълъг',
                      highlighted: true,
                    ),
                    StripNumber(
                      value: '$totalCheckIns',
                      label: 'Общо',
                    ),
                    StripNumber(
                      value: '${habits.length}',
                      label: 'Навика',
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                const SectionLabel('По навик · 30 дни'),

                const SizedBox(height: 14),

                for (final habit in habits)
                  _HabitRate(
                    habit: habit,
                    rate: _rateFor(habit, today),
                  ),
              ],
            ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _HabitRate extends StatelessWidget {
  final Habit habit;
  final double rate;

  const _HabitRate({
    required this.habit,
    required this.rate,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              habit.emoji,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 88,
            child: Text(
              habit.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 380),
                curve: Curves.easeOut,
                tween: Tween(begin: 0, end: rate),
                builder: (context, value, _) {
                  return LinearProgressIndicator(
                    value: value,
                    minHeight: 8,
                    backgroundColor: AppColors.track,
                    valueColor:
                        AlwaysStoppedAnimation(AppColors.accent),
                  );
                },
              ),
            ),
          ),
          SizedBox(
            width: 44,
            child: Text(
              '${(rate * 100).round()}%',
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
