import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Малкото разредено заглавие над секция ("НАВИЦИ", "ЗАДАЧИ ЗА ДНЕС").
class SectionLabel extends StatelessWidget {
  final String text;

  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.8,
      ),
    );
  }
}
