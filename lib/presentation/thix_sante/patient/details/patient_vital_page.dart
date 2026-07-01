// presentation/thix_sante/patient/details/patient_vital_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/presentation/thix_sante/shared/models/health_models.dart';
import 'package:thix_id/presentation/thix_sante/shared/services/health_services.dart';
import 'package:thix_id/supabase/supabase_config.dart';

class PatientVitalPage extends StatefulWidget {
  final String? vitalId;
  final bool isEditing;

  const PatientVitalPage({super.key, this.vitalId, this.isEditing = false});

  @override
  State<PatientVitalPage> createState() => _PatientVitalPageState();
}

class _PatientVitalPageState extends State<PatientVitalPage> {
  final HealthService _healthService = HealthService.instance;
  final SupabaseClient _supabase = SupabaseConfig.client;

  // Contrôleurs
  final _valueController = TextEditingController();
  final _unitController = TextEditingController();

  // Variables d'état
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  VitalSign? _vitalSign;

  // Données du formulaire
  VitalType _selectedType = VitalType.heartRate;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _valueController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (widget.vitalId == null) {
        // Nouvelle constante
        setState(() => _isLoading = false);
        return;
      }

      // Récupérer la constante via Supabase directe (le service n'a pas de fetchById)
      final response = await _supabase
          .from('health_vitals')
          .select('*')
          .eq('id', widget.vitalId!)
          .maybeSingle();

      if (response == null) {
        throw Exception('Constante introuvable');
      }

      final data = response as Map<String, dynamic>;
      final typeName = data['type'] as String? ?? VitalType.heartRate.name;
      final type = VitalType.values.firstWhere(
        (e) => e.name == typeName,
        orElse: () => VitalType.heartRate,
      );

      final vital = VitalSign(
        id: data['id'] as String,
        patientId: data['patient_id'] as String,
        type: type,
        value: (data['value'] as num).toDouble(),
        unit: data['unit'] as String?,
        date: DateTime.parse(data['measured_at'] as String),
      );

      setState(() {
        _vitalSign = vital;
        _selectedType = vital.type;
        _selectedDate = vital.date;
        _valueController.text = vital.value.toString();
        _unitController.text = vital.unit ?? '';
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
    final valueText = _valueController.text.trim();
    if (valueText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer une valeur.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final value = double.tryParse(valueText);
    if (value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Valeur invalide.'),
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
        'type': _selectedType.name,
        'value': value,
        'unit': _unitController.text.trim().isNotEmpty
            ? _unitController.text.trim()
            : null,
        'measured_at': _selectedDate.toIso8601String(),
      };

      if (widget.vitalId == null) {
        // Création
        await _supabase.from('health_vitals').insert(payload);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Constante ajoutée avec succès.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Mise à jour
        await _supabase
            .from('health_vitals')
            .update(payload)
            .eq('id', widget.vitalId!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Constante mise à jour.'),
            backgroundColor: Colors.green,
          ),
        );
      }

      if (!mounted) return;
      context.pop(true);
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
        title: const Text('Supprimer la constante ?'),
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

    if (confirm != true || widget.vitalId == null) return;

    try {
      await _supabase
          .from('health_vitals')
          .delete()
          .eq('id', widget.vitalId!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Constante supprimée.'),
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
    final isNew = widget.vitalId == null;
    final title = isNew
        ? 'Ajouter une constante'
        : (widget.isEditing ? 'Modifier la constante' : 'Détail de la constante');

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (!isNew && !widget.isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                context.push('/sante/patient/vital/${widget.vitalId}?edit=true');
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
    final v = _vitalSign!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoRow('Type', VitalSign.getVitalLabel(v.type)),
        _infoRow('Valeur', v.displayValue),
        _infoRow('Date', _formatDate(v.date)),
        if (v.notes != null) _infoRow('Notes', v.notes!),
      ],
    );
  }

  Widget _buildFormView() {
    return Column(
      children: [
        DropdownButtonFormField<VitalType>(
          value: _selectedType,
          items: VitalType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(VitalSign.getVitalLabel(type)),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedType = value!),
          decoration: const InputDecoration(
            labelText: 'Type de constante *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.favorite),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _valueController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Valeur *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.numbers),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _unitController,
          decoration: const InputDecoration(
            labelText: 'Unité (ex: kg, mmHg, bpm)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.measuring_tape),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.calendar_today),
            const SizedBox(width: 8),
            const Text('Date : '),
            TextButton(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now(),
                );
                if (date != null) setState(() => _selectedDate = date);
              },
              child: Text(_formatDate(_selectedDate)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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
