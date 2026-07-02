// presentation/thix_sante/pharmacy/details/pharmacy_report_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class PharmacyReportPage extends StatelessWidget {
  const PharmacyReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Rapports'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.orange.shade800,
        actions: [
          IconButton(
            icon: const Icon(Icons.generating_tokens),
            onPressed: () => context.push('/sante/pharmacy/report/generate'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _reportTile('Chiffre d\'affaires', '1 250 €', Colors.green),
            _reportTile('Commandes', '45', Colors.blue),
            _reportTile('Prescriptions', '120', Colors.purple),
          ],
        ),
      ),
    );
  }

  Widget _reportTile(String title, String value, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        ],
      ),
    );
  }
}
