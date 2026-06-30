// presentation/thix_sante/doctor/doctor_care_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/presentation/thix_sante/shared/models/health_models.dart';
import 'package:thix_id/presentation/thix_sante/shared/widgets/health_bottom_nav.dart';

class DoctorCarePage extends StatefulWidget {
  const DoctorCarePage({super.key});

  @override
  State<DoctorCarePage> createState() => _DoctorCarePageState();
}

class _DoctorCarePageState extends State<DoctorCarePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Doctor> _patients = [];
  Doctor? _selectedPatient;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() {
    _patients = [
      Doctor(id: 'p1', firstName: 'Michel', lastName: 'L.', specialty: '', phone: '0601020304'),
      Doctor(id: 'p2', firstName: 'Sophie', lastName: 'M.', specialty: '', phone: '0602030405'),
      Doctor(id: 'p3', firstName: 'Jean', lastName: 'P.', specialty: '', phone: '0603040506'),
      Doctor(id: 'p4', firstName: 'Marie', lastName: 'D.', specialty: '', phone: '0604050607'),
    ];
    if (_patients.isNotEmpty) _selectedPatient = _patients.first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Soins médecins'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Patients'),
            Tab(icon: Icon(Icons.person), text: 'Détail patient'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              context.push('/sante/doctor/patients');
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPatientsList(),
          _buildPatientDetail(),
        ],
      ),
      bottomNavigationBar: HealthBottomNav(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            context.go('/sante');
          } else if (index == 2) {
            _showQuickAction(context);
          } else if (index == 3) {
            context.go('/sante/doctor/connect');
          } else if (index == 4) {
            context.go('/sante/doctor/profile');
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            context.push('/sante/doctor/patient/new');
          } else {
            context.push('/sante/doctor/prescription/new', extra: _selectedPatient);
          }
        },
        child: Icon(_tabController.index == 0 ? Icons.person_add : Icons.receipt),
      ),
    );
  }

  Widget _buildPatientsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _patients.length,
      itemBuilder: (context, index) {
        final patient = _patients[index];
        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Text(patient.firstName[0]),
            ),
            title: Text('${patient.firstName} ${patient.lastName}'),
            subtitle: Text(patient.phone ?? ''),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              setState(() {
                _selectedPatient = patient;
                _tabController.animateTo(1);
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildPatientDetail() {
    if (_selectedPatient == null) {
      return const Center(child: Text('Sélectionnez un patient dans la liste.'));
    }
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blue,
                  child: Text(
                    _selectedPatient!.firstName[0],
                    style: const TextStyle(fontSize: 24, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_selectedPatient!.firstName} ${_selectedPatient!.lastName}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text('ID: ${_selectedPatient!.id} • ${_selectedPatient!.phone ?? ''}'),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    // Modifier patient
                  },
                ),
              ],
            ),
          ),
          const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.receipt), text: 'Prescriptions'),
              Tab(icon: Icon(Icons.note), text: 'Notes'),
              Tab(icon: Icon(Icons.show_chart), text: 'Graphiques'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildPrescriptionsTab(),
                _buildNotesTab(),
                _buildChartsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ElevatedButton.icon(
          onPressed: () {
            context.push('/sante/doctor/prescription/new', extra: _selectedPatient);
          },
          icon: const Icon(Icons.add),
          label: const Text('Nouvelle prescription électronique'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
        ),
        const SizedBox(height: 16),
        const Text('Historique des prescriptions', style: TextStyle(fontWeight: FontWeight.bold)),
        ListTile(
          leading: const Icon(Icons.receipt, color: Colors.green),
          title: const Text('Ordonnance du 10/03/2024'),
          subtitle: Text('Dr. ${_selectedPatient?.lastName} • 3 médicaments'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            context.push('/sante/doctor/prescription/1');
          },
        ),
        ListTile(
          leading: const Icon(Icons.receipt, color: Colors.green),
          title: const Text('Ordonnance du 25/02/2024'),
          subtitle: Text('Dr. ${_selectedPatient?.lastName} • 2 médicaments'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            context.push('/sante/doctor/prescription/2');
          },
        ),
      ],
    );
  }

  Widget _buildNotesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ElevatedButton.icon(
          onPressed: () {
            context.push('/sante/doctor/note/new');
          },
          icon: const Icon(Icons.add),
          label: const Text('Ajouter une note médicale'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
        ),
        const SizedBox(height: 16),
        const Text('Notes récentes', style: TextStyle(fontWeight: FontWeight.bold)),
        Card(
          child: ListTile(
            title: const Text('Consultation du 10/03'),
            subtitle: const Text('Patient présentant une douleur thoracique...'),
            trailing: const Icon(Icons.more_vert),
            onTap: () {
              context.push('/sante/doctor/note/1');
            },
          ),
        ),
        Card(
          child: ListTile(
            title: const Text('Suivi traitement'),
            subtitle: const Text('Amélioration constatée, dosage réduit...'),
            trailing: const Icon(Icons.more_vert),
            onTap: () {
              context.push('/sante/doctor/note/2');
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChartsTab() {
    return const Center(
      child: Text('Graphiques des constantes (à implémenter avec doctor_statistics_page)'),
    );
  }

  void _showQuickAction(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.person_add, color: Colors.blue),
              title: const Text('Nouveau patient'),
              onTap: () {
                Navigator.pop(context);
                context.push('/sante/doctor/patient/new');
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt, color: Colors.green),
              title: const Text('Nouvelle prescription'),
              onTap: () {
                Navigator.pop(context);
                context.push('/sante/doctor/prescription/new');
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam, color: Colors.purple),
              title: const Text('Téléconsultation'),
              onTap: () {
                Navigator.pop(context);
                context.push('/sante/doctor/teleconsult');
              },
            ),
          ],
        ),
      ),
    );
  }
}
