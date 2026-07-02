// presentation/thix_sante/pharmacy/details/pharmacy_prescriptions_report_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class PharmacyPrescriptionsReportPage extends StatefulWidget {
  const PharmacyPrescriptionsReportPage({super.key});

  @override
  State<PharmacyPrescriptionsReportPage> createState() => _PharmacyPrescriptionsReportPageState();
}

class _PharmacyPrescriptionsReportPageState extends State<PharmacyPrescriptionsReportPage> {
  String _filter = 'Toutes';
  final List<String> _filterOptions = ['Toutes', 'Actives', 'Expirées', 'Validées'];

  final List<Map<String, dynamic>> _prescriptions = [
    {'medicament': 'Paracétamol', 'quantite': 45, 'status': 'Validée', 'date': '10/03/2024'},
    {'medicament': 'Amoxicilline', 'quantite': 30, 'status': 'Active', 'date': '08/03/2024'},
    {'medicament': 'Ibuprofène', 'quantite': 20, 'status': 'Expirée', 'date': '01/03/2024'},
  ];

  List<Map<String, dynamic>> get _filteredData {
    if (_filter == 'Toutes') return _prescriptions;
    return _prescriptions.where((p) => p['status'] == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredData;
    final total = filtered.fold<int>(0, (sum, item) => sum + (item['quantite'] as int));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Rapport prescriptions'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.orange.shade800,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Export PDF (simulé)')),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _filterOptions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final label = _filterOptions[index];
                  return FilterChip(
                    label: Text(label),
                    selected: _filter == label,
                    onSelected: (_) => setState(() => _filter = label),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statColumn('Total prescriptions', filtered.length.toString()),
                    _statColumn('Médicaments prescrits', total.toString()),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final p = filtered[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(p['medicament']!),
                      subtitle: Text('Quantité : ${p['quantite']} • ${p['date']}'),
                      trailing: Chip(label: Text(p['status']!), backgroundColor: _getStatusColor(p['status']!)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statColumn(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Validée':
        return Colors.green.shade100;
      case 'Active':
        return Colors.blue.shade100;
      case 'Expirée':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade100;
    }
  }
}
