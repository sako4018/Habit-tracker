import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streakly/models/task.dart';
import 'package:streakly/services/storage_exception.dart';
import 'package:streakly/services/task_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('load връща празен списък когато няма данни', () async {
    expect(await TaskStorage.load(), isEmpty);
  });

  test('save и load обхождат данните в кръг', () async {
    final tasks = [
      Task(id: '1', name: 'Сметки', date: DateTime(2026, 3, 1)),
      Task(id: '2', name: 'Фитнес', date: DateTime(2026, 3, 2), isCompleted: true),
    ];

    await TaskStorage.save(tasks);

    final loaded = await TaskStorage.load();
    expect(loaded.map((t) => t.name), ['Сметки', 'Фитнес']);
    expect(loaded[1].isCompleted, true);
  });

  test('повреден JSON хвърля StorageException и пази backup', () async {
    SharedPreferences.setMockInitialValues({
      'tasks': 'няма как да е това списък',
    });

    await expectLater(
      TaskStorage.load(),
      throwsA(isA<StorageException>()),
    );

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString('tasks_corrupt_backup'),
      'няма как да е това списък',
    );
  });

  test('save отказва да презапише данни с празен списък', () async {
    await TaskStorage.save([
      Task(id: '1', name: 'x', date: DateTime(2026, 1, 1)),
    ]);

    await TaskStorage.save([]);

    expect(await TaskStorage.load(), hasLength(1));
  });

  test('clear трие всичко', () async {
    await TaskStorage.save([
      Task(id: '1', name: 'x', date: DateTime(2026, 1, 1)),
    ]);

    await TaskStorage.clear();
    expect(await TaskStorage.load(), isEmpty);
  });
}
