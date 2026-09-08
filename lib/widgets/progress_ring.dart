import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Пръстен с процент в средата.
class ProgressRing extends StatelessWidget {
  /// От 0.0 до 1.0.
  final double value;

  final String label;
  final double size;

  const ProgressRing({
    super.key,
    required this.value,
    required this.label,
    this.size = 84,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOut,
        tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
        builder: (context, animated, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: animated,
                  strokeWidth: 7,
                  strokeCap: StrokeCap.round,
                  backgroundColor: AppColors.track,
                  valueColor: AlwaysStoppedAnimation(AppColors.accent),
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: size * 0.24,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
