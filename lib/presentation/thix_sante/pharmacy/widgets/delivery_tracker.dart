// 📁 lib/presentation/thix_sante/pharmacy/widgets/delivery_tracker.dart

import 'package:flutter/material.dart';
import '../../../common/widgets/pill_badge.dart';

class DeliveryTracker extends StatelessWidget {
  final String orderId;
  final String patientName;
  final String address;
  final String status; // pending, preparing, in_transit, delivered
  final DateTime estimatedDelivery;
  final VoidCallback onTrack;

  const DeliveryTracker({
    Key? key,
    required this.orderId,
    required this.patientName,
    required this.address,
    required this.status,
    required this.estimatedDelivery,
    required this.onTrack,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final steps = ['Préparation', 'En transit', 'Livré'];
    int currentStep = 0;
    if (status == 'preparing') currentStep = 0;
    else if (status == 'in_transit') currentStep = 1;
    else if (status == 'delivered') currentStep = 2;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.delivery_dining, size: 20, color: Colors.purple),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Livraison #$orderId',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      patientName,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              PillBadge(
                text: status == 'delivered' ? 'Livré' : 'En cours',
                color: status == 'delivered' ? Colors.green : Colors.blue,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.location_on, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  address,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Timeline
          Row(
            children: steps.asMap().entries.map((entry) {
              final index = entry.key;
              final label = entry.value;
              final isActive = index <= currentStep;
              final isLast = index == steps.length - 1;

              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isActive ? Colors.green : Colors.grey.shade200,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isActive ? Icons.check : Icons.circle,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 9,
                              color: isActive ? Colors.green : Colors.grey.shade400,
                              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: index < currentStep ? Colors.green : Colors.grey.shade200,
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.access_time, size: 12, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(
                'Livraison estimée: ${estimatedDelivery.day}/${estimatedDelivery.month}/${estimatedDelivery.year}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
              const Spacer(),
              TextButton(
                onPressed: onTrack,
                child: const Text('Suivre', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
