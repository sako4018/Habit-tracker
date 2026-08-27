import 'package:flutter/material.dart';

import '../models/habit.dart';
import '../theme/app_colors.dart';
import '../widgets/contribution_heatmap.dart';
import '../widgets/heatmap_legend.dart';
import '../widgets/habit_card.dart';

class HomeScreen extends StatelessWidget {
  final List<Habit> habits;
  final bool loading;

  final VoidCallback onAddHabit;
  final void Function(Habit) onToggleToday;
  final void Function(Habit) onDelete;
  final void Function(Habit) onOpenCalendar;
  final VoidCallback onViewYear;

  const HomeScreen({
    super.key,
    required this.habits,
    required this.loading,
    required this.onAddHabit,
    required this.onToggleToday,
    required this.onDelete,
    required this.onOpenCalendar,
    required this.onViewYear,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();

    final doneToday = habits
        .where((habit) => habit.isDoneOn(today))
        .length;

    return Scaffold(
      body: SafeArea(
        child: loading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.accent,
                ),
              )
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        20,
                        20,
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
                            habits.isEmpty
                                ? 'Добави първия си навик 👇'
                                : '$doneToday от ${habits.length} изпълнени',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (habits.isNotEmpty)
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
                                    MainAxisAlignment
                                        .spaceBetween,
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
                                    onTap: onViewYear,
                                    child: Row(
                                      children: [
                                        Text(
                                          'Цялата година',
                                          style: TextStyle(
                                            color: Colors
                                                .grey
                                                .shade400,
                                            fontSize: 12,
                                          ),
                                        ),

                                        const SizedBox(
                                          width: 3,
                                        ),

                                        Icon(
                                          Icons
                                              .arrow_forward_ios,
                                          size: 10,
                                          color: Colors
                                              .grey
                                              .shade400,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 10),

                              ContributionHeatmap(
                                habits: habits,
                              ),

                              const SizedBox(height: 10),

                              const HeatmapLegend(),
                            ],
                          ),
                        ),
                      ),
                    ),

                  if (habits.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding:
                              const EdgeInsets.all(32),
                          child: Text(
                            'Няма добавени навици все още.\n'
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
                  else
                    SliverPadding(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      sliver: SliverList(
                        delegate:
                            SliverChildBuilderDelegate(
                          (context, index) {
                            final habit =
                                habits[index];

                            return HabitCard(
                              key: ValueKey(habit.id),
                              habit: habit,
                              onToggleToday:
                                  () => onToggleToday(habit),
                              onDelete:
                                  () => onDelete(habit),
                              onOpenCalendar:
                                  () => onOpenCalendar(habit),
                            );
                          },
                          childCount: habits.length,
                        ),
                      ),
                    ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: 80),
                  ),
                ],
              ),
      ),

      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: onAddHabit,
        icon: const Icon(Icons.add),
        label: const Text('Нов навик'),
      ),
    );
  }
}