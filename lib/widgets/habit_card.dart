import 'package:flutter/material.dart';

import '../models/habit.dart';
import '../theme/app_colors.dart';
import 'check_button.dart';

/// Ред за навик на екрана "Днес".
///
/// Съзнателно НЕ показва история (7-дневни точки, мини heatmap): "Днес"
/// е екран за отмятане, а историята живее в календара на навика и в
/// Статистика. Тук стоят само име, streak и мишената за отмятане.
class HabitCard extends StatelessWidget {
  final Habit habit;
  final VoidCallback onToggleToday;
  final VoidCallback onDelete;
  final VoidCallback onOpenCalendar;

  const HabitCard({
    super.key,
    required this.habit,
    required this.onToggleToday,
    required this.onDelete,
    required this.onOpenCalendar,
  });

  String _streakText(int streak) {
    if (streak == 0) {
      return 'започни отново';
    }

    return '$streak ${streak == 1 ? "ден" : "дни"} подред';
  }

  @override
  Widget build(BuildContext context) {
    final streak = habit.currentStreak;
    final isDone = habit.isDoneOn(DateTime.now());

    return Dismissible(
      key: ValueKey('dismiss_${habit.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppColors.surface,
                title: const Text(
                  'Изтриване',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                content: Text(
                  'Да изтрия ли "${habit.name}"?',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Отказ'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text(
                      'Изтрий',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onOpenCalendar,
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.fromLTRB(15, 11, 10, 11),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDone
                  ? AppColors.accent.withValues(alpha: 0.24)
                  : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(13),
                ),
                alignment: Alignment.center,
                child: Text(
                  habit.emoji,
                  style: const TextStyle(fontSize: 21),
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: AppColors.textPrimary,
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
                          _streakText(streak),
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              CheckButton(
                isDone: isDone,
                onTap: onToggleToday,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
