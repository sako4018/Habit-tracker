import 'package:flutter/material.dart';

import 'accent_color_controller.dart';

class AppColors {
  static const background = Color(0xFF121212);

  static const surface = Color(0xFF1E1E1E);

  /// Ръб на карта — по-светъл от повърхността, за да се отделя.
  static const border = Color(0xFF262626);

  // ---------------------------------------------------------------------
  // Текст
  //
  // Стойностите са избрани така, че всяко ниво да минава 4.5:1 върху
  // [background]. Старите Colors.grey.shade500/600 падаха под 3.6:1 и
  // на телефон практически не се четяха.
  // ---------------------------------------------------------------------

  /// Заглавия и основен текст.
  static const textPrimary = Color(0xFFFFFFFF);

  /// Подзаглавия и стойности до основния текст.
  static const textSecondary = Color(0xFFB0B0B0);

  /// Помощен текст: етикети, дати, брояч под името.
  static const textMuted = Color(0xFF9A9A9A);

  /// Най-тихото ниво, което още е текст за четене.
  static const textFaint = Color(0xFF8F8F8F);

  /// Неактивно състояние (бъдещ ден, празен чекбокс) — не е текст за
  /// четене, затова умишлено стои под прага за контраст.
  static const inactive = Color(0xFF5C5C5C);

  /// Вече НЕ е const — чете се динамично от AccentColorController,
  /// за да може потребителят да сменя акцентния цвят от Settings.
  static Color get accent =>
      AccentColorController.instance.notifier.value;

  /// Стълбица за heatmap-а: от празен ден до пълен, тонирана с
  /// акцентния цвят, за да върви със смяната му.
  static List<Color> get heatmapLevels => [
        const Color(0xFF242424),
        accent.withValues(alpha: 0.24),
        accent.withValues(alpha: 0.45),
        accent.withValues(alpha: 0.70),
        accent,
      ];
}
