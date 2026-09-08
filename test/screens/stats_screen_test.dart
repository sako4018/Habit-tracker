import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streakly/models/habit.dart';
import 'package:streakly/screens/stats_screen.dart';
import 'package:streakly/state/app_state.dart';
import 'package:streakly/widgets/progress_ring.dart';

String dayKey(int offset) =>
    Habit.keyFor(DateTime.now().subtract(Duration(days: offset)));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<AppState> pumpStats(WidgetTester tester) async {
    final state = AppState();
    await state.load();

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: state,
        child: const MaterialApp(home: StatsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    return state;
  }

  testWidgets('без навици подканя вместо да показва нули',
      (tester) async {
    await pumpStats(tester);

    expect(
      find.textContaining('Добави навици'),
      findsOneWidget,
    );
    expect(find.byType(ProgressRing), findsNothing);
  });

  testWidgets('успеваемостта е 100% при отметнати последни 30 дни',
      (tester) async {
    final state = await pumpStats(tester);

    state.addHabit(name: 'Вода', emoji: '💧');
    for (var i = 0; i < 30; i++) {
      state.habits.first.completedDates.add(dayKey(i));
    }
    await tester.pumpAndSettle();

    expect(find.text('100%'), findsWidgets);
  });

  testWidgets('лентата с числа показва най-дълъг, общо и брой навици',
      (tester) async {
    final state = await pumpStats(tester);

    state.addHabit(name: 'Спорт', emoji: '🏃');
    state.habits.first.completedDates.addAll({
      dayKey(0),
      dayKey(1),
      dayKey(2),
    });
    await tester.pumpAndSettle();

    expect(find.text('НАЙ-ДЪЛЪГ'), findsOneWidget);
    expect(find.text('ОБЩО'), findsOneWidget);
    expect(find.text('НАВИКА'), findsOneWidget);

    // 3 поредни дни -> най-дълъг 3, общо 3, един навик.
    expect(find.text('3'), findsNWidgets(2));
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('връзката към годишния изглед е тук, не на Днес',
      (tester) async {
    final state = await pumpStats(tester);

    state.addHabit(name: 'Спорт', emoji: '🏃');
    await tester.pumpAndSettle();

    expect(find.text('Цялата година'), findsOneWidget);
  });

  group('прозорецът не наказва новите навици', () {
    testWidgets('навик на един ден, отметнат днес, е 100%',
        (tester) async {
      final state = await pumpStats(tester);

      state.addHabit(name: 'Вода', emoji: '💧');
      state.toggleHabitToday(state.habits.first);
      await tester.pumpAndSettle();

      // Преди прозорецът беше фиксиран на 30 дни и това даваше 3%.
      expect(find.text('100%'), findsWidgets);
    });

    testWidgets('докато няма 30 дни история, текстът го казва',
        (tester) async {
      final state = await pumpStats(tester);

      state.addHabit(name: 'Вода', emoji: '💧');
      await tester.pumpAndSettle();

      expect(
        find.textContaining('откакто ги следиш'),
        findsOneWidget,
      );
      expect(find.textContaining('последните 30 дни'), findsNothing);
    });

    testWidgets('стар навик пак се мери спрямо пълните 30 дни',
        (tester) async {
      final old = Habit(
        id: 'old',
        name: 'Спорт',
        emoji: '🏃',
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
        completedDates: {
          for (var i = 0; i < 15; i++) dayKey(i),
        },
      );

      SharedPreferences.setMockInitialValues({
        'habits_data_v2': jsonEncode([old.toJson()]),
      });

      await pumpStats(tester);

      // 15 от 30 дни, а не 15 от 90.
      expect(find.text('50%'), findsWidgets);
      expect(
        find.textContaining('последните 30 дни'),
        findsOneWidget,
      );
    });
  });
}
