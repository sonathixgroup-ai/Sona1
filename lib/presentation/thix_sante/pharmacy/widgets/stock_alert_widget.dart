// 📁 lib/presentation/thix_sante/pharmacy/widgets/stock_alert_widget.dart

import 'package:flutter/material.dart';
import '../../../common/widgets/gradient_button.dart';

class StockAlertWidget extends StatelessWidget {
  final String drugName;
  final String dosage;
  final int currentQuantity;
  final int threshold;
  final VoidCallback onReorder;
  final VoidCallback? onDismiss;

  const StockAlertWidget({
    Key? key,
    required this.drugName,
    required this.dosage,
    required this.currentQuantity,
    required this.threshold,
    required this.onReorder,
    this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isCritical = currentQuantity <= threshold * 0.5;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCritical ? Colors.red.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCritical ? Colors.red.shade200 : Colors.orange.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCritical ? Icons.warning_amber : Icons.info_outline,
                color: isCritical ? Colors.red : Colors.orange,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⚠️ Stock ${isCritical ? 'critique' : 'faible'}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isCritical ? Colors.red : Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$drugName - $dosage',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (onDismiss != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onDismiss,
                  color: Colors.grey.shade500,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Stock: $currentQuantity unités',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isCritical ? Colors.red : Colors.orange,
                  ),
                ),
              ),
              const Spacer(),
              GradientButton(
                text: 'Réapprovisionner',
                onPressed: onReorder,
                gradient: LinearGradient(
                  colors: isCritical
                      ? [Colors.red, Colors.redAccent]
                      : [Colors.orange, Colors.orangeAccent],
                ),
                width: 140,
                height: 34,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
