import 'package:flutter_test/flutter_test.dart';
import 'package:streakly/models/task.dart';

void main() {
  group('Task JSON', () {
    test('toJson/fromJson запазва данните', () {
      final t = Task(
        id: 't1',
        name: 'Плати сметки',
        date: DateTime(2026, 3, 15),
        isCompleted: true,
      );

      final copy = Task.fromJson(t.toJson());

      expect(copy.id, 't1');
      expect(copy.name, 'Плати сметки');
      expect(copy.date, DateTime(2026, 3, 15));
      expect(copy.isCompleted, true);
    });

    test('липсващо isCompleted става false', () {
      final copy = Task.fromJson({
        'id': 't1',
        'name': 'x',
        'date': DateTime(2026, 1, 1).toIso8601String(),
      });
      expect(copy.isCompleted, false);
    });
  });

  group('Task.isForDate', () {
    test('сравнява само деня, не часа', () {
      final t = Task(
        id: 't1',
        name: 'x',
        date: DateTime(2026, 5, 20, 9, 30),
      );

      expect(t.isForDate(DateTime(2026, 5, 20, 23, 59)), true);
      expect(t.isForDate(DateTime(2026, 5, 21)), false);
    });
  });

  group('Task.toggle', () {
    test('обръща isCompleted', () {
      final t = Task(id: 't1', name: 'x', date: DateTime(2026, 1, 1));

      t.toggle();
      expect(t.isCompleted, true);

      t.toggle();
      expect(t.isCompleted, false);
    });
  });
}
