import 'package:flutter/material.dart';

import 'contribution_heatmap.dart';

class HeatmapLegend extends StatelessWidget {
  const HeatmapLegend({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.end,
      children: [
        Text(
          'По-малко',
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 10,
          ),
        ),

        const SizedBox(width: 6),

        ...ContributionHeatmap.levels.map(
          (color) {
            return Padding(
              padding:
                  const EdgeInsets.only(
                left: 3,
              ),
              child: Container(
                width: 11,
                height: 11,
                decoration:
                    BoxDecoration(
                  color: color,
                  borderRadius:
                      BorderRadius.circular(3),
                ),
              ),
            );
          },
        ),

        const SizedBox(width: 6),

        Text(
          'Повече',
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}