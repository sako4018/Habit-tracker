import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Едно предефинирано цветово поле за избор в Settings.
class AccentOption {
  final String name;
  final Color color;

  const AccentOption({
    required this.name,
    required this.color,
  });
}

/// Управлява текущия accent цвят на приложението.
/// Всеки екран, който слуша [notifier], автоматично се пребоядисва,
/// когато потребителят смени цвета от Settings.
class AccentColorController {
  AccentColorController._();

  static final AccentColorController instance =
      AccentColorController._();

  static const String _key = 'accent_color_value';

  /// Кехлибарът е новият подразбиращ се цвят. Оранжевото остава в
  /// списъка, за да не ресетнем потребители, които са го избрали —
  /// само лилавото отпадна с новия дизайн.
  static const List<AccentOption> options = [
    AccentOption(name: 'Кехлибар', color: Color(0xFFF5A623)),
    AccentOption(name: 'Жарава', color: Color(0xFFFF8A3D)),
    AccentOption(name: 'Оранжево', color: Color(0xFFFFB74D)),
    AccentOption(name: 'Синьо', color: Color(0xFF64B5F6)),
    AccentOption(name: 'Зелено', color: Color(0xFF81C784)),
    AccentOption(name: 'Червено', color: Color(0xFFE57373)),
    AccentOption(name: 'Розово', color: Color(0xFFF06292)),
  ];

  final ValueNotifier<Color> notifier =
      ValueNotifier<Color>(options.first.color);

  /// Зарежда запазения цвят от диска. Извиква се веднъж при старт.
  ///
  /// Ако запазеният цвят вече не е сред [options] (лилавото отпадна с
  /// кехлибарения дизайн), връщаме се към първия и го записваме. Иначе
  /// палитрата в Настройки не би показала нищо избрано.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final storedValue = prefs.getInt(_key);

    if (storedValue == null) {
      return;
    }

    final stored = Color(storedValue);

    final isKnown = options.any(
      (option) => option.color.toARGB32() == stored.toARGB32(),
    );

    if (isKnown) {
      notifier.value = stored;
      return;
    }

    notifier.value = options.first.color;
    await prefs.setInt(_key, options.first.color.toARGB32());
  }

  /// Задава нов accent цвят и го запазва трайно.
  Future<void> setColor(Color color) async {
    notifier.value = color;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, color.toARGB32());
  }
}