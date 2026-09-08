import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streakly/models/habit.dart';
import 'package:streakly/services/habit_storage.dart';
import 'package:streakly/services/storage_exception.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('load връща празен списък когато няма данни', () async {
    expect(await HabitStorage.load(), isEmpty);
  });

  test('save и load обхождат данните в кръг', () async {
    final habits = [
      Habit(id: '1', name: 'Чети', emoji: '📖', completedDates: {'2026-01-01'}),
      Habit(id: '2', name: 'Спорт', emoji: '🏃'),
    ];

    expect(await HabitStorage.save(habits), true);

    final loaded = await HabitStorage.load();
    expect(loaded.map((h) => h.name), ['Чети', 'Спорт']);
    expect(loaded.first.completedDates, {'2026-01-01'});
  });

  test('повреден JSON хвърля StorageException и пази backup', () async {
    SharedPreferences.setMockInitialValues({
      'habits_data_v2': '{ това не е валиден списък',
    });

    await expectLater(
      HabitStorage.load(),
      throwsA(isA<StorageException>()),
    );

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString('habits_data_v2_corrupt_backup'),
      '{ това не е валиден списък',
    );
  });

  test('save отказва да презапише данни с празен списък', () async {
    await HabitStorage.save([Habit(id: '1', name: 'x', emoji: '⭐')]);

    final ok = await HabitStorage.save([]);
    expect(ok, false);

    expect(await HabitStorage.load(), hasLength(1));
  });

  test('save([], allowEmpty: true) изчиства данните', () async {
    await HabitStorage.save([Habit(id: '1', name: 'x', emoji: '⭐')]);

    expect(await HabitStorage.save([], allowEmpty: true), true);
    expect(await HabitStorage.load(), isEmpty);
  });

  test('clearAll трие всичко', () async {
    await HabitStorage.save([Habit(id: '1', name: 'x', emoji: '⭐')]);

    await HabitStorage.clearAll();
    expect(await HabitStorage.load(), isEmpty);
  });
}
