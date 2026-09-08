import 'package:flutter_test/flutter_test.dart';
import 'package:streakly/models/habit.dart';

/// Ключ (yyyy-MM-dd) за ден отместен с [offset] дни спрямо днес.
String dayKey(int offset) {
  final d = DateTime.now().add(Duration(days: offset));
  return Habit.keyFor(d);
}

void main() {
  group('Habit.currentStreak', () {
    test('нула при никакви отметки', () {
      final h = Habit(id: '1', name: 'Чети', emoji: '📖');
      expect(h.currentStreak, 0);
    });

    test('брои поредни дни завършващи днес', () {
      final h = Habit(
        id: '1',
        name: 'Чети',
        emoji: '📖',
        completedDates: {dayKey(0), dayKey(-1), dayKey(-2)},
      );
      expect(h.currentStreak, 3);
    });

    test('брои серия завършваща вчера (днес още не е отметнато)', () {
      final h = Habit(
        id: '1',
        name: 'Чети',
        emoji: '📖',
        completedDates: {dayKey(-1), dayKey(-2)},
      );
      expect(h.currentStreak, 2);
    });

    test('прекъсване нулира серията', () {
      final h = Habit(
        id: '1',
        name: 'Чети',
        emoji: '📖',
        completedDates: {dayKey(0), dayKey(-2), dayKey(-3)},
      );
      expect(h.currentStreak, 1);
    });

    test('серия само в миналото не се брои за текуща', () {
      final h = Habit(
        id: '1',
        name: 'Чети',
        emoji: '📖',
        completedDates: {dayKey(-5), dayKey(-6), dayKey(-7)},
      );
      expect(h.currentStreak, 0);
    });
  });

  group('Habit.bestStreak', () {
    test('нула при празно', () {
      final h = Habit(id: '1', name: 'x', emoji: '⭐');
      expect(h.bestStreak, 0);
    });

    test('една отметка дава 1', () {
      final h = Habit(
        id: '1',
        name: 'x',
        emoji: '⭐',
        completedDates: {dayKey(-10)},
      );
      expect(h.bestStreak, 1);
    });

    test('намира най-дългата серия сред няколко', () {
      final h = Habit(
        id: '1',
        name: 'x',
        emoji: '⭐',
        completedDates: {
          dayKey(-1), dayKey(-2), // серия 2
          dayKey(-10), dayKey(-11), dayKey(-12), dayKey(-13), // серия 4
          dayKey(-20), // серия 1
        },
      );
      expect(h.bestStreak, 4);
    });
  });

  group('Habit.last7Days', () {
    test('връща 7 стойности от най-стар към днес', () {
      final h = Habit(
        id: '1',
        name: 'x',
        emoji: '⭐',
        completedDates: {dayKey(0), dayKey(-6)},
      );
      final week = h.last7Days;
      expect(week.length, 7);
      expect(week.first, true); // преди 6 дни
      expect(week.last, true); // днес
      expect(week[3], false); // преди 3 дни
    });
  });

  group('Habit.toggle', () {
    test('добавя и маха ден', () {
      final h = Habit(id: '1', name: 'x', emoji: '⭐');
      final now = DateTime.now();

      h.toggle(now);
      expect(h.isDoneOn(now), true);

      h.toggle(now);
      expect(h.isDoneOn(now), false);
    });
  });

  group('Habit JSON', () {
    test('toJson/fromJson запазва данните', () {
      final h = Habit(
        id: 'abc',
        name: 'Спорт',
        emoji: '🏃',
        completedDates: {'2026-01-01', '2026-01-02'},
      );

      final copy = Habit.fromJson(h.toJson());

      expect(copy.id, 'abc');
      expect(copy.name, 'Спорт');
      expect(copy.emoji, '🏃');
      expect(copy.completedDates, {'2026-01-01', '2026-01-02'});
    });

    test('липсващо emoji става ⭐', () {
      final copy = Habit.fromJson({
        'id': '1',
        'name': 'x',
        'emoji': '   ',
        'completedDates': <String>[],
      });
      expect(copy.emoji, '⭐');
    });
  });
}
