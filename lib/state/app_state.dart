import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/habit.dart';
import '../models/task.dart';
import '../services/habit_storage.dart';
import '../services/storage_exception.dart';
import '../services/task_storage.dart';

/// Единно място за навиците и задачите на приложението.
///
/// Всеки екран слуша този обект чрез `context.watch<AppState>()` и се
/// пребоядисва при промяна. Мутациите (добавяне, отметка, триене) сами
/// извикват [notifyListeners] и запазват на диска.
class AppState extends ChangeNotifier {
  final List<Habit> _habits = [];
  final List<Task> _tasks = [];

  bool _loading = true;
  bool _storageLocked = false;

  /// Копие само за четене — екраните не бива да променят списъка директно.
  List<Habit> get habits => List.unmodifiable(_habits);
  List<Task> get tasks => List.unmodifiable(_tasks);

  bool get loading => _loading;

  /// true, ако запазените данни са повредени. Докато е true, записите
  /// се спират, за да не се презапишат възстановимите данни.
  bool get storageLocked => _storageLocked;

  /// Зарежда данните от диска. Извиква се веднъж при стартиране.
  Future<void> load() async {
    var failed = false;

    try {
      _habits
        ..clear()
        ..addAll(await HabitStorage.load());
    } on StorageException {
      failed = true;
    }

    try {
      _tasks
        ..clear()
        ..addAll(await TaskStorage.load());
    } on StorageException {
      failed = true;
    }

    _loading = false;
    _storageLocked = failed;
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Навици
  // ---------------------------------------------------------------------

  void addHabit({required String name, required String emoji}) {
    _habits.add(
      Habit(
        id: '${DateTime.now().millisecondsSinceEpoch}_${_habits.length}',
        name: name,
        emoji: emoji,
      ),
    );

    notifyListeners();
    _persistHabits();
  }

  void deleteHabit(Habit habit) {
    _habits.removeWhere((h) => h.id == habit.id);

    notifyListeners();
    _persistHabits();
  }

  /// Отмята навика за днес (от Home екрана).
  void toggleHabitToday(Habit habit) {
    _toggleHabitOn(habit, DateTime.now());
  }

  /// Отмята навика за конкретен ден (от календара).
  void toggleHabitOn(Habit habit, DateTime day) {
    _toggleHabitOn(habit, day);
  }

  void _toggleHabitOn(Habit habit, DateTime day) {
    final willBeDone = !habit.isDoneOn(day);

    habit.toggle(day);

    notifyListeners();
    _persistHabits();

    if (willBeDone) {
      HapticFeedback.mediumImpact();
      SystemSound.play(SystemSoundType.click);
    }
  }

  // ---------------------------------------------------------------------
  // Задачи
  // ---------------------------------------------------------------------

  void addTask({required String name, required DateTime date}) {
    _tasks.add(
      Task(
        id: '${DateTime.now().millisecondsSinceEpoch}_${_tasks.length}',
        name: name,
        date: date,
      ),
    );

    notifyListeners();
    _persistTasks();
  }

  void deleteTask(Task task) {
    _tasks.removeWhere((t) => t.id == task.id);

    notifyListeners();
    _persistTasks();
  }

  void toggleTask(Task task) {
    task.toggle();

    notifyListeners();
    _persistTasks();

    if (task.isCompleted) {
      HapticFeedback.mediumImpact();
      SystemSound.play(SystemSoundType.click);
    }
  }

  // ---------------------------------------------------------------------
  // Изчистване
  // ---------------------------------------------------------------------

  /// Изтрива всички навици и задачи. Ползва директните clear методи,
  /// защото save() отказва да презапише данни с празен списък.
  Future<void> clearAllData() async {
    await HabitStorage.clearAll();
    await TaskStorage.clear();

    _habits.clear();
    _tasks.clear();
    _storageLocked = false;

    notifyListeners();
  }

  // ---------------------------------------------------------------------

  Future<void> _persistHabits() {
    if (_storageLocked) {
      return Future.value();
    }

    return HabitStorage.save(_habits);
  }

  Future<void> _persistTasks() {
    if (_storageLocked) {
      return Future.value();
    }

    return TaskStorage.save(_tasks);
  }
}
