import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streakly/screens/home_screen.dart';
import 'package:streakly/state/app_state.dart';
import 'package:streakly/widgets/heatmap_legend.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<AppState> pumpHome(WidgetTester tester) async {
    final state = AppState();
    await state.load();

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: state,
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    return state;
  }

  testWidgets('празен екран приканва да добавиш', (tester) async {
    await pumpHome(tester);

    expect(find.textContaining('Няма добавени навици'), findsOneWidget);
    // Без данни няма и ред за прогрес.
    expect(find.textContaining('изпълнени'), findsNothing);
  });

  testWidgets('редът за прогрес брои навици и задачи заедно',
      (tester) async {
    final state = await pumpHome(tester);

    state.addHabit(name: 'Спорт', emoji: '🏃');
    state.addTask(name: 'Сметки', date: DateTime.now());
    await tester.pumpAndSettle();

    expect(find.textContaining('изпълнени'), findsOneWidget);
    expect(find.text('остават 2'), findsOneWidget);

    state.toggleHabitToday(state.habits.first);
    await tester.pumpAndSettle();

    // Единствено число: "остава 1", не "остават 1".
    expect(find.text('остава 1'), findsOneWidget);

    state.toggleTask(state.tasks.first);
    await tester.pumpAndSettle();

    expect(find.text('готово за днес'), findsOneWidget);
  });

  testWidgets('Днес не показва аналитика (няма heatmap легенда)',
      (tester) async {
    final state = await pumpHome(tester);

    state.addHabit(name: 'Спорт', emoji: '🏃');
    await tester.pumpAndSettle();

    expect(find.byType(HeatmapLegend), findsNothing);
    expect(find.text('Цялата година'), findsNothing);
  });

  testWidgets('навик без streak казва "започни отново"', (tester) async {
    final state = await pumpHome(tester);

    state.addHabit(name: 'Медитация', emoji: '🧘');
    await tester.pumpAndSettle();

    expect(find.text('започни отново'), findsOneWidget);

    state.toggleHabitToday(state.habits.first);
    await tester.pumpAndSettle();

    expect(find.text('1 ден подред'), findsOneWidget);
  });

  testWidgets('секциите са озаглавени и навиците са преди задачите',
      (tester) async {
    final state = await pumpHome(tester);

    state.addHabit(name: 'Спорт', emoji: '🏃');
    state.addTask(name: 'Сметки', date: DateTime.now());
    await tester.pumpAndSettle();

    final habitsLabel = tester.getTopLeft(find.text('НАВИЦИ'));
    final tasksLabel = tester.getTopLeft(find.text('ЗАДАЧИ ЗА ДНЕС'));

    expect(habitsLabel.dy, lessThan(tasksLabel.dy));
  });
}
