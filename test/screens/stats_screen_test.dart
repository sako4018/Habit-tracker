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
}
