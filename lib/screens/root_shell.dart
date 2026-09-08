import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/habit.dart';
import '../models/task.dart';
import '../services/habit_storage.dart';
import '../services/storage_exception.dart';
import '../services/task_storage.dart';
import '../widgets/add_habit_dialog.dart';
import '../widgets/add_task_dialog.dart';

import 'habit_calendar_screen.dart';
import 'home_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';
import 'year_contribution_screen.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  List<Habit> habits = [];
  List<Task> tasks = [];

  bool loading = true;

  /// Става true, ако запазените данни са повредени. Докато е true,
  /// записите се спират, за да не се презапишат възстановимите данни.
  bool _storageLocked = false;

  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    List<Habit> loadedHabits = [];
    List<Task> loadedTasks = [];
    var failed = false;

    try {
      loadedHabits = await HabitStorage.load();
    } on StorageException {
      failed = true;
    }

    try {
      loadedTasks = await TaskStorage.load();
    } on StorageException {
      failed = true;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      habits = loadedHabits;
      tasks = loadedTasks;
      loading = false;
      _storageLocked = failed;
    });

    if (failed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Запазените данни са повредени. Записът е спрян, '
            'за да не се изтрият. Рестартирай приложението.',
          ),
          duration: Duration(seconds: 8),
        ),
      );
    }
  }

  Future<void> _persistHabits() {
    if (_storageLocked) {
      return Future.value();
    }

    return HabitStorage.save(habits);
  }

  Future<void> _persistTasks() {
    if (_storageLocked) {
      return Future.value();
    }

    return TaskStorage.save(tasks);
  }

  void _toggleToday(Habit habit) {
    final now = DateTime.now();

    final willBeDone = !habit.isDoneOn(now);

    setState(() {
      habit.toggle(now);
    });

    _persistHabits();

    if (willBeDone) {
      HapticFeedback.mediumImpact();
      SystemSound.play(
        SystemSoundType.click,
      );
    }
  }

  void _toggleTask(Task task) {
    setState(() {
      task.toggle();
    });

    _persistTasks();

    if (task.isCompleted) {
      HapticFeedback.mediumImpact();
      SystemSound.play(
        SystemSoundType.click,
      );
    }
  }

  void _deleteHabit(Habit habit) {
    setState(() {
      habits.removeWhere(
        (h) => h.id == habit.id,
      );
    });

    _persistHabits();
  }

  void _deleteTask(Task task) {
    setState(() {
      tasks.removeWhere(
        (t) => t.id == task.id,
      );
    });

    _persistTasks();
  }

  Future<void> _addHabit() async {
    final result =
        await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => const AddHabitDialog(),
    );

    if (result == null) {
      return;
    }

    final newHabit = Habit(
      id:
          '${DateTime.now().millisecondsSinceEpoch}_${habits.length}',
      name: result['name']!,
      emoji: result['emoji']!,
    );

    setState(() {
      habits.add(newHabit);
    });

    _persistHabits();
  }

  Future<void> _addTask() async {
    final result =
        await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => const AddTaskDialog(),
    );

    if (result == null) {
      return;
    }

    final newTask = Task(
      id:
          '${DateTime.now().millisecondsSinceEpoch}_${tasks.length}',
      name: result['name']!,
      date: DateTime.parse(
        result['date']!,
      ),
    );

    setState(() {
      tasks.add(newTask);
    });

    _persistTasks();
  }

  Future<void> _openCalendar(Habit habit) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HabitCalendarScreen(
          habit: habit,
          onChanged: () {
            setState(() {});
            _persistHabits();
          },
        ),
      ),
    );
  }

  Future<void> _openYearContribution() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => YearContributionScreen(
          habits: habits,
        ),
      ),
    );
  }

  Future<void> _onDataCleared() async {
    await HabitStorage.clearAll();
    await TaskStorage.clear();

    if (!mounted) {
      return;
    }

    setState(() {
      habits = [];
      tasks = [];
      _storageLocked = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        habits: habits,
        tasks: tasks,
        loading: loading,
        onAddHabit: _addHabit,
        onAddTask: _addTask,
        onToggleToday: _toggleToday,
        onToggleTask: _toggleTask,
        onDelete: _deleteHabit,
        onDeleteTask: _deleteTask,
        onOpenCalendar: _openCalendar,
        onViewYear: _openYearContribution,
      ),

      StatsScreen(
        habits: habits,
      ),

      SettingsScreen(
        onDataCleared: _onDataCleared,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _tabIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (index) {
          setState(() {
            _tabIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.checklist_rtl,
            ),
            label: 'Днес',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.bar_chart,
            ),
            label: 'Статистика',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.settings,
            ),
            label: 'Настройки',
          ),
        ],
      ),
    );
  }
}
