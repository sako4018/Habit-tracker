import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streakly/screens/home_screen.dart';
import 'package:streakly/state/app_state.dart';

/// Проверява, че екраните наистина се пребоядисват при промяна на
/// AppState — точката, която unit тестовете не хващат.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget wrap(AppState state) {
    return ChangeNotifierProvider<AppState>.value(
      value: state,
      child: const MaterialApp(home: HomeScreen()),
    );
  }

  testWidgets('нов навик се появява на Home без рестарт', (tester) async {
    final state = AppState();
    await state.load();

    await tester.pumpWidget(wrap(state));
    await tester.pumpAndSettle();

    expect(find.text('Сутрешна разходка'), findsNothing);

    state.addHabit(name: 'Сутрешна разходка', emoji: '🚶');
    await tester.pumpAndSettle();

    expect(find.text('Сутрешна разходка'), findsOneWidget);
  });

  testWidgets('изтриване на навик го маха от Home', (tester) async {
    final state = AppState();
    await state.load();
    state.addHabit(name: 'Чети', emoji: '📖');

    await tester.pumpWidget(wrap(state));
    await tester.pumpAndSettle();

    expect(find.text('Чети'), findsOneWidget);

    state.deleteHabit(state.habits.first);
    await tester.pumpAndSettle();

    expect(find.text('Чети'), findsNothing);
  });

  testWidgets('clearAllData изчиства Home веднага', (tester) async {
    final state = AppState();
    await state.load();
    state.addHabit(name: 'Спорт', emoji: '🏃');

    await tester.pumpWidget(wrap(state));
    await tester.pumpAndSettle();

    expect(find.text('Спорт'), findsOneWidget);

    await state.clearAllData();
    await tester.pumpAndSettle();

    expect(find.text('Спорт'), findsNothing);
  });
}
