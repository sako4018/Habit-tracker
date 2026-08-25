import 'package:flutter/material.dart';

import '../models/habit.dart';
import '../theme/app_colors.dart';

class ContributionHeatmap extends StatelessWidget {
  final List<Habit> habits;
  final int weeks;

  const ContributionHeatmap({
    super.key,
    required this.habits,
    this.weeks = 5,
  });

  static const List<Color> levels = [
    Color(0xFF262626), // 0 done
    Color(0x40BB86FC), // ~25%
    Color(0x80BB86FC), // ~50%
    Color(0xBFBB86FC), // ~75%
    AppColors.accent, // 100%
  ];

  int _levelFor(DateTime day) {
    if (habits.isEmpty) return 0;

    final done = habits.where((h) => h.isDoneOn(day)).length;

    if (done == 0) return 0;

    final ratio = done / habits.length;

    if (ratio < 0.34) return 1;
    if (ratio < 0.67) return 2;
    if (ratio < 1.0) return 3;

    return 4;
  }

  static const _monthNames = [
    'Яну',
    'Фев',
    'Мар',
    'Апр',
    'Май',
    'Юни',
    'Юли',
    'Авг',
    'Сеп',
    'Окт',
    'Ное',
    'Дек',
  ];

  static const _dayLabels = [
    'П',
    '',
    'С',
    '',
    'П',
    '',
    '',
  ];

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();

    final todayOnly = DateTime(
      today.year,
      today.month,
      today.day,
    );

    final daysBack = weeks * 7 - 1;

    var start = todayOnly.subtract(
      Duration(days: daysBack),
    );

    start = start.subtract(
      Duration(days: start.weekday - 1),
    );

    final totalDays =
        todayOnly.difference(start).inDays + 1;

    final columnsCount = (totalDays / 7).ceil();

    int? lastMonth;

    final columns = <Widget>[];

    for (int col = 0; col < columnsCount; col++) {
      String? monthLabel;

      final cells = <Widget>[];

      for (int row = 0; row < 7; row++) {
        final date = start.add(
          Duration(
            days: col * 7 + row,
          ),
        );

        if (row == 0 &&
            date.month != lastMonth &&
            !date.isAfter(todayOnly)) {
          monthLabel = _monthNames[date.month - 1];
          lastMonth = date.month;
        }

        if (date.isAfter(todayOnly)) {
          cells.add(
            const SizedBox(
              width: 12,
              height: 12,
            ),
          );

          continue;
        }

        final level = _levelFor(date);

        final isToday =
            date.year == todayOnly.year &&
            date.month == todayOnly.month &&
            date.day == todayOnly.day;

        cells.add(
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.all(1.5),
            decoration: BoxDecoration(
              color: levels[level],
              borderRadius: BorderRadius.circular(3),
              border: isToday
                  ? Border.all(
                      color: Colors.white54,
                      width: 1,
                    )
                  : null,
            ),
          ),
        );
      }

      columns.add(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 14,
              width: 15,
              child: monthLabel != null
                  ? Text(
                      monthLabel,
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey.shade500,
                      ),
                      overflow: TextOverflow.visible,
                      softWrap: false,
                    )
                  : null,
            ),
            ...cells,
          ],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true,
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              top: 14,
              right: 4,
            ),
            child: Column(
              children: _dayLabels
                  .map(
                    (label) => SizedBox(
                      height: 15,
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          ...columns,
        ],
      ),
    );
  }
}