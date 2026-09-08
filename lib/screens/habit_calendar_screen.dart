import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/bg_dates.dart';
import '../models/habit.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/number_strip.dart';
import '../widgets/section_label.dart';

/// Екранът на един навик: числата му и календар, в който изминал ден
/// може да се отметне допълнително.
class HabitCalendarScreen extends StatefulWidget {
  final Habit habit;

  const HabitCalendarScreen({
    super.key,
    required this.habit,
  });

  @override
  State<HabitCalendarScreen> createState() =>
      _HabitCalendarScreenState();
}

class _HabitCalendarScreenState
    extends State<HabitCalendarScreen> {
  late DateTime _visibleMonth;

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

  /// Напред се ходи само до текущия месец — в бъдещето няма какво да
  /// се види, а и дните там не се отмятат.
  bool get _canGoForward {
    final now = DateTime.now();

    return _visibleMonth.year < now.year ||
        (_visibleMonth.year == now.year &&
            _visibleMonth.month < now.month);
  }

  void _toggleDay(DateTime day) {
    final today = DateTime.now();

    final dayOnly = DateTime(day.year, day.month, day.day);
    final todayOnly = DateTime(today.year, today.month, today.day);

    // Не позволяваме отбелязване на бъдещи дни.
    if (dayOnly.isAfter(todayOnly)) {
      return;
    }

    context.read<AppState>().toggleHabitOn(widget.habit, day);

    // Локален setState, за да се преначертае календарната мрежа.
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final habit = widget.habit;
    final streak = habit.currentStreak;

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const SectionLabel('Навик'),
      ),

      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
        children: [
          // ---------------------------------------------------------
          // Кой навик гледаме
          // ---------------------------------------------------------
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text(
                  habit.emoji,
                  style: const TextStyle(fontSize: 26),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          size: 14,
                          color: streak > 0
                              ? AppColors.accent
                              : AppColors.inactive,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          streak > 0
                              ? '${BgDates.days(streak)} подред'
                              : 'започни отново',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          NumberStrip(
            numbers: [
              StripNumber(
                value: '$streak',
                label: 'Текущ',
                highlighted: true,
              ),
              StripNumber(
                value: '${habit.bestStreak}',
                label: 'Най-дълъг',
              ),
              StripNumber(
                value: '${habit.totalCompleted}',
                label: 'Общо',
              ),
            ],
          ),

          const SizedBox(height: 24),

          _CalendarCard(
            habit: habit,
            visibleMonth: _visibleMonth,
            canGoForward: _canGoForward,
            onChangeMonth: _changeMonth,
            onToggleDay: _toggleDay,
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// CALENDAR
// =====================================================================

class _CalendarCard extends StatelessWidget {
  final Habit habit;
  final DateTime visibleMonth;
  final bool canGoForward;
  final void Function(int) onChangeMonth;
  final void Function(DateTime) onToggleDay;

  const _CalendarCard({
    required this.habit,
    required this.visibleMonth,
    required this.canGoForward,
    required this.onChangeMonth,
    required this.onToggleDay,
  });

  @override
  Widget build(BuildContext context) {
    final firstOfMonth = DateTime(
      visibleMonth.year,
      visibleMonth.month,
      1,
    );

    final daysInMonth = DateTime(
      visibleMonth.year,
      visibleMonth.month + 1,
      0,
    ).day;

    // Понеделник = 1 ... Неделя = 7.
    final leadingEmpty = firstOfMonth.weekday - 1;
    final totalCells = leadingEmpty + daysInMonth;
    final rowCount = (totalCells / 7).ceil();

    final now = DateTime.now();
    final todayOnly = DateTime(now.year, now.month, now.day);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => onChangeMonth(-1),
                tooltip: 'Предишен месец',
                icon: const Icon(
                  Icons.chevron_left,
                  color: AppColors.textSecondary,
                  size: 26,
                ),
              ),
              Text(
                BgDates.monthYear(visibleMonth),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                onPressed: canGoForward ? () => onChangeMonth(1) : null,
                tooltip: 'Следващ месец',
                icon: Icon(
                  Icons.chevron_right,
                  color: canGoForward
                      ? AppColors.textSecondary
                      : AppColors.inactive,
                  size: 26,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Row(
            children: BgDates.weekdayLetters
                .map(
                  (day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: const TextStyle(
                          color: AppColors.textFaint,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),

          const SizedBox(height: 10),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rowCount * 7,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              final dayNum = index - leadingEmpty + 1;

              if (dayNum < 1 || dayNum > daysInMonth) {
                return const SizedBox.shrink();
              }

              final date = DateTime(
                visibleMonth.year,
                visibleMonth.month,
                dayNum,
              );

              final isFuture = date.isAfter(todayOnly);
              final done = habit.isDoneOn(date);
              final isToday = date == todayOnly;

              return Semantics(
                label: '$dayNum ${BgDates.monthYear(visibleMonth)}',
                checked: done,
                button: !isFuture,
                child: GestureDetector(
                  onTap: isFuture ? null : () => onToggleDay(date),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: done ? AppColors.accent : AppColors.track,
                      borderRadius: BorderRadius.circular(9),
                      border: isToday
                          ? Border.all(
                              color: AppColors.textPrimary,
                              width: 1.6,
                            )
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$dayNum',
                      style: TextStyle(
                        color: done
                            ? AppColors.background
                            : isFuture
                                ? AppColors.inactive
                                : AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: isToday
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 14),

          const Text(
            'Докосни изминал ден, за да го отметнеш допълнително.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textFaint,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
