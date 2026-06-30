// presentation/thix_sante/patient/details/patient_map_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PatientMapPage extends StatefulWidget {
  final String type; // 'emergencies', 'pharmacies', 'hospitals'
  const PatientMapPage({super.key, required this.type});

  @override
  State<PatientMapPage> createState() => _PatientMapPageState();
}

class _PatientMapPageState extends State<PatientMapPage> {
  @override
  Widget build(BuildContext context) {
    String title;
    IconData icon;
    Color color;
    switch (widget.type) {
      case 'pharmacies':
        title = 'Pharmacies proches';
        icon = Icons.local_pharmacy;
        color = Colors.green;
        break;
      case 'hospitals':
        title = 'Hôpitaux proches';
        icon = Icons.local_hospital;
        color = Colors.blue;
        break;
      default:
        title = 'Urgences proches';
        icon = Icons.emergency;
        color = Colors.red;
    }

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          // Simulation de carte
          Container(
            height: 250,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('Carte interactive (simulation)'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Liste des établissements', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 3,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: Icon(icon, color: color),
                  title: Text('Établissement ${index + 1}'),
                  subtitle: const Text('1 Rue de la Santé'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    if (widget.type == 'pharmacies') {
                      context.push('/sante/patient/map/pharmacy/${index + 1}');
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
