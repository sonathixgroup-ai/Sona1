// presentation/thix_sante/doctor/details/doctor_teleexpertise_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DoctorTeleexpertisePage extends StatefulWidget {
  final String? requestId;
  const DoctorTeleexpertisePage({super.key, this.requestId});

  @override
  State<DoctorTeleexpertisePage> createState() => _DoctorTeleexpertisePageState();
}

class _DoctorTeleexpertisePageState extends State<DoctorTeleexpertisePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<Map<String, dynamic>> _requests = [
    {'id': 'e1', 'doctorName': 'Dr. Martin', 'specialty': 'Cardiologue', 'patientName': 'Marie D.', 'date': '02/03', 'status': 'En attente'},
    {'id': 'e2', 'doctorName': 'Dr. Bernard', 'specialty': 'Dermatologue', 'patientName': 'Luc R.', 'date': '28/02', 'status': 'Répondu'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _newRequest() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Demande de téléexpertise envoyée (simulé)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Téléexpertise'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'En attente'),
            Tab(text: 'Répondu'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList(_requests.where((r) => r['status'] == 'En attente').toList()),
          _buildList(_requests.where((r) => r['status'] == 'Répondu').toList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _newRequest,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return const Center(child: Text('Aucune demande.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final r = items[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.medical_services), backgroundColor: Colors.orange),
            title: Text(r['doctorName']),
            subtitle: Text('${r['patientName']} • ${r['specialty']} • ${r['date']}'),
            trailing: Chip(label: Text(r['status']), backgroundColor: Colors.orange),
            onTap: () {
              context.push('/sante/doctor/teleexpertise/${r['id']}');
            },
          ),
        );
      },
    );
  }
}
