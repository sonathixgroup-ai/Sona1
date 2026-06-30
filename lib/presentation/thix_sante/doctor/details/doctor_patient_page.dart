// presentation/thix_sante/doctor/details/doctor_patient_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/presentation/thix_sante/shared/models/health_models.dart';

class DoctorPatientPage extends StatefulWidget {
  final String patientId;
  const DoctorPatientPage({super.key, required this.patientId});

  @override
  State<DoctorPatientPage> createState() => _DoctorPatientPageState();
}

class _DoctorPatientPageState extends State<DoctorPatientPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Doctor? _patient;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPatient();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadPatient() {
    // Simuler – à remplacer par HealthService
    _patient = Doctor(
      id: widget.patientId,
      firstName: 'Michel',
      lastName: 'L.',
      specialty: '',
      phone: '0601020304',
      email: 'michel@exemple.com',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_patient == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('${_patient!.firstName} ${_patient!.lastName}'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.history), text: 'Historique'),
            Tab(icon: Icon(Icons.favorite), text: 'Constantes'),
            Tab(icon: Icon(Icons.medication), text: 'Traitements'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Éditer le patient
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHistory(),
          _buildVitals(),
          _buildTreatments(),
        ],
      ),
    );
  }

  Widget _buildHistory() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Antécédents', style: TextStyle(fontWeight: FontWeight.bold)),
        const Card(child: ListTile(title: Text('Hypertension'), subtitle: Text('Diagnostiqué en 2020'))),
        const Card(child: ListTile(title: Text('Diabète type 2'), subtitle: Text('Diagnostiqué en 2021'))),
        const SizedBox(height: 16),
        const Text('Consultations récentes', style: TextStyle(fontWeight: FontWeight.bold)),
        const Card(child: ListTile(title: Text('10/03/2024'), subtitle: Text('Consultation de suivi'))),
        const Card(child: ListTile(title: Text('25/02/2024'), subtitle: Text('Prise de sang'))),
      ],
    );
  }

  Widget _buildVitals() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Dernières constantes', style: TextStyle(fontWeight: FontWeight.bold)),
        _vitalRow('Tension', '130/85 mmHg'),
        _vitalRow('Fréquence cardiaque', '72 bpm'),
        _vitalRow('Poids', '72.5 kg'),
        _vitalRow('IMC', '24.5'),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            context.push('/sante/doctor/patient/${_patient!.id}/vitals/add');
          },
          child: const Text('Ajouter une constante'),
        ),
      ],
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

  Widget _buildTreatments() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Traitements en cours', style: TextStyle(fontWeight: FontWeight.bold)),
        const Card(child: ListTile(title: Text('Paracétamol'), subtitle: Text('500 mg, 3x/jour'))),
        const Card(child: ListTile(title: Text('Amoxicilline'), subtitle: Text('250 mg, 2x/jour'))),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            context.push('/sante/doctor/prescription/new', extra: _patient);
          },
          child: const Text('Prescrire un traitement'),
        ),
      ],
    );
  }
}
