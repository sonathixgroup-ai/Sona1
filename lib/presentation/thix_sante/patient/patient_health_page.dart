// presentation/thix_sante/patient/patient_health_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/presentation/thix_sante/shared/services/health_services.dart';
import 'package:thix_id/presentation/thix_sante/shared/models/health_models.dart';
import 'package:thix_id/presentation/thix_sante/shared/widgets/health_bottom_nav.dart';

class PatientHealthPage extends StatefulWidget {
  const PatientHealthPage({super.key});

  @override
  State<PatientHealthPage> createState() => _PatientHealthPageState();
}

class _PatientHealthPageState extends State<PatientHealthPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final HealthService _healthService = HealthService.instance;

  List<Symptom> _symptoms = [];
  List<VitalSign> _vitals = [];
  List<Medication> _medications = [];
  List<Vaccine> _vaccines = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      const patientId = 'patient-123';
      final results = await Future.wait([
        _healthService.fetchSymptoms(patientId),
        _healthService.fetchVitalSigns(patientId),
        _healthService.fetchMedications(patientId, activeOnly: false),
        _healthService.fetchVaccines(patientId),
      ]);
      setState(() {
        _symptoms = results[0] as List<Symptom>;
        _vitals = results[1] as List<VitalSign>;
        _medications = results[2] as List<Medication>;
        _vaccines = results[3] as List<Vaccine>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suivi santé'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.sick), text: 'Symptômes'),
            Tab(icon: Icon(Icons.favorite), text: 'Constantes'),
            Tab(icon: Icon(Icons.medication), text: 'Médicaments'),
            Tab(icon: Icon(Icons.vaccines), text: 'Vaccins'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showAddDialog(_tabController.index);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAllData,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSymptomsTab(),
                  _buildVitalsTab(),
                  _buildMedicationsTab(),
                  _buildVaccinesTab(),
                ],
              ),
            ),
      bottomNavigationBar: HealthBottomNav(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            context.go('/sante');
          } else if (index == 2) {
            _showQuickAction(context);
          } else if (index == 3) {
            context.go('/sante/patient/messages');
          } else if (index == 4) {
            context.go('/sante/patient/profile');
          }
        },
      ),
    );
  }

  // ... (les méthodes _buildSymptomsTab, _buildVitalsTab, _buildMedicationsTab, _buildVaccinesTab restent identiques à avant,
  // mais les onTap doivent pointer vers les nouvelles routes)

  Widget _buildSymptomsTab() {
    if (_symptoms.isEmpty) {
      return const Center(child: Text('Aucun symptôme enregistré.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _symptoms.length,
      itemBuilder: (context, index) {
        final sym = _symptoms[index];
        return Card(
          elevation: 1,
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: sym.intensityColor,
              child: Text(sym.intensity.toString()),
            ),
            title: Text(sym.name),
            subtitle: Text(
              '${sym.date.day}/${sym.date.month}/${sym.date.year}'
              '${sym.notes != null ? ' • ${sym.notes}' : ''}',
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              context.push('/sante/patient/symptom/${sym.id}', extra: sym);
            },
          ),
        );
      },
    );
  }

  Widget _buildVitalsTab() {
    if (_vitals.isEmpty) {
      return const Center(child: Text('Aucune constante enregistrée.'));
    }
    final grouped = <VitalType, VitalSign>{};
    for (var v in _vitals) {
      if (!grouped.containsKey(v.type) || v.date.isAfter(grouped[v.type]!.date)) {
        grouped[v.type] = v;
      }
    }
    final list = grouped.values.toList()
      ..sort((a, b) => a.type.name.compareTo(b.type.name));

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final v = list[index];
        return Card(
          elevation: 1,
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: Icon(VitalSign.getVitalIcon(v.type), color: Colors.blue),
            title: Text(VitalSign.getVitalLabel(v.type)),
            subtitle: Text(
              '${v.displayValue} • ${v.date.day}/${v.date.month}/${v.date.year}',
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              context.push('/sante/patient/vital/${v.id}', extra: v);
            },
          ),
        );
      },
    );
  }

  Widget _buildMedicationsTab() {
    if (_medications.isEmpty) {
      return const Center(child: Text('Aucun médicament.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _medications.length,
      itemBuilder: (context, index) {
        final med = _medications[index];
        return Card(
          elevation: 1,
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: Icon(
              med.isActive ? Icons.check_circle : Icons.cancel,
              color: med.isActive ? Colors.green : Colors.grey,
            ),
            title: Text(med.name),
            subtitle: Text('${med.dosage} • ${med.frequency}'),
            trailing: Text(
              med.isActive ? 'En cours' : 'Terminé',
              style: TextStyle(
                color: med.isActive ? Colors.green : Colors.grey,
                fontSize: 12,
              ),
            ),
            onTap: () {
              context.push('/sante/patient/medication/${med.id}', extra: med);
            },
          ),
        );
      },
    );
  }

  Widget _buildVaccinesTab() {
    if (_vaccines.isEmpty) {
      return const Center(child: Text('Aucun vaccin enregistré.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _vaccines.length,
      itemBuilder: (context, index) {
        final vac = _vaccines[index];
        return Card(
          elevation: 1,
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: const Icon(Icons.vaccines, color: Colors.orange),
            title: Text(vac.name),
            subtitle: Text(
              'Administré le ${vac.dateAdministered.day}/${vac.dateAdministered.month}/${vac.dateAdministered.year}'
              '${vac.boosterDate != null ? ' • Rappel : ${vac.boosterDate!.day}/${vac.boosterDate!.month}/${vac.boosterDate!.year}' : ''}',
            ),
            trailing: vac.isBoosterDue
                ? const Chip(label: Text('Rappel dû'), backgroundColor: Colors.red)
                : null,
            onTap: () {
              context.push('/sante/patient/vaccine/${vac.id}', extra: vac);
            },
          ),
        );
      },
    );
  }

  void _showAddDialog(int tabIndex) {
    final titles = ['Ajouter un symptôme', 'Ajouter une constante', 'Ajouter un médicament', 'Ajouter un vaccin'];
    final icons = [Icons.sick, Icons.favorite, Icons.medication, Icons.vaccines];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(icons[tabIndex], color: Colors.blue),
              title: Text(titles[tabIndex]),
              onTap: () {
                Navigator.pop(context);
                _navigateToAddForm(tabIndex);
              },
            ),
            ListTile(
              leading: const Icon(Icons.close, color: Colors.red),
              title: const Text('Annuler'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAddForm(int tabIndex) {
    switch (tabIndex) {
      case 0:
        context.push('/sante/patient/symptom/new');
        break;
      case 1:
        context.push('/sante/patient/vital/new');
        break;
      case 2:
        context.push('/sante/patient/medication/new');
        break;
      case 3:
        context.push('/sante/patient/vaccine/new');
        break;
    }
  }

  void _showQuickAction(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.calendar_today, color: Colors.blue),
              title: const Text('Prendre un rendez-vous'),
              onTap: () {
                Navigator.pop(context);
                context.push('/sante/patient/appointment/new');
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera, color: Colors.purple),
              title: const Text('Scanner une ordonnance'),
              onTap: () {
                Navigator.pop(context);
                context.push('/sante/patient/scan');
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat, color: Colors.teal),
              title: const Text('Consulter l\'assistant IA'),
              onTap: () {
                Navigator.pop(context);
                context.push('/sante/patient/ia');
              },
            ),
          ],
        ),
      ),
    );
  }
}
