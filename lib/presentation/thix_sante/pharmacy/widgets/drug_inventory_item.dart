// 📁 lib/presentation/thix_sante/pharmacy/widgets/drug_inventory_item.dart

import 'package:flutter/material.dart';
import 'stock_level_indicator.dart';

class DrugInventoryItem extends StatelessWidget {
  final String name;
  final String dosage;
  final int quantity;
  final int threshold;
  final String? batchNumber;
  final VoidCallback onTap;
  final VoidCallback? onEdit;

  const DrugInventoryItem({
    Key? key,
    required this.name,
    required this.dosage,
    required this.quantity,
    required this.threshold,
    this.batchNumber,
    required this.onTap,
    this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isLow = quantity <= threshold;
    final isCritical = quantity <= threshold * 0.5;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isCritical ? Colors.red.shade50 : (isLow ? Colors.orange.shade50 : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isCritical ? Colors.red.shade200 : (isLow ? Colors.orange.shade200 : Colors.grey.shade100),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isCritical ? Colors.red.shade100 : (isLow ? Colors.orange.shade100 : Colors.blue.shade50),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isCritical ? Icons.warning_amber : (isLow ? Icons.info_outline : Icons.medication),
                size: 22,
                color: isCritical ? Colors.red : (isLow ? Colors.orange : Colors.blue),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dosage,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  if (batchNumber != null)
                    Text(
                      'Lot: $batchNumber',
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StockLevelIndicator(
                  quantity: quantity,
                  threshold: threshold,
                ),
                const SizedBox(height: 4),
                Text(
                  '$quantity unités',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isCritical ? Colors.red : (isLow ? Colors.orange : Colors.green),
                  ),
                ),
              ],
            ),
            if (onEdit != null) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                onPressed: onEdit,
                color: Colors.grey.shade500,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
