// presentation/thix_sante/patient/details/patient_symptom_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/presentation/thix_sante/shared/models/health_models.dart';
import 'package:thix_id/presentation/thix_sante/shared/services/health_services.dart';
import 'package:thix_id/supabase/supabase_config.dart';

class PatientSymptomPage extends StatefulWidget {
  final String? symptomId;
  final bool isEditing;

  const PatientSymptomPage({
    super.key,
    this.symptomId,
    this.isEditing = false,
  });

  @override
  State<PatientSymptomPage> createState() => _PatientSymptomPageState();
}

class _PatientSymptomPageState extends State<PatientSymptomPage> {
  final HealthService _healthService = HealthService.instance;
  final SupabaseClient _supabase = SupabaseConfig.client;

  final _nameController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  Symptom? _symptom;

  int _intensity = 3;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (widget.symptomId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final response = await _supabase
          .from('health_symptoms')
          .select('*')
          .eq('id', widget.symptomId!)
          .maybeSingle();

      if (response == null) {
        throw Exception('Symptôme introuvable');
      }

      final data = response as Map<String, dynamic>;
      final symptom = Symptom(
        id: data['id'] as String,
        name: data['name'] as String,
        intensity: data['intensity'] as int,
        date: DateTime.parse(data['date'] as String),
        notes: data['notes'] as String?,
      );

      setState(() {
        _symptom = symptom;
        _nameController.text = symptom.name;
        _intensity = symptom.intensity;
        _selectedDate = symptom.date;
        _notesController.text = symptom.notes ?? '';
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
          content: Text('Veuillez entrer un nom pour le symptôme.'),
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
        'intensity': _intensity,
        'date': _selectedDate.toIso8601String(),
        'notes': _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      };

      if (widget.symptomId == null) {
        // Création
        final created = await _supabase
            .from('health_symptoms')
            .insert(payload)
            .select()
            .single();
        final createdId = created['id'] as String; // ✅ correction
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Symptôme ajouté avec succès.'),
            backgroundColor: Colors.green,
          ),
        );
        if (!mounted) return;
        context.push('/sante/patient/symptom/$createdId');
      } else {
        // Mise à jour
        await _supabase
            .from('health_symptoms')
            .update(payload)
            .eq('id', widget.symptomId!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Symptôme mis à jour.'),
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
        title: const Text('Supprimer le symptôme ?'),
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

    if (confirm != true || widget.symptomId == null) return;

    try {
      await _supabase
          .from('health_symptoms')
          .delete()
          .eq('id', widget.symptomId!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Symptôme supprimé.'),
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
    final isNew = widget.symptomId == null;
    final title = isNew
        ? 'Ajouter un symptôme'
        : (widget.isEditing ? 'Modifier le symptôme' : 'Détail du symptôme');

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (!isNew && !widget.isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                context.push('/sante/patient/symptom/${widget.symptomId}?edit=true');
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoRow('Nom', _symptom!.name),
        _infoRow('Intensité', '${_symptom!.intensity}/5'),
        _infoRow('Date', _formatDate(_symptom!.date)),
        if (_symptom!.notes != null) _infoRow('Notes', _symptom!.notes!),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.flag, color: Colors.blue, size: 16),
            const SizedBox(width: 8),
            Text(
              'Intensité : ${_symptom!.intensity}/5',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: _symptom!.intensity / 5,
          backgroundColor: Colors.grey[200],
          color: _intensityColor(_symptom!.intensity),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
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
            labelText: 'Nom du symptôme *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.sick),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(Icons.flag, color: Colors.blue),
            const SizedBox(width: 8),
            const Text('Intensité : '),
            Text(
              '$_intensity/5',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Slider(
          value: _intensity.toDouble(),
          min: 1,
          max: 5,
          divisions: 4,
          label: '$_intensity/5',
          onChanged: (value) => setState(() => _intensity = value.round()),
          activeColor: _intensityColor(_intensity),
        ),
        const SizedBox(height: 8),
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
        const SizedBox(height: 8),
        TextField(
          controller: _notesController,
          decoration: const InputDecoration(
            labelText: 'Notes (optionnel)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.note),
          ),
          maxLines: 3,
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

  Color _intensityColor(int intensity) {
    switch (intensity) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.lightGreen;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.deepOrange;
      case 5:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
