// presentation/thix_sante/patient/details/patient_medications_list_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/presentation/thix_sante/shared/models/health_models.dart';
import 'package:thix_id/presentation/thix_sante/shared/services/health_services.dart';

class PatientMedicationsListPage extends StatefulWidget {
  const PatientMedicationsListPage({super.key});

  @override
  State<PatientMedicationsListPage> createState() => _PatientMedicationsListPageState();
}

class _PatientMedicationsListPageState extends State<PatientMedicationsListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final HealthService _service = HealthService.instance;
  List<Medication> _medications = [];
  bool _isLoading = true;

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

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final list = await _service.fetchMedications('patient-123', activeOnly: false);
      setState(() {
        _medications = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes médicaments'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'En cours'),
            Tab(text: 'Terminés'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildList(_medications.where((m) => m.isActive).toList()),
                  _buildList(_medications.where((m) => !m.isActive).toList()),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/sante/patient/medication/new');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildList(List<Medication> items) {
    if (items.isEmpty) {
      return const Center(child: Text('Aucun médicament dans cette catégorie.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final med = items[index];
        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              med.isActive ? Icons.medication : Icons.medication_off,
              color: med.isActive ? Colors.green : Colors.grey,
            ),
            title: Text(med.name),
            subtitle: Text('${med.dosage} • ${med.frequency}'),
            trailing: med.isActive
                ? const Icon(Icons.arrow_forward_ios, size: 16)
                : Chip(label: Text('Terminé'), backgroundColor: Colors.grey[200]),
            onTap: () {
              context.push('/sante/patient/medication/${med.id}', extra: med);
            },
          ),
        );
      },
    );
  }
}
