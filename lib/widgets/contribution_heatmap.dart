import 'package:flutter/material.dart';

import '../models/habit.dart';

class ContributionHeatmap extends StatelessWidget {
  final List<Habit> habits;
  final int weeks;

  const ContributionHeatmap({
    super.key,
    required this.habits,
    this.weeks = 5,
  });

  static const List<Color> levels = [
    Color(0xFF202A23),
    Color(0xFF123D20),
    Color(0xFF176B2C),
    Color(0xFF26A641),
    Color(0xFF39D353),
  ];

  static const List<String> _monthNames = [
    'Януари',
    'Февруари',
    'Март',
    'Април',
    'Май',
    'Юни',
    'Юли',
    'Август',
    'Септември',
    'Октомври',
    'Ноември',
    'Декември',
  ];

  int _completedHabits(DateTime date) {
    return habits.where((habit) => habit.isDoneOn(date)).length;
  }

  int _levelFor(DateTime date) {
    if (habits.isEmpty) {
      return 0;
    }

    final completed = _completedHabits(date);
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

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    final normalizedToday = DateTime(
      now.year,
      now.month,
      now.day,
    );

    /*
     * weeks = 5:
     * Megjelenява текущия месец.
     *
     * weeks = 52:
     * Показва последните 52 седмици,
     * като GitHub-style contribution графика.
     */

    if (weeks >= 52) {
      return _buildYearHeatmap(normalizedToday);
    }

    return _buildMonthHeatmap(normalizedToday);
  }

  Widget _buildMonthHeatmap(DateTime today) {
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

    // Dart:
    // Monday = 1
    // Tuesday = 2
    // ...
    // Sunday = 7
    //
    // Затова понеделник има индекс 0.
    final leadingEmpty = firstDay.weekday - 1;

    final totalCells = leadingEmpty + daysInMonth;

    final weekCount = (totalCells / 7).ceil();

    const weekDays = [
      'П',
      'В',
      'С',
      'Ч',
      'П',
      'С',
      'Н',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_monthNames[month - 1]} $year',
          style: const TextStyle(
            color: Colors.white,
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
                          style: TextStyle(
                            color: Colors.grey.shade500,
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

  Widget _buildYearHeatmap(DateTime today) {
    /*
     * Намираме понеделника преди или на датата,
     * която е преди 52 седмици.
     */

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
  ) {
    final level = _levelFor(date);
    final completed = _completedHabits(date);

    final isToday =
        date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;

    return Tooltip(
      message:
          '${date.day}.${date.month}.${date.year}\n'
          '$completed/${habits.length} навика',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: levels[level],
          borderRadius: BorderRadius.circular(3),
          border: isToday
              ? Border.all(
                  color: const Color(0xFF7CFF8C),
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
  }) {
    final level = _levelFor(date);
    final completed = _completedHabits(date);

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
              '$completed/${habits.length} навика',
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: levels[level],
              borderRadius: BorderRadius.circular(3),
              border: isToday
                  ? Border.all(
                      color: const Color(0xFF7CFF8C),
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