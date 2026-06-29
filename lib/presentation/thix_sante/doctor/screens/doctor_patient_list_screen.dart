// 📁 lib/presentation/thix_sante/doctor/screens/doctor_patient_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/patient_list_tile.dart';
import '../../../common/widgets/search_bar.dart';
import '../../../common/widgets/empty_state.dart';

class DoctorPatientListScreen extends ConsumerStatefulWidget {
  const DoctorPatientListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DoctorPatientListScreen> createState() => _DoctorPatientListScreenState();
}

class _DoctorPatientListScreenState extends ConsumerState<DoctorPatientListScreen> {
  final List<Map<String, dynamic>> _patients = [
    {'name': 'Michel Dupont', 'email': 'michel@email.com', 'birthDate': '15/03/1985', 'bloodType': 'A+', 'unread': 2, 'hasAlert': true},
    {'name': 'Sophie Martin', 'email': 'sophie@email.com', 'birthDate': '22/07/1990', 'bloodType': 'O-', 'unread': 0, 'hasAlert': false},
    {'name': 'Lucas Bernard', 'email': 'lucas@email.com', 'birthDate': '10/11/1978', 'bloodType': 'B+', 'unread': 1, 'hasAlert': false},
    {'name': 'Julie Petit', 'email': 'julie@email.com', 'birthDate': '05/09/1995', 'bloodType': 'AB+', 'unread': 0, 'hasAlert': true},
  ];

  List<Map<String, dynamic>> _filteredPatients = [];

  @override
  void initState() {
    super.initState();
    _filteredPatients = _patients;
  }

  void _search(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredPatients = _patients;
      } else {
        _filteredPatients = _patients.where((p) =>
          p['name'].toLowerCase().contains(query.toLowerCase()) ||
          p['email'].toLowerCase().contains(query.toLowerCase())
        ).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes patients'),
        actions: [
          IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          CustomSearchBar(
            onSearch: _search,
            hintText: 'Rechercher un patient...',
          ),
          Expanded(
            child: _filteredPatients.isEmpty
                ? const EmptyStateWidget(
                    title: 'Aucun patient trouvé',
                    icon: Icons.people_outline,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _filteredPatients.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final p = _filteredPatients[index];
                      return PatientListTile(
                        patient: PatientModel(
                          id: 'p${index+1}',
                          name: p['name'],
                          email: p['email'],
                          birthDate: p['birthDate'],
                          bloodType: p['bloodType'],
                        ),
                        unreadMessages: p['unread'],
                        hasAlert: p['hasAlert'],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DoctorPatientDetailScreen(patientId: 'p${index+1}'),
                            ),
                          );
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
