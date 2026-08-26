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

  static const List<String> _weekDays = [
    'П',
    'В',
    'С',
    'Ч',
    'П',
    'С',
    'Н',
  ];

  int _completedHabits(DateTime date) {
    return habits.where(
      (habit) => habit.isDoneOn(date),
    ).length;
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

    final year = now.year;
    final month = now.month;

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

    // Понеделник = 1 ... Неделя = 7.
    final leadingEmpty = firstDay.weekday - 1;

    final totalCells =
        leadingEmpty + daysInMonth;

    final weekCount =
        (totalCells / 7).ceil();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        // --------------------------------------------------
        // МЕСЕЦ
        // --------------------------------------------------

        Text(
          '${_monthNames[month - 1]} $year',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 12),

        // --------------------------------------------------
        // КАЛЕНДАР
        // --------------------------------------------------

        Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // ------------------------------------------------
            // ДНИ ОТ СЕДМИЦАТА
            // ------------------------------------------------

            SizedBox(
              width: 20,
              child: Column(
                children: List.generate(
                  7,
                  (index) {
                    return SizedBox(
                      height: 20,
                      child: Center(
                        child: Text(
                          _weekDays[index],
                          style: TextStyle(
                            color:
                                Colors.grey.shade500,
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

            // ------------------------------------------------
            // КВАДРАТЧЕТА
            // ------------------------------------------------

            Expanded(
              child: Column(
                children: List.generate(
                  7,
                  (weekdayIndex) {
                    return SizedBox(
                      height: 20,
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.start,
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

                            // Извън текущия месец.
                            if (dayNumber < 1 ||
                                dayNumber >
                                    daysInMonth) {
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

                            final level =
                                _levelFor(date);

                            final completed =
                                _completedHabits(
                              date,
                            );

                            final isToday =
                                date.year ==
                                        today.year &&
                                    date.month ==
                                        today.month &&
                                    date.day ==
                                        today.day;

                            return SizedBox(
                              width: 18,
                              height: 18,
                              child: Center(
                                child: Tooltip(
                                  message:
                                      '$dayNumber $month/$year\n'
                                      '$completed/${habits.length} навика',
                                  child:
                                      AnimatedContainer(
                                    duration:
                                        const Duration(
                                      milliseconds: 180,
                                    ),
                                    width: 16,
                                    height: 16,
                                    decoration:
                                        BoxDecoration(
                                      color:
                                          levels[level],
                                      borderRadius:
                                          BorderRadius
                                              .circular(3),
                                      border: isToday
                                          ? Border.all(
                                              color:
                                                  const Color(
                                                0xFF7CFF8C,
                                              ),
                                              width: 2,
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
}