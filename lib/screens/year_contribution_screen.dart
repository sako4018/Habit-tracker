import 'package:flutter/material.dart';

import '../l10n/bg_dates.dart';
import '../models/habit.dart';
import '../theme/app_colors.dart';
import '../widgets/heatmap_legend.dart';

class YearContributionScreen extends StatelessWidget {
  final List<Habit> habits;

  const YearContributionScreen({
    super.key,
    required this.habits,
  });

  static const List<Color> levels = [
    Color(0xFF202A23),
    Color(0xFF123D20),
    Color(0xFF176B2C),
    Color(0xFF26A641),
    Color(0xFF39D353),
  ];

  static const List<String> monthNames = BgDates.months;

  static const List<String> weekDays = BgDates.weekdayLetters;

  int completedHabits(DateTime date) {
    return habits.where(
      (habit) => habit.isDoneOn(date),
    ).length;
  }

  int levelFor(DateTime date) {
    if (habits.isEmpty) {
      return 0;
    }

    final completed = completedHabits(date);
    final percentage = completed / habits.length;

    if (percentage == 0) {
      return 0;
    }

    if (percentage <= 0.20) {
      return 1;
    }

    if (percentage <= 0.40) {
      return 2;
    }

    if (percentage <= 0.60) {
      return 3;
    }

    return 4;
  }

  Widget _buildMonth(
    BuildContext context,
    int year,
    int month,
  ) {
    final firstDay = DateTime(year, month, 1);

    final daysInMonth = DateTime(
      year,
      month + 1,
      0,
    ).day;

    // Понеделник = 0 ... Неделя = 6.
    final leadingEmpty = firstDay.weekday - 1;

    final totalCells = leadingEmpty + daysInMonth;
    final weekCount = (totalCells / 7).ceil();

    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            monthNames[month - 1],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 10),

          // Календар
          Column(
            children: List.generate(
              7,
              (weekdayIndex) {
                return SizedBox(
                  height: 18,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 18,
                        child: Center(
                          child: Text(
                            weekDays[weekdayIndex],
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 8,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 4),

                      Expanded(
                        child: Row(
                          children: List.generate(
                            weekCount,
                            (weekIndex) {
                              final cellIndex =
                                  weekIndex * 7 +
                                  weekdayIndex;

                              final dayNumber =
                                  cellIndex -
                                  leadingEmpty +
                                  1;

                              // Празна клетка преди началото
                              // или след края на месеца.
                              if (dayNumber < 1 ||
                                  dayNumber > daysInMonth) {
                                return const Expanded(
                                  child: SizedBox(),
                                );
                              }

                              final date = DateTime(
                                year,
                                month,
                                dayNumber,
                              );

                              final level = levelFor(date);
                              final completed =
                                  completedHabits(date);

                              final isFuture =
                                  date.isAfter(today);

                              final isToday =
                                  date.year == today.year &&
                                  date.month == today.month &&
                                  date.day == today.day;

                              return Expanded(
                                child: Center(
                                  child: Tooltip(
                                    message:
                                        '$dayNumber/$month/$year\n'
                                        '$completed/${habits.length} навика',
                                    child: Container(
                                      width: 13,
                                      height: 13,
                                      decoration: BoxDecoration(
                                        color: isFuture
                                            ? levels[0]
                                            : levels[level],
                                        borderRadius:
                                            BorderRadius.circular(3),
                                        border: isToday
                                            ? Border.all(
                                                color:
                                                    const Color(
                                                  0xFF7CFF8C,
                                                ),
                                                width: 1.5,
                                              )
                                            : null,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final year = DateTime.now().year;

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: Text(
          'Цялата година $year',
        ),
      ),

      body: habits.isEmpty
          ? Center(
              child: Text(
                'Добави навици, за да видиш активността.',
                style: TextStyle(
                  color: Colors.grey.shade500,
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Активност за годината',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Всеки квадрат показва процента изпълнени навици за деня.',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 20),

                  ...List.generate(
                    12,
                    (index) => _buildMonth(
                      context,
                      year,
                      index + 1,
                    ),
                  ),

                  const SizedBox(height: 4),

                  const HeatmapLegend(),

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}
