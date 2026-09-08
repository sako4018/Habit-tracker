import 'package:flutter/material.dart';

import 'accent_color_controller.dart';

class AppColors {
  static const background = Color(0xFF121212);

  static const surface = Color(0xFF1E1E1E);

  /// Вече НЕ е const — чете се динамично от AccentColorController,
  /// за да може потребителят да сменя акцентния цвят от Settings.
  static Color get accent =>
      AccentColorController.instance.notifier.value;
}