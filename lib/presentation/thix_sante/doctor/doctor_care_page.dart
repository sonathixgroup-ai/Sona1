// presentation/thix_sante/doctor/doctor_care_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/presentation/thix_sante/shared/models/health_models.dart';
import 'package:thix_id/presentation/thix_sante/shared/widgets/health_bottom_nav.dart';
import 'package:charts_flutter/flutter.dart' as charts;

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

  // Données mockées
  final List<PatientDetail> _patientDetails = [];

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
    // Simuler une liste de patients
    _patients = [
      Doctor(id: 'p1', firstName: 'Michel', lastName: 'L.', specialty: '', phone: '0601020304'),
      Doctor(id: 'p2', firstName: 'Sophie', lastName: 'M.', specialty: '', phone: '0602030405'),
      Doctor(id: 'p3', firstName: 'Jean', lastName: 'P.', specialty: '', phone: '0603040506'),
      Doctor(id: 'p4', firstName: 'Marie', lastName: 'D.', specialty: '', phone: '0604050607'),
    ];
    // Sélectionner le premier patient par défaut
    if (_patients.isNotEmpty) {
      _selectedPatient = _patients.first;
    }
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
              // Recherche de patient
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
        currentIndex: 1, // onglet "Santé"
        onTap: (index) {
          if (index == 0) {
            context.go('/sante');
          } else if (index == 2) {
            _showQuickAction(context);
          } else if (index == 3) {
            context.go('/sante/doctor/messages');
          } else if (index == 4) {
            context.go('/sante/doctor/profile');
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            // Ajouter un patient
            context.push('/sante/doctor/patient/new');
          } else {
            // Prescription électronique
            context.push('/sante/doctor/prescription/new', extra: _selectedPatient);
          }
        },
        child: Icon(_tabController.index == 0 ? Icons.person_add : Icons.receipt),
      ),
    );
  }

  // ============================================================
  // 1. LISTE PATIENTS
  // ============================================================
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

  // ============================================================
  // 2. DÉTAIL PATIENT (avec prescription, notes, graphiques)
  // ============================================================
  Widget _buildPatientDetail() {
    if (_selectedPatient == null) {
      return const Center(child: Text('Sélectionnez un patient dans la liste.'));
    }
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          // En-tête patient
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
          // Onglets Prescription / Notes / Graphiques
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

  // ----- Prescriptions électroniques -----
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
        ...List.generate(2, (index) => ListTile(
          leading: const Icon(Icons.receipt, color: Colors.green),
          title: Text('Ordonnance du ${DateTime.now().subtract(Duration(days: index * 5)).day}/${DateTime.now().month}/${DateTime.now().year}'),
          subtitle: Text('Dr. ${_selectedPatient?.lastName} • 3 médicaments'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            // Voir l'ordonnance
          },
        )),
      ],
    );
  }

  // ----- Notes médicales -----
  Widget _buildNotesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ElevatedButton.icon(
          onPressed: () {
            _showAddNoteDialog();
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
              // Voir la note
            },
          ),
        ),
        Card(
          child: ListTile(
            title: const Text('Suivi traitement'),
            subtitle: const Text('Amélioration constatée, dosage réduit...'),
            trailing: const Icon(Icons.more_vert),
            onTap: () {
              // Voir la note
            },
          ),
        ),
      ],
    );
  }

  // ----- Graphiques des constantes -----
  Widget _buildChartsTab() {
    // Données simulées pour le graphique de tension
    final data = [
      charts.Series<Map<String, dynamic>, int>(
        id: 'Tension',
        colorFn: (_, __) => charts.ColorUtil.fromDartColor(Colors.blue),
        domainFn: (datum, _) => datum['day'] as int,
        measureFn: (datum, _) => datum['systolic'] as int,
        data: [
          {'day': 1, 'systolic': 130},
          {'day': 2, 'systolic': 125},
          {'day': 3, 'systolic': 140},
          {'day': 4, 'systolic': 135},
          {'day': 5, 'systolic': 120},
          {'day': 6, 'systolic': 128},
          {'day': 7, 'systolic': 132},
        ],
      ),
      charts.Series<Map<String, dynamic>, int>(
        id: 'Diastolique',
        colorFn: (_, __) => charts.ColorUtil.fromDartColor(Colors.red),
        domainFn: (datum, _) => datum['day'] as int,
        measureFn: (datum, _) => datum['diastolic'] as int,
        data: [
          {'day': 1, 'diastolic': 85},
          {'day': 2, 'diastolic': 80},
          {'day': 3, 'diastolic': 90},
          {'day': 4, 'diastolic': 88},
          {'day': 5, 'diastolic': 78},
          {'day': 6, 'diastolic': 82},
          {'day': 7, 'diastolic': 85},
        ],
      ),
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text('Évolution de la tension artérielle', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: charts.LineChart(
              data,
              animate: true,
              defaultRenderer: charts.LineRendererConfig(includePoints: true),
              behaviors: [charts.ChartTitle('Jour', behaviorPosition: charts.BehaviorPosition.bottom)],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Dernières constantes', style: TextStyle(fontWeight: FontWeight.bold)),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _vitalRow('Tension', '130/85 mmHg'),
                  _vitalRow('Fréquence cardiaque', '72 bpm'),
                  _vitalRow('Poids', '72.5 kg'),
                  _vitalRow('IMC', '24.5'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _vitalRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ============================================================
  // DIALOGUES
  // ============================================================
  void _showAddNoteDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter une note médicale'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Rédigez votre note ici...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              // Sauvegarder la note
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Note ajoutée avec succès')),
              );
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
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
                context.push('/sante/doctor/teleconsultation/new');
              },
            ),
          ],
        ),
      ),
    );
  }
}
