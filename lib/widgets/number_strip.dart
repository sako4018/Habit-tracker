import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class StripNumber {
  final String value;
  final String label;

  /// Първото число в лента обикновено е акцентирано.
  final bool highlighted;

  const StripNumber({
    required this.value,
    required this.label,
    this.highlighted = false,
  });
}

/// Лента от няколко числа, разделени с тънки линии.
class NumberStrip extends StatelessWidget {
  final List<StripNumber> numbers;

  const NumberStrip({
    super.key,
    required this.numbers,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (var i = 0; i < numbers.length; i++) ...[
              if (i > 0)
                const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: AppColors.border,
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 8,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        numbers[i].value,
                        style: TextStyle(
                          color: numbers[i].highlighted
                              ? AppColors.accent
                              : AppColors.textPrimary,
                          fontSize: 23,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        numbers[i].label.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
