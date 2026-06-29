// 📁 lib/presentation/thix_sante/pharmacy/widgets/stock_level_indicator.dart

import 'package:flutter/material.dart';

class StockLevelIndicator extends StatelessWidget {
  final int quantity;
  final int threshold;
  final double? width;

  const StockLevelIndicator({
    Key? key,
    required this.quantity,
    required this.threshold,
    this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final maxQuantity = (threshold * 3).toDouble();
    final percentage = (quantity / maxQuantity).clamp(0.0, 1.0);

    Color color;
    if (percentage < 0.3) {
      color = Colors.red;
    } else if (percentage < 0.6) {
      color = Colors.orange;
    } else {
      color = Colors.green;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: width ?? 60,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            widthFactor: percentage,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${(percentage * 100).toInt()}%',
          style: TextStyle(
            fontSize: 9,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }
}
