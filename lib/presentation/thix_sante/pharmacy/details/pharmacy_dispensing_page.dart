// presentation/thix_sante/pharmacy/details/pharmacy_dispensing_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class PharmacyDispensingPage extends StatelessWidget {
  const PharmacyDispensingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dispensations = [
      {'id': 'd1', 'patient': 'Michel L.', 'medications': 'Paracétamol, Amoxicilline', 'status': 'À dispenser'},
      {'id': 'd2', 'patient': 'Sophie M.', 'medications': 'Ibuprofène', 'status': 'Dispensé'},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Dispensation'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.orange.shade800,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: dispensations.length,
        itemBuilder: (context, index) {
          final d = dispensations[index];
          final isDispensed = d['status'] == 'Dispensé';
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
                CircleAvatar(
                  backgroundColor: isDispensed ? Colors.green : Colors.orange,
                  child: Text(
                    (d['patient'] as String).substring(0, 1),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d['patient'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        d['medications'] as String,
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
                    color: isDispensed ? Colors.green.withOpacity(0.15) : Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    d['status'] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDispensed ? Colors.green : Colors.orange,
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
        onPressed: () => context.push('/sante/pharmacy/dispensing/detail'),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
