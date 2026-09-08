import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/bg_dates.dart';
import '../models/habit.dart';
import '../models/task.dart';
import '../services/profile_storage.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/add_habit_dialog.dart';
import '../widgets/add_task_dialog.dart';
import '../widgets/habit_card.dart';
import '../widgets/section_label.dart';
import 'habit_calendar_screen.dart';
import 'profile_screen.dart';

/// Екранът "Днес" е за отмятане, не за анализ.
///
/// Отгоре стои само един ред прогрес; статистиката и историята живеят
/// в Статистика и в календара на навика.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  Future<void> _showAddHabitDialog(BuildContext context) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => const AddHabitDialog(),
    );

    if (result == null || !context.mounted) {
      return;
    }

    context.read<AppState>().addHabit(
          name: result['name']!,
          emoji: result['emoji']!,
        );
  }

  Future<void> _showAddTaskDialog(BuildContext context) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => const AddTaskDialog(),
    );

    if (result == null || !context.mounted) {
      return;
    }

    context.read<AppState>().addTask(
          name: result['name']!,
          date: DateTime.parse(result['date']!),
        );
  }

  void _openCalendar(BuildContext context, Habit habit) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HabitCalendarScreen(habit: habit),
      ),
    );
  }

  void _openAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Какво искаш да добавиш?',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _showAddHabitDialog(context);
                    },
                    icon: const Icon(Icons.repeat),
                    label: const Text('Нов навик'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.background,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _showAddTaskDialog(context);
                    },
                    icon: const Icon(Icons.task_alt),
                    label: const Text('Еднократна задача'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    final habits = appState.habits;
    final tasks = appState.tasks;

    final today = DateTime.now();

    final todayTasks = tasks
        .where((task) => _isSameDay(task.date, today))
        .toList();

    final doneHabits =
        habits.where((habit) => habit.isDoneOn(today)).length;

    final doneTasks =
        todayTasks.where((task) => task.isCompleted).length;

    final totalToday = habits.length + todayTasks.length;
    final doneToday = doneHabits + doneTasks;

    final isEmpty = habits.isEmpty && todayTasks.isEmpty;

    return Scaffold(
      body: SafeArea(
        child: appState.loading
            ? Center(
                child: CircularProgressIndicator(
                  color: AppColors.accent,
                ),
              )
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _Header(
                      today: BgDates.weekdayDayMonth(today),
                    ),
                  ),

                  if (!isEmpty)
                    SliverToBoxAdapter(
                      child: _DayProgress(
                        done: doneToday,
                        total: totalToday,
                      ),
                    ),

                  // ---------------------------------------------------
                  // Навици — първото нещо на екрана след деня
                  // ---------------------------------------------------

                  if (habits.isNotEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(18, 28, 18, 10),
                        child: SectionLabel('Навици'),
                      ),
                    ),

                  if (habits.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final habit = habits[index];

                            return HabitCard(
                              key: ValueKey(habit.id),
                              habit: habit,
                              onToggleToday: () => context
                                  .read<AppState>()
                                  .toggleHabitToday(habit),
                              onDelete: () => context
                                  .read<AppState>()
                                  .deleteHabit(habit),
                              onOpenCalendar: () =>
                                  _openCalendar(context, habit),
                            );
                          },
                          childCount: habits.length,
                        ),
                      ),
                    ),

                  // ---------------------------------------------------
                  // Задачи за днес
                  // ---------------------------------------------------

                  if (todayTasks.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 24, 18, 10),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            const SectionLabel('Задачи за днес'),
                            Text(
                              '$doneTasks/${todayTasks.length}',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (todayTasks.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final task = todayTasks[index];

                            return _TaskCard(
                              key: ValueKey(task.id),
                              task: task,
                              onToggle: () => context
                                  .read<AppState>()
                                  .toggleTask(task),
                              onDelete: () => context
                                  .read<AppState>()
                                  .deleteTask(task),
                            );
                          },
                          childCount: todayTasks.length,
                        ),
                      ),
                    ),

                  if (isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text(
                            'Няма добавени навици или задачи все още.\n'
                            'Натисни + за да започнеш.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: 100),
                  ),
                ],
              ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Добави'),
      ),
    );
  }
}

// =====================================================================
// HEADER
// =====================================================================

class _Header extends StatelessWidget {
  final String today;

  const _Header({required this.today});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Днес',
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  today,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProfileScreen(),
                ),
              );
            },
            child: ValueListenableBuilder<Uint8List?>(
              valueListenable: ProfileStorage.photoNotifier,
              builder: (context, photo, _) {
                return CircleAvatar(
                  radius: 19,
                  backgroundColor: AppColors.surface,
                  backgroundImage:
                      photo != null ? MemoryImage(photo) : null,
                  child: photo == null
                      ? const Icon(
                          Icons.person,
                          color: AppColors.textMuted,
                          size: 21,
                        )
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// DAY PROGRESS
// =====================================================================

class _DayProgress extends StatelessWidget {
  final int done;
  final int total;

  const _DayProgress({
    required this.done,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = total - done;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$done',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: ' от '),
                    TextSpan(
                      text: '$total',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const TextSpan(text: ' изпълнени'),
                  ],
                ),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              Text(
                remaining == 0
                    ? 'готово за днес'
                    : BgDates.remaining(remaining),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOut,
              tween: Tween(
                begin: 0,
                end: total == 0 ? 0 : done / total,
              ),
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 4,
                  backgroundColor: AppColors.track,
                  valueColor: AlwaysStoppedAnimation(AppColors.accent),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// TASK CARD
// =====================================================================

class _TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _TaskCard({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(task.id),
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
              builder: (context) {
                return AlertDialog(
                  backgroundColor: AppColors.surface,
                  title: const Text(
                    'Изтриване',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  content: const Text(
                    'Сигурен ли си, че искаш да изтриеш тази задача?',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Отказ'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Изтрий'),
                    ),
                  ],
                );
              },
            ) ??
            false;
      },
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(15, 8, 12, 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Semantics(
              label: task.name,
              checked: task.isCompleted,
              button: true,
              child: GestureDetector(
                onTap: onToggle,
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: task.isCompleted
                            ? AppColors.accent
                            : Colors.transparent,
                        border: task.isCompleted
                            ? null
                            : Border.all(
                                color: AppColors.inactive,
                                width: 2,
                              ),
                      ),
                      child: task.isCompleted
                          ? const Icon(
                              Icons.check,
                              size: 17,
                              color: AppColors.background,
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                task.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: task.isCompleted
                      ? AppColors.textMuted
                      : AppColors.textPrimary,
                  fontSize: 15,
                  decoration: task.isCompleted
                      ? TextDecoration.lineThrough
                      : null,
                  decorationColor: AppColors.textFaint,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
