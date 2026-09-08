import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class HeatmapLegend extends StatelessWidget {
  const HeatmapLegend({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const Text(
          'По-малко',
          style: TextStyle(
            color: AppColors.textFaint,
            fontSize: 10,
          ),
        ),

        const SizedBox(width: 6),

        ...AppColors.heatmapLevels.map(
          (color) {
            return Padding(
              padding: const EdgeInsets.only(left: 3),
              child: Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            );
          },
        ),

        const SizedBox(width: 6),

        const Text(
          'Повече',
          style: TextStyle(
            color: AppColors.textFaint,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
