import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streakly/l10n/bg_dates.dart';
import 'package:streakly/screens/habit_calendar_screen.dart';
import 'package:streakly/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<AppState> pumpCalendar(WidgetTester tester) async {
    final state = AppState();
    await state.load();
    state.addHabit(name: 'Спорт', emoji: '🏃');

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: state,
        child: MaterialApp(
          home: HabitCalendarScreen(habit: state.habits.first),
        ),
      ),
    );
    await tester.pumpAndSettle();

    return state;
  }

  testWidgets('показва трите числа на навика', (tester) async {
    await pumpCalendar(tester);

    expect(find.text('ТЕКУЩ'), findsOneWidget);
    expect(find.text('НАЙ-ДЪЛЪГ'), findsOneWidget);
    expect(find.text('ОБЩО'), findsOneWidget);
  });

  testWidgets('започва на текущия месец и не пуска напред',
      (tester) async {
    await pumpCalendar(tester);

    expect(
      find.text(BgDates.monthYear(DateTime.now())),
      findsOneWidget,
    );

    final forward = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.chevron_right),
    );
    expect(forward.onPressed, isNull);
  });

  testWidgets('назад сменя месеца и връща бутона напред',
      (tester) async {
    await pumpCalendar(tester);

    await tester.tap(
      find.widgetWithIcon(IconButton, Icons.chevron_left),
    );
    await tester.pumpAndSettle();

    final now = DateTime.now();
    final previous = DateTime(now.year, now.month - 1);

    expect(find.text(BgDates.monthYear(previous)), findsOneWidget);

    final forward = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.chevron_right),
    );
    expect(forward.onPressed, isNotNull);
  });

  testWidgets('докосване на днешния ден го отмята', (tester) async {
    final state = await pumpCalendar(tester);
    final habit = state.habits.first;

    expect(habit.isDoneOn(DateTime.now()), false);

    await tester.tap(find.text('${DateTime.now().day}'));
    await tester.pumpAndSettle();

    expect(habit.isDoneOn(DateTime.now()), true);
    expect(find.text('1 ден подред'), findsOneWidget);
  });
}
