// presentation/thix_sante/patient/details/patient_vaccine_page.dart
// (version complète avec correction ligne 434)
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/presentation/thix_sante/shared/models/health_models.dart';
import 'package:thix_id/presentation/thix_sante/shared/services/health_services.dart';
import 'package:thix_id/supabase/supabase_config.dart';

class PatientVaccinePage extends StatefulWidget {
  final String? vaccineId;
  final bool isEditing;

  const PatientVaccinePage({
    super.key,
    this.vaccineId,
    this.isEditing = false,
  });

  @override
  State<PatientVaccinePage> createState() => _PatientVaccinePageState();
}

class _PatientVaccinePageState extends State<PatientVaccinePage> {
  final HealthService _healthService = HealthService.instance;
  final SupabaseClient _supabase = SupabaseConfig.client;

  // Contrôleurs
  final _nameController = TextEditingController();
  final _batchController = TextEditingController();
  final _administeredByController = TextEditingController();

  // Variables d'état
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  Vaccine? _vaccine;

  // Dates
  DateTime _administeredDate = DateTime.now();
  DateTime? _boosterDate;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _batchController.dispose();
    _administeredByController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (widget.vaccineId == null) {
        // Nouveau vaccin
        setState(() => _isLoading = false);
        return;
      }

      // Récupérer le vaccin via Supabase
      final response = await _supabase
          .from('health_vaccines')
          .select('*')
          .eq('id', widget.vaccineId!)
          .maybeSingle();

      if (response == null) {
        throw Exception('Vaccin introuvable');
      }

      final data = response as Map<String, dynamic>;
      final vaccine = Vaccine(
        id: data['id'] as String,
        patientId: data['patient_id'] as String,
        name: data['name'] as String,
        dateAdministered: DateTime.parse(data['date_administered'] as String),
        boosterDate: data['booster_date'] != null
            ? DateTime.parse(data['booster_date'] as String)
            : null,
        batchNumber: data['batch_number'] as String?,
        administeredBy: data['administered_by'] as String?,
      );

      setState(() {
        _vaccine = vaccine;
        _nameController.text = vaccine.name;
        _administeredDate = vaccine.dateAdministered;
        _boosterDate = vaccine.boosterDate;
        _batchController.text = vaccine.batchNumber ?? '';
        _administeredByController.text = vaccine.administeredBy ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer le nom du vaccin.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = AuthController.instance.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      final Map<String, dynamic> payload = {
        'patient_id': user.id,
        'name': name,
        'date_administered': _administeredDate.toIso8601String(),
        'booster_date': _boosterDate?.toIso8601String(),
        'batch_number': _batchController.text.trim().isNotEmpty
            ? _batchController.text.trim()
            : null,
        'administered_by': _administeredByController.text.trim().isNotEmpty
            ? _administeredByController.text.trim()
            : null,
      };

      if (widget.vaccineId == null) {
        // Création
        final created = await _healthService.addVaccine(
          Vaccine(
            id: '', // sera généré par Supabase
            patientId: user.id,
            name: name,
            dateAdministered: _administeredDate,
            boosterDate: _boosterDate,
            batchNumber: _batchController.text.trim().isNotEmpty
                ? _batchController.text.trim()
                : null,
            administeredBy: _administeredByController.text.trim().isNotEmpty
                ? _administeredByController.text.trim()
                : null,
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vaccin ajouté avec succès.'),
            backgroundColor: Colors.green,
          ),
        );
        if (!mounted) return;
        context.push('/sante/patient/vaccine/${created.id}');
      } else {
        // Mise à jour
        await _supabase
            .from('health_vaccines')
            .update(payload)
            .eq('id', widget.vaccineId!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vaccin mis à jour.'),
            backgroundColor: Colors.green,
          ),
        );
        if (!mounted) return;
        context.pop(true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le vaccin ?'),
        content: const Text('Cette action est définitive.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Non'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Oui'),
          ),
        ],
      ),
    );

    if (confirm != true || widget.vaccineId == null) return;

    try {
      await _supabase
          .from('health_vaccines')
          .delete()
          .eq('id', widget.vaccineId!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vaccin supprimé.'),
          backgroundColor: Colors.orange,
        ),
      );
      if (!mounted) return;
      context.pop(true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.vaccineId == null;
    final title = isNew
        ? 'Ajouter un vaccin'
        : (widget.isEditing ? 'Modifier le vaccin' : 'Détail du vaccin');

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (!isNew && !widget.isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                context.push('/sante/patient/vaccine/${widget.vaccineId}?edit=true');
              },
            ),
          if (!isNew && !widget.isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _delete,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 8),
                      Text('Erreur : $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (!isNew && !widget.isEditing)
                        _buildDetailView()
                      else
                        _buildFormView(),
                      const SizedBox(height: 24),
                      if (widget.isEditing || isNew)
                        ElevatedButton(
                          onPressed: _isSaving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563FF),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 48),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(isNew ? 'Ajouter' : 'Enregistrer'),
                        ),
                      if (!isNew && !widget.isEditing)
                        OutlinedButton(
                          onPressed: _delete,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            minimumSize: const Size(double.infinity, 48),
                          ),
                          child: const Text('Supprimer'),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildDetailView() {
    final v = _vaccine!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoRow('Nom', v.name),
        _infoRow('Administré le', _formatDate(v.dateAdministered)),
        if (v.boosterDate != null)
          _infoRow('Rappel', _formatDate(v.boosterDate!)),
        if (v.batchNumber != null)
          _infoRow('Lot', v.batchNumber!),
        if (v.administeredBy != null)
          _infoRow('Administré par', v.administeredBy!),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: v.isBoosterDue ? Colors.red[50] : Colors.green[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                v.isBoosterDue ? Icons.warning : Icons.check_circle,
                color: v.isBoosterDue ? Colors.red : Colors.green,
              ),
              const SizedBox(width: 8),
              Text(
                v.isBoosterDue ? 'Rappel dû' : 'À jour',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: v.isBoosterDue ? Colors.red : Colors.green,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormView() {
    return Column(
      children: [
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Nom du vaccin *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.vaccines),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.calendar_today),
            const SizedBox(width: 8),
            const Text('Administré le : '),
            TextButton(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _administeredDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 3650)),
                  lastDate: DateTime.now(),
                );
                if (date != null) setState(() => _administeredDate = date);
              },
              child: Text(_formatDate(_administeredDate)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.calendar_today),
            const SizedBox(width: 8),
            const Text('Rappel : '),
            TextButton(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _boosterDate ?? _administeredDate.add(const Duration(days: 365)),
                  firstDate: _administeredDate,
                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                );
                if (date != null) setState(() => _boosterDate = date);
              },
              child: Text(
                _boosterDate != null
                    ? _formatDate(_boosterDate!)
                    : 'Non défini',
              ),
            ),
            if (_boosterDate != null)
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => setState(() => _boosterDate = null),
              ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _batchController,
          decoration: const InputDecoration(
            labelText: 'Numéro de lot (optionnel)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.barcode), // ✅ correction (sans const)
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _administeredByController,
          decoration: const InputDecoration(
            labelText: 'Administré par (optionnel)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
