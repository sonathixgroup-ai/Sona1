// presentation/thix_sante/pharmacy/details/pharmacy_dispensing_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PharmacyDispensingPage extends StatefulWidget {
  final String? dispensingId;
  const PharmacyDispensingPage({super.key, this.dispensingId});

  @override
  State<PharmacyDispensingPage> createState() => _PharmacyDispensingPageState();
}

class _PharmacyDispensingPageState extends State<PharmacyDispensingPage> {
  final List<Map<String, dynamic>> _dispensations = [
    {'id': 'd1', 'patient': 'Michel L.', 'medications': 'Paracétamol, Amoxicilline', 'status': 'À dispenser'},
    {'id': 'd2', 'patient': 'Sophie M.', 'medications': 'Ibuprofène', 'status': 'Dispensé'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dispensation')),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _dispensations.length,
        itemBuilder: (context, index) {
          final item = _dispensations[index];
          return Card(
            elevation: 1,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: item['status'] == 'Dispensé' ? Colors.green : Colors.orange,
                child: Text((item['patient'] as String)[0], style: const TextStyle(color: Colors.white)),
              ),
              title: Text(item['patient'] as String),
              subtitle: Text(item['medications'] as String),
              trailing: Chip(
                label: Text(item['status'] as String),
                backgroundColor: item['status'] == 'Dispensé' ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
              ),
              onTap: () {
                // Attribuer au patient (simulé)
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Dispensation pour ${item['patient']} (simulé)')),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Nouvelle dispensation
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nouvelle dispensation (simulé)')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
