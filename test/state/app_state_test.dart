import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streakly/services/habit_storage.dart';
import 'package:streakly/services/task_storage.dart';
import 'package:streakly/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('load с чист диск дава празни списъци и не заключва', () async {
    final state = AppState();
    await state.load();

    expect(state.habits, isEmpty);
    expect(state.tasks, isEmpty);
    expect(state.loading, false);
    expect(state.storageLocked, false);
  });

  test('addHabit добавя и запазва на диска', () async {
    final state = AppState();
    await state.load();

    state.addHabit(name: 'Чети', emoji: '📖');

    expect(state.habits.single.name, 'Чети');
    expect(await HabitStorage.load(), hasLength(1));
  });

  test('повреден storage заключва записите — мутациите не пишат', () async {
    SharedPreferences.setMockInitialValues({
      'habits_data_v2': 'не е валиден json',
    });

    final state = AppState();
    await state.load();

    expect(state.storageLocked, true);

    // Мутация докато е заключено не бива да презаписва backup-а.
    state.addHabit(name: 'Нов', emoji: '⭐');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('habits_data_v2'), 'не е валиден json');
  });

  test('clearAllData изпразва двата списъка и диска', () async {
    final state = AppState();
    await state.load();

    state.addHabit(name: 'x', emoji: '⭐');
    state.addTask(name: 'y', date: DateTime(2026, 1, 1));

    // Изчакваме записите.
    await Future<void>.delayed(Duration.zero);

    await state.clearAllData();

    expect(state.habits, isEmpty);
    expect(state.tasks, isEmpty);
    expect(state.storageLocked, false);
    expect(await HabitStorage.load(), isEmpty);
    expect(await TaskStorage.load(), isEmpty);
  });

  test('notifyListeners се вика при добавяне', () async {
    final state = AppState();
    await state.load();

    var notified = 0;
    state.addListener(() => notified++);

    state.addHabit(name: 'x', emoji: '⭐');
    state.deleteHabit(state.habits.first);

    expect(notified, 2);
  });
}
