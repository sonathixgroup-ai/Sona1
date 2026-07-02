// presentation/thix_sante/pharmacy/details/pharmacy_delivery_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class PharmacyDeliveryPage extends StatelessWidget {
  const PharmacyDeliveryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final deliveries = [
      {'id': 'd1', 'patient': 'Jean P.', 'address': '12 Rue de Paris', 'status': 'En cours'},
      {'id': 'd2', 'patient': 'Marie D.', 'address': '5 Avenue des Fleurs', 'status': 'Livrée'},
      {'id': 'd3', 'patient': 'Luc R.', 'address': '3 Rue de la Santé', 'status': 'En attente'},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Livraisons'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.orange.shade800,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: deliveries.length,
        itemBuilder: (context, index) {
          final d = deliveries[index];
          final isDelivered = d['status'] == 'Livrée';
          final isInProgress = d['status'] == 'En cours';
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  isDelivered ? Icons.check_circle : (isInProgress ? Icons.local_shipping : Icons.pending),
                  color: isDelivered ? Colors.green : (isInProgress ? Colors.blue : Colors.orange),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Patient : ${d['patient']}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        d['address'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDelivered ? Colors.green.withOpacity(0.15) : (isInProgress ? Colors.blue.withOpacity(0.15) : Colors.orange.withOpacity(0.15)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    d['status'] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDelivered ? Colors.green : (isInProgress ? Colors.blue : Colors.orange),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        onPressed: () => context.push('/sante/pharmacy/delivery/tracking'),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
