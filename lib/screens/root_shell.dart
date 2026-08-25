import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/add_habit_dialog.dart';
import '../models/habit.dart';
import '../services/habit_storage.dart';
import 'habit_calendar_screen.dart';
import 'home_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  List<Habit> habits = [];
  bool loading = true;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final loaded = await HabitStorage.load();

    setState(() {
      habits = loaded;
      loading = false;
    });
  }

  Future<void> _persist() {
    return HabitStorage.save(habits);
  }

  void _toggleToday(Habit habit) {
    final now = DateTime.now();

    final willBeDone = !habit.isDoneOn(now);

    setState(() {
      habit.toggle(now);
    });

    _persist();

    if (willBeDone) {
      HapticFeedback.mediumImpact();
      SystemSound.play(SystemSoundType.click);
    }
  }

  void _deleteHabit(Habit habit) {
    setState(() {
      habits.removeWhere(
        (h) => h.id == habit.id,
      );
    });

    _persist();
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

    _persist();
  }

  void _openCalendar(Habit habit) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HabitCalendarScreen(
          habit: habit,
          onChanged: () {
            setState(() {});
            _persist();
          },
        ),
      ),
    );
  }

  void _goToStatsTab() {
    setState(() {
      _tabIndex = 1;
    });
  }

  void _onDataCleared() {
    setState(() {
      habits = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        habits: habits,
        loading: loading,
        onAddHabit: _addHabit,
        onToggleToday: _toggleToday,
        onDelete: _deleteHabit,
        onOpenCalendar: _openCalendar,
        onViewYear: _goToStatsTab,
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

      bottomNavigationBar:
          BottomNavigationBar(
        currentIndex: _tabIndex,

        onTap: (index) {
          setState(() {
            _tabIndex = index;
          });
        },

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.checklist_rtl),
            label: 'Днес',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Статистика',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Настройки',
          ),
        ],
      ),
    );
  }
}