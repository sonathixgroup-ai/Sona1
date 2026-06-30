// presentation/thix_sante/patient/details/patient_medication_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/presentation/thix_sante/shared/models/health_models.dart';
import 'package:thix_id/presentation/thix_sante/shared/services/health_services.dart';
import 'package:thix_id/supabase/supabase_config.dart';

class PatientMedicationPage extends StatefulWidget {
  final String? medicationId;
  final bool isEditing;

  const PatientMedicationPage({
    super.key,
    this.medicationId,
    this.isEditing = false,
  });

  @override
  State<PatientMedicationPage> createState() => _PatientMedicationPageState();
}

class _PatientMedicationPageState extends State<PatientMedicationPage> {
  final HealthService _healthService = HealthService.instance;
  final SupabaseClient _supabase = SupabaseConfig.client;

  // Contrôleurs
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _frequencyController = TextEditingController();
  final _durationController = TextEditingController();
  final _instructionsController = TextEditingController();

  // Variables d'état
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  Medication? _medication;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _frequencyController.dispose();
    _durationController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (widget.medicationId == null) {
        // Nouveau médicament
        setState(() => _isLoading = false);
        return;
      }

      // Récupérer le médicament via Supabase
      final response = await _supabase
          .from('health_medications')
          .select('*')
          .eq('id', widget.medicationId!)
          .maybeSingle();

      if (response == null) {
        throw Exception('Médicament introuvable');
      }

      final data = response as Map<String, dynamic>;
      final medication = Medication(
        id: data['id'] as String,
        patientId: data['patient_id'] as String,
        name: data['name'] as String,
        dosage: data['dosage'] as String,
        frequency: data['frequency'] as String,
        duration: data['duration'] as String?,
        instructions: data['instructions'] as String?,
        startDate: DateTime.parse(data['start_date'] as String),
        endDate: data['end_date'] != null
            ? DateTime.parse(data['end_date'] as String)
            : null,
        isActive: data['is_active'] as bool? ?? true,
        prescriptionId: data['prescription_id'] as String?,
        prescribedBy: data['prescribed_by'] as String?,
        reminders: const [],
      );

      setState(() {
        _medication = medication;
        _nameController.text = medication.name;
        _dosageController.text = medication.dosage;
        _frequencyController.text = medication.frequency;
        _durationController.text = medication.duration ?? '';
        _instructionsController.text = medication.instructions ?? '';
        _startDate = medication.startDate;
        _endDate = medication.endDate;
        _isActive = medication.isActive;
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
    final dosage = _dosageController.text.trim();
    final frequency = _frequencyController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer le nom du médicament.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (dosage.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer le dosage.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (frequency.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer la fréquence.'),
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
        'dosage': dosage,
        'frequency': frequency,
        'duration': _durationController.text.trim().isNotEmpty
            ? _durationController.text.trim()
            : null,
        'instructions': _instructionsController.text.trim().isNotEmpty
            ? _instructionsController.text.trim()
            : null,
        'start_date': _startDate.toIso8601String(),
        'end_date': _endDate?.toIso8601String(),
        'is_active': _isActive,
      };

      if (widget.medicationId == null) {
        // Création
        final created = await _healthService.addMedication(
          Medication(
            id: '', // sera généré par Supabase
            patientId: user.id,
            name: name,
            dosage: dosage,
            frequency: frequency,
            duration: _durationController.text.trim().isNotEmpty
                ? _durationController.text.trim()
                : null,
            instructions: _instructionsController.text.trim().isNotEmpty
                ? _instructionsController.text.trim()
                : null,
            startDate: _startDate,
            endDate: _endDate,
            isActive: _isActive,
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Médicament ajouté avec succès.'),
            backgroundColor: Colors.green,
          ),
        );
        if (!mounted) return;
        context.push('/sante/patient/medication/${created.id}');
      } else {
        // Mise à jour
        await _supabase
            .from('health_medications')
            .update(payload)
            .eq('id', widget.medicationId!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Médicament mis à jour.'),
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
        title: const Text('Supprimer le médicament ?'),
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

    if (confirm != true || widget.medicationId == null) return;

    try {
      await _supabase
          .from('health_medications')
          .delete()
          .eq('id', widget.medicationId!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Médicament supprimé.'),
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
    final isNew = widget.medicationId == null;
    final title = isNew
        ? 'Ajouter un médicament'
        : (widget.isEditing ? 'Modifier le médicament' : 'Détail du médicament');

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (!isNew && !widget.isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                context.push('/sante/patient/medication/${widget.medicationId}?edit=true');
              },
            ),
          if (!isNew && !widget.isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _delete,
            ),
          if (!isNew && !widget.isEditing)
            IconButton(
              icon: const Icon(Icons.notifications_active),
              onPressed: () {
                // Naviguer vers la page des rappels
                context.push('/sante/patient/medication/${widget.medicationId}/reminders');
              },
              tooltip: 'Gérer les rappels',
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
    final m = _medication!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoRow('Nom', m.name),
        _infoRow('Dosage', m.dosage),
        _infoRow('Fréquence', m.frequency),
        if (m.duration != null) _infoRow('Durée', m.duration!),
        if (m.instructions != null) _infoRow('Instructions', m.instructions!),
        _infoRow('Début', _formatDate(m.startDate)),
        if (m.endDate != null) _infoRow('Fin', _formatDate(m.endDate!)),
        _infoRow('Statut', m.isActive ? 'Actif' : 'Terminé'),
        if (m.prescribedBy != null) _infoRow('Prescrit par', m.prescribedBy!),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: m.isActive ? Colors.green[50] : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                m.isActive ? Icons.check_circle : Icons.cancel,
                color: m.isActive ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                m.isActive ? 'En cours' : 'Terminé',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: m.isActive ? Colors.green : Colors.grey,
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
            labelText: 'Nom du médicament *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.medication),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _dosageController,
          decoration: const InputDecoration(
            labelText: 'Dosage * (ex: 500 mg)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.medication_liquid),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _frequencyController,
          decoration: const InputDecoration(
            labelText: 'Fréquence * (ex: 3x/jour)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.timer),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _durationController,
          decoration: const InputDecoration(
            labelText: 'Durée (optionnel)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.calendar_today),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _instructionsController,
          decoration: const InputDecoration(
            labelText: 'Instructions (optionnel)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.note),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.calendar_today),
            const SizedBox(width: 8),
            const Text('Début : '),
            TextButton(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) setState(() => _startDate = date);
              },
              child: Text(_formatDate(_startDate)),
            ),
          ],
        ),
        Row(
          children: [
            const Icon(Icons.calendar_today),
            const SizedBox(width: 8),
            const Text('Fin : '),
            TextButton(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _endDate ?? _startDate.add(const Duration(days: 30)),
                  firstDate: _startDate,
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) setState(() => _endDate = date);
              },
              child: Text(_endDate != null ? _formatDate(_endDate!) : 'Non définie'),
            ),
            if (_endDate != null)
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => setState(() => _endDate = null),
              ),
          ],
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('Médicament actif'),
          value: _isActive,
          onChanged: (value) => setState(() => _isActive = value),
          activeColor: Colors.green,
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
