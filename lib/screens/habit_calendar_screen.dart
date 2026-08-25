import 'package:flutter/material.dart';

import '../models/habit.dart';
import '../theme/app_colors.dart';

class HabitCalendarScreen extends StatefulWidget {
  final Habit habit;
  final VoidCallback onChanged;

  const HabitCalendarScreen({
    super.key,
    required this.habit,
    required this.onChanged,
  });

  @override
  State<HabitCalendarScreen> createState() =>
      _HabitCalendarScreenState();
}

class _HabitCalendarScreenState
    extends State<HabitCalendarScreen> {
  late DateTime _visibleMonth;

  static const _monthNames = [
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

  static const _weekDayLabels = [
    'П',
    'В',
    'С',
    'Ч',
    'П',
    'С',
    'Н',
  ];

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    _visibleMonth = DateTime(
      now.year,
      now.month,
    );
  }

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(
        _visibleMonth.year,
        _visibleMonth.month + delta,
      );
    });
  }

  void _toggleDay(DateTime day) {
    final today = DateTime.now();

    final dayOnly = DateTime(
      day.year,
      day.month,
      day.day,
    );

    final todayOnly = DateTime(
      today.year,
      today.month,
      today.day,
    );

    // Не позволяваме отбелязване на бъдещи дни.
    if (dayOnly.isAfter(todayOnly)) {
      return;
    }

    setState(() {
      widget.habit.toggle(day);
    });

    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final habit = widget.habit;

    final firstOfMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month,
      1,
    );

    final daysInMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + 1,
      0,
    ).day;

    final leadingEmpty = firstOfMonth.weekday - 1;

    final today = DateTime.now();

    final todayOnly = DateTime(
      today.year,
      today.month,
      today.day,
    );

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: Row(
          children: [
            Text(
              habit.emoji,
              style: const TextStyle(fontSize: 20),
            ),

            const SizedBox(width: 8),

            Flexible(
              child: Text(
                habit.name,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            Row(
              children: [
                _StatChip(
                  label: 'Streak',
                  value: '${habit.currentStreak} 🔥',
                ),

                const SizedBox(width: 12),

                _StatChip(
                  label: 'Общо дни',
                  value: '${habit.totalCompleted}',
                ),
              ],
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => _changeMonth(-1),
                  icon: const Icon(
                    Icons.chevron_left,
                    color: Colors.white,
                  ),
                ),

                Text(
                  '${_monthNames[_visibleMonth.month - 1]} '
                  '${_visibleMonth.year}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                IconButton(
                  onPressed: () => _changeMonth(1),
                  icon: const Icon(
                    Icons.chevron_right,
                    color: Colors.white,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: _weekDayLabels
                  .map(
                    (day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: GridView.builder(
                itemCount:
                    leadingEmpty + daysInMonth,

                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),

                itemBuilder: (context, index) {
                  if (index < leadingEmpty) {
                    return const SizedBox.shrink();
                  }

                  final dayNum =
                      index - leadingEmpty + 1;

                  final date = DateTime(
                    _visibleMonth.year,
                    _visibleMonth.month,
                    dayNum,
                  );

                  final isFuture =
                      date.isAfter(todayOnly);

                  final done =
                      habit.isDoneOn(date);

                  final isToday =
                      date.year == today.year &&
                      date.month == today.month &&
                      date.day == today.day;

                  return GestureDetector(
                    onTap: isFuture
                        ? null
                        : () => _toggleDay(date),

                    child: AnimatedContainer(
                      duration:
                          const Duration(milliseconds: 200),

                      decoration: BoxDecoration(
                        color: done
                            ? AppColors.accent
                            : AppColors.surface,

                        borderRadius:
                            BorderRadius.circular(10),

                        border: isToday
                            ? Border.all(
                                color: AppColors.accent,
                                width: 2,
                              )
                            : null,
                      ),

                      alignment: Alignment.center,

                      child: Text(
                        '$dayNum',

                        style: TextStyle(
                          color: isFuture
                              ? Colors.grey.shade700
                              : done
                                  ? Colors.black
                                  : Colors.white,

                          fontWeight: isToday
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 12),

        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),

        alignment: Alignment.center,

        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 2),

            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}