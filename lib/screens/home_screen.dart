import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/habit.dart';
import '../models/task.dart';
import '../services/profile_storage.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/add_habit_dialog.dart';
import '../widgets/add_task_dialog.dart';
import '../widgets/contribution_heatmap.dart';
import '../widgets/heatmap_legend.dart';
import '../widgets/habit_card.dart';
import 'habit_calendar_screen.dart';
import 'profile_screen.dart';
import 'year_contribution_screen.dart';

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

  void _openYearContribution(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => YearContributionScreen(
          habits: context.read<AppState>().habits,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    final habits = appState.habits;
    final tasks = appState.tasks;
    final loading = appState.loading;

    final today = DateTime.now();

    final todayTasks = tasks
        .where((task) => _isSameDay(task.date, today))
        .toList();

    final doneHabits = habits
        .where((habit) => habit.isDoneOn(today))
        .length;

    final doneTasks =
        todayTasks.where((task) => task.isCompleted).length;

    final totalToday = habits.length + todayTasks.length;
    final doneToday = doneHabits + doneTasks;

    return Scaffold(
      body: SafeArea(
        child: loading
            ? Center(
                child: CircularProgressIndicator(
                  color: AppColors.accent,
                ),
              )
            : CustomScrollView(
                slivers: [
                  // =====================================================
                  // PROFILE HEADER
                  // =====================================================

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        20,
                        16,
                        20,
                        4,
                      ),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const ProfileScreen(),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            ValueListenableBuilder<Uint8List?>(
                              valueListenable:
                                  ProfileStorage.photoNotifier,
                              builder: (context, photo, _) {
                                return CircleAvatar(
                                  radius: 21,
                                  backgroundColor:
                                      AppColors.surface,
                                  backgroundImage: photo != null
                                      ? MemoryImage(photo)
                                      : null,
                                  child: photo == null
                                      ? const Icon(
                                          Icons.person,
                                          color: Colors.grey,
                                          size: 22,
                                        )
                                      : null,
                                );
                              },
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ValueListenableBuilder<String>(
                                valueListenable:
                                    ProfileStorage.nameNotifier,
                                builder: (context, name, _) {
                                  return Text(
                                    name.isEmpty
                                        ? 'Streakly'
                                        : name,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: -0.5,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // =====================================================
                  // TODAY HEADER
                  // =====================================================

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        20,
                        12,
                        20,
                        8,
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Днес',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            totalToday == 0
                                ? 'Добави първия си навик или задача 👇'
                                : '$doneToday от $totalToday изпълнени',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // =====================================================
                  // CONTRIBUTION
                  // =====================================================

                  if (habits.isNotEmpty || tasks.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          20,
                          0,
                          20,
                          8,
                        ),
                        child: Container(
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
                                    'Активност',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight:
                                          FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () =>
                                        _openYearContribution(
                                      context,
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          'Цялата година',
                                          style: TextStyle(
                                            color:
                                                Colors.grey.shade400,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(width: 3),
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          size: 10,
                                          color:
                                              Colors.grey.shade400,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ContributionHeatmap(
                                habits: habits,
                                tasks: tasks,
                              ),
                              const SizedBox(height: 10),
                              const HeatmapLegend(),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // =====================================================
                  // TASKS FOR TODAY
                  // =====================================================

                  if (todayTasks.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          16,
                          8,
                          16,
                          4,
                        ),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Задачи за днес',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '$doneTasks/${todayTasks.length}',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (todayTasks.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      sliver: SliverList(
                        delegate:
                            SliverChildBuilderDelegate(
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

                  // =====================================================
                  // HABITS
                  // =====================================================

                  if (habits.isNotEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          16,
                          16,
                          4,
                        ),
                        child: Text(
                          'Навици',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                  if (habits.isEmpty && todayTasks.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            'Няма добавени навици или задачи все още.\n'
                            'Натисни + за да започнеш.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    )
                  else if (habits.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      sliver: SliverList(
                        delegate:
                            SliverChildBuilderDelegate(
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

                  const SliverToBoxAdapter(
                    child: SizedBox(height: 100),
                  ),
                ],
              ),
      ),

      // ===============================================================
      // ADD BUTTON
      // ===============================================================

      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: () {
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
                          color: Colors.white,
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
                          icon: const Icon(
                            Icons.repeat,
                          ),
                          label: const Text(
                            'Нов навик',
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                AppColors.accent,
                            foregroundColor:
                                Colors.black,
                            padding:
                                const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
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
                          icon: const Icon(
                            Icons.task_alt,
                          ),
                          label: const Text(
                            'Еднократна задача',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
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
        },
        icon: const Icon(Icons.add),
        label: const Text('Добави'),
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
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (context) {
                return AlertDialog(
                  backgroundColor: AppColors.surface,
                  title: const Text(
                    'Изтриване',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  content: const Text(
                    'Сигурен ли си, че искаш да изтриеш тази задача?',
                    style: TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () =>
                          Navigator.pop(context, false),
                      child: const Text('Отказ'),
                    ),
                    FilledButton(
                      onPressed: () =>
                          Navigator.pop(context, true),
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
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 4,
          ),
          leading: GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration:
                  const Duration(milliseconds: 180),
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: task.isCompleted
                    ? AppColors.accent
                    : Colors.transparent,
                border: Border.all(
                  color: task.isCompleted
                      ? AppColors.accent
                      : Colors.grey.shade600,
                  width: 2,
                ),
              ),
              child: task.isCompleted
                  ? const Icon(
                      Icons.check,
                      size: 19,
                      color: Colors.black,
                    )
                  : null,
            ),
          ),
          title: Text(
            task.name,
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              decoration: task.isCompleted
                  ? TextDecoration.lineThrough
                  : null,
              decorationColor: Colors.grey,
            ),
          ),
          subtitle: const Text(
            'Еднократна задача',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          trailing: IconButton(
            onPressed: onDelete,
            icon: Icon(
              Icons.delete_outline,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }
}
