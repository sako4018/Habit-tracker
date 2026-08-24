// Basic widget tests for the Habit Tracker app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:habit_tracker/main.dart';

void main() {
  testWidgets('App starts and shows empty state', (WidgetTester tester) async {
    await tester.pumpWidget(const HabitTrackerApp());
    await tester.pumpAndSettle();

    expect(find.text('Днес'), findsOneWidget);
    expect(find.textContaining('Добави'), findsWidgets);
    expect(find.text('Нов навик'), findsOneWidget);
  });

  testWidgets('Can add a new habit with emoji and name', (WidgetTester tester) async {
    await tester.pumpWidget(const HabitTrackerApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Нов навик'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('emoji_field')), '💧');
    await tester.enterText(find.byKey(const Key('name_field')), 'Пий вода');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Добави'));
    await tester.pumpAndSettle();

    expect(find.text('Пий вода'), findsOneWidget);
    expect(find.textContaining('дни подред'), findsOneWidget);
  });

  testWidgets('Cannot add habit without name', (WidgetTester tester) async {
    await tester.pumpWidget(const HabitTrackerApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Нов навик'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('emoji_field')), '💧');
    await tester.tap(find.text('Добави'));
    await tester.pumpAndSettle();

    expect(find.text('Въведи име на навика'), findsOneWidget);
  });

  testWidgets('Can toggle a habit as done for today', (WidgetTester tester) async {
    await tester.pumpWidget(const HabitTrackerApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Нов навик'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('emoji_field')), '📖');
    await tester.enterText(find.byKey(const Key('name_field')), 'Чети книга');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Добави'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check), findsNothing);

    await tester.tap(find.byKey(const Key('check_button')));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('Opens calendar screen when tapping a habit card', (WidgetTester tester) async {
    await tester.pumpWidget(const HabitTrackerApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Нов навик'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('emoji_field')), '🏃');
    await tester.enterText(find.byKey(const Key('name_field')), 'Бягане');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Добави'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Бягане'));
    await tester.pumpAndSettle();

    expect(find.text('Streak'), findsOneWidget);
    expect(find.text('Общо дни'), findsOneWidget);
  });
}