import 'package:flutter_test/flutter_test.dart';

import 'package:streakly/main.dart';

void main() {
  testWidgets('Streakly app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const HabitTrackerApp());

    expect(find.text('Streakly'), findsOneWidget);
  });
}
