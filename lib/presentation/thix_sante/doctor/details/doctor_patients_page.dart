// presentation/thix_sante/doctor/details/doctor_patients_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/presentation/thix_sante/shared/models/health_models.dart';

class DoctorPatientsPage extends StatefulWidget {
  const DoctorPatientsPage({super.key});

  @override
  State<DoctorPatientsPage> createState() => _DoctorPatientsPageState();
}

class _DoctorPatientsPageState extends State<DoctorPatientsPage> {
  final List<Doctor> _patients = [
    Doctor(id: 'p1', firstName: 'Michel', lastName: 'L.', specialty: '', phone: '0601020304'),
    Doctor(id: 'p2', firstName: 'Sophie', lastName: 'M.', specialty: '', phone: '0602030405'),
    Doctor(id: 'p3', firstName: 'Jean', lastName: 'P.', specialty: '', phone: '0603040506'),
    Doctor(id: 'p4', firstName: 'Marie', lastName: 'D.', specialty: '', phone: '0604050607'),
  ];
  List<Doctor> _filtered = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filtered = _patients;
    _searchController.addListener(_filterPatients);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterPatients);
    _searchController.dispose();
    super.dispose();
  }

  void _filterPatients() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filtered = _patients.where((p) =>
          p.firstName.toLowerCase().contains(query) ||
          p.lastName.toLowerCase().contains(query) ||
          (p.phone?.contains(query) ?? false)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes patients'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              context.push('/sante/doctor/patient/new');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Rechercher un patient...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _filtered.length,
              itemBuilder: (context, index) {
                final p = _filtered[index];
                return Card(
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(child: Text(p.firstName[0])),
                    title: Text('${p.firstName} ${p.lastName}'),
                    subtitle: Text(p.phone ?? ''),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      context.push('/sante/doctor/patient/${p.id}', extra: p);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
