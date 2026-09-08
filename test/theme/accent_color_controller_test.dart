import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streakly/theme/accent_color_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const amber = Color(0xFFF5A623);
  const oldPurple = Color(0xFFBB86FC);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AccentColorController.instance.notifier.value =
        AccentColorController.options.first.color;
  });

  test('кехлибарът е първата опция и подразбиращ се цвят', () {
    expect(AccentColorController.options.first.color, amber);
  });

  test('лилавото вече не е сред опциите', () {
    expect(
      AccentColorController.options.any((o) => o.color == oldPurple),
      false,
    );
  });

  test('запазен познат цвят се зарежда както е', () async {
    final blue = AccentColorController.options[2].color;

    SharedPreferences.setMockInitialValues({
      'accent_color_value': blue.toARGB32(),
    });

    await AccentColorController.instance.load();

    expect(AccentColorController.instance.notifier.value, blue);
  });

  test('премахнат цвят пада обратно към кехлибар и се записва', () async {
    SharedPreferences.setMockInitialValues({
      'accent_color_value': oldPurple.toARGB32(),
    });

    await AccentColorController.instance.load();

    expect(AccentColorController.instance.notifier.value, amber);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('accent_color_value'), amber.toARGB32());
  });
}
