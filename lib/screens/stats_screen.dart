import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/contribution_heatmap.dart';
import '../widgets/heatmap_legend.dart';
import '../widgets/stat_card.dart';
import 'year_contribution_screen.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final habits = context.watch<AppState>().habits;

    final totalCheckIns = habits.fold<int>(
      0,
      (sum, habit) => sum + habit.totalCompleted,
    );

    final bestStreak = habits.isEmpty
        ? 0
        : habits
            .map((habit) => habit.bestStreak)
            .reduce((a, b) => a > b ? a : b);

    final today = DateTime.now();

    int possibleSlots = 0;
    int doneSlots = 0;

    for (final habit in habits) {
      for (int i = 0; i < 30; i++) {
        final day = today.subtract(
          Duration(days: i),
        );

        possibleSlots++;

        if (habit.isDoneOn(day)) {
          doneSlots++;
        }
      }
    }

    final successRate = possibleSlots == 0
        ? 0
        : ((doneSlots / possibleSlots) * 100).round();

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text('Статистика'),
      ),

      body: habits.isEmpty
          ? const Center(
              child: Text(
                'Добави навици, за да видиш статистика.',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 15,
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      StatCard(
                        label: 'Успеваемост (30 дни)',
                        value: '$successRate%',
                      ),

                      const SizedBox(width: 12),

                      StatCard(
                        label: 'Най-дълъг streak',
                        value: '$bestStreak дни',
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      StatCard(
                        label: 'Навици',
                        value: '${habits.length}',
                      ),

                      const SizedBox(width: 12),

                      StatCard(
                        label: 'Общо отчитания',
                        value: '$totalCheckIns',
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius:
                          BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Активност този месец',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        YearContributionScreen(
                                      habits: habits,
                                    ),
                                  ),
                                );
                              },
                              behavior: HitTestBehavior.opaque,
                              child: const Row(
                                children: [
                                  Text(
                                    'Цялата година',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                  SizedBox(width: 3),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 10,
                                    color: AppColors.textMuted,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        ContributionHeatmap(
                          habits: habits,
                        ),

                        const SizedBox(height: 10),

                        const HeatmapLegend(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}