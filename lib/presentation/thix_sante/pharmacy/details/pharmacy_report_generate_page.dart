// presentation/thix_sante/pharmacy/details/pharmacy_report_generate_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class PharmacyReportGeneratePage extends StatefulWidget {
  const PharmacyReportGeneratePage({super.key});

  @override
  State<PharmacyReportGeneratePage> createState() => _PharmacyReportGeneratePageState();
}

class _PharmacyReportGeneratePageState extends State<PharmacyReportGeneratePage> {
  String _reportType = 'Commandes';
  final List<String> _types = ['Commandes', 'Prescriptions', 'Chiffre d\'affaires'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Générer un rapport'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.orange.shade800,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Type de rapport',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._types.map((type) => RadioListTile<String>(
                  title: Text(type),
                  value: type,
                  groupValue: _reportType,
                  onChanged: (value) => setState(() => _reportType = value!),
                )),
            const SizedBox(height: 16),
            const Text(
              'Période',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    child: const Text('Début'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    child: const Text('Fin'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Rapport généré (simulé)'), backgroundColor: Colors.green),
                );
                context.pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Générer le rapport'),
            ),
          ],
        ),
      ),
    );
  }
}
