import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:streakly/main.dart';

void main() {
  testWidgets('Streakly app зарежда без грешки', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const HabitTrackerApp());
    await tester.pumpAndSettle();

    // MaterialApp-ът има title 'Streakly'.
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.title, 'Streakly');
  });
}
