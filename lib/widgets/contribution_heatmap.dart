import 'package:flutter/material.dart';

import '../l10n/bg_dates.dart';
import '../models/habit.dart';
import '../models/task.dart';
import '../theme/app_colors.dart';

class ContributionHeatmap extends StatelessWidget {
  final List<Habit> habits;
  final List<Task> tasks;
  final int weeks;

  const ContributionHeatmap({
    super.key,
    required this.habits,
    this.tasks = const [],
    this.weeks = 5,
  });

  /// Стълбицата се тонира с текущия акцентен цвят.
  static List<Color> get levels => AppColors.heatmapLevels;

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  int _completedHabits(DateTime date) {
    return habits.where((habit) => habit.isDoneOn(date)).length;
  }

  int _completedTasks(DateTime date) {
    return tasks
        .where(
          (task) =>
              _isSameDay(task.date, date) &&
              task.isCompleted,
        )
        .length;
  }

  int _totalItems(DateTime date) {
    final totalHabits = habits.length;

    final totalTasksForDate = tasks
        .where((task) => _isSameDay(task.date, date))
        .length;

    return totalHabits + totalTasksForDate;
  }

  int _completedItems(DateTime date) {
    return _completedHabits(date) + _completedTasks(date);
  }

  int _levelFor(DateTime date) {
    final total = _totalItems(date);

    if (total == 0) {
      return 0;
    }

    final completed = _completedItems(date);
    final percentage = completed / total;

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

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    final normalizedToday = DateTime(
      now.year,
      now.month,
      now.day,
    );

    // Взима се веднъж на build и се подава надолу: годишният изглед
    // рисува ~365 клетки и не бива да пита за стълбицата на всяка.
    final ramp = levels;

    if (weeks >= 52) {
      return _buildYearHeatmap(normalizedToday, ramp);
    }

    return _buildMonthHeatmap(normalizedToday, ramp);
  }

  Widget _buildMonthHeatmap(DateTime today, List<Color> ramp) {
    final year = today.year;
    final month = today.month;

    final firstDay = DateTime(
      year,
      month,
      1,
    );

    final daysInMonth = DateTime(
      year,
      month + 1,
      0,
    ).day;

    final leadingEmpty = firstDay.weekday - 1;

    final totalCells = leadingEmpty + daysInMonth;

    final weekCount = (totalCells / 7).ceil();

    const weekDays = BgDates.weekdayLetters;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          BgDates.monthYear(firstDay),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 20,
              child: Column(
                children: List.generate(
                  7,
                  (weekdayIndex) {
                    return SizedBox(
                      height: 20,
                      child: Center(
                        child: Text(
                          weekDays[weekdayIndex],
                          style: const TextStyle(
                            color: AppColors.textFaint,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Column(
                children: List.generate(
                  7,
                  (weekdayIndex) {
                    return SizedBox(
                      height: 20,
                      child: Row(
                        children: List.generate(
                          weekCount,
                          (weekIndex) {
                            final cellIndex =
                                weekIndex * 7 + weekdayIndex;

                            final dayNumber =
                                cellIndex - leadingEmpty + 1;

                            if (dayNumber < 1 ||
                                dayNumber > daysInMonth) {
                              return const SizedBox(
                                width: 18,
                                height: 18,
                              );
                            }

                            final date = DateTime(
                              year,
                              month,
                              dayNumber,
                            );

                            return _buildDayCell(
                              date: date,
                              today: today,
                              ramp: ramp,
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildYearHeatmap(DateTime today, List<Color> ramp) {
    final startDate = today.subtract(
      const Duration(days: 364),
    );

    final monday = startDate.subtract(
      Duration(days: startDate.weekday - 1),
    );

    final dates = List.generate(
      52 * 7,
      (index) => monday.add(
        Duration(days: index),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Последната година',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 125,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(
                52,
                (weekIndex) {
                  return Padding(
                    padding: const EdgeInsets.only(
                      right: 3,
                    ),
                    child: Column(
                      children: List.generate(
                        7,
                        (weekdayIndex) {
                          final index =
                              weekIndex * 7 + weekdayIndex;

                          final date = dates[index];

                          final isFuture =
                              date.isAfter(today);

                          if (isFuture) {
                            return const SizedBox(
                              width: 14,
                              height: 14,
                            );
                          }

                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: 3,
                            ),
                            child: _buildYearCell(
                              date,
                              today,
                              ramp,
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildYearCell(
    DateTime date,
    DateTime today,
    List<Color> ramp,
  ) {
    final level = _levelFor(date);
    final completed = _completedItems(date);
    final total = _totalItems(date);

    final isToday =
        date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;

    return Tooltip(
      message:
          '${date.day}.${date.month}.${date.year}\n'
          '$completed/$total изпълнени',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: ramp[level],
          borderRadius: BorderRadius.circular(3),
          border: isToday
              ? Border.all(
                  color: AppColors.textPrimary,
                  width: 1.5,
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildDayCell({
    required DateTime date,
    required DateTime today,
    required List<Color> ramp,
  }) {
    final level = _levelFor(date);
    final completed = _completedItems(date);
    final total = _totalItems(date);

    final isToday =
        date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;

    return SizedBox(
      width: 18,
      height: 18,
      child: Center(
        child: Tooltip(
          message:
              '${date.day}.${date.month}.${date.year}\n'
              '$completed/$total изпълнени',
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: ramp[level],
              borderRadius: BorderRadius.circular(3),
              border: isToday
                  ? Border.all(
                      color: AppColors.textPrimary,
                      width: 2,
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
