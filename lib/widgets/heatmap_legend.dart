import 'package:flutter/material.dart';

import 'contribution_heatmap.dart';

class HeatmapLegend extends StatelessWidget {
  const HeatmapLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'По-малко',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade500,
          ),
        ),

        const SizedBox(width: 6),

        ...ContributionHeatmap.levels.map(
          (color) => Container(
            width: 11,
            height: 11,
            margin: const EdgeInsets.symmetric(
              horizontal: 1.5,
            ),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),

        const SizedBox(width: 6),

        Text(
          'Повече',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }
}