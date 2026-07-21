// 📁 lib/presentation/chat/widgets/sentiment_indicator.dart

import 'package:flutter/material.dart';
import '../../../models/chat/sentiment.dart';

class SentimentIndicator extends StatelessWidget {
  final SentimentResult? result;
  final bool showLabel;
  final double size;

  const SentimentIndicator({
    super.key,
    required this.result,
    this.showLabel = true,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    if (result == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: result!.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: result!.color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            result!.icon,
            color: result!.color,
            size: size,
          ),
          if (showLabel) ...[
            const SizedBox(width: 4),
            Text(
              result!.labelFr,
              style: TextStyle(
                color: result!.color,
                fontSize: size * 0.6,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
