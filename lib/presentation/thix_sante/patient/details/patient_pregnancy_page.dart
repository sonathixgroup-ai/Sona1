// presentation/thix_sante/patient/details/patient_pregnancy_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/presentation/thix_sante/shared/models/health_models.dart';
import 'package:thix_id/supabase/supabase_config.dart';

class PatientPregnancyPage extends StatefulWidget {
  final String? pregnancyId;
  final bool isEditing;

  const PatientPregnancyPage({
    super.key,
    this.pregnancyId,
    this.isEditing = false,
  });

  @override
  State<PatientPregnancyPage> createState() => _PatientPregnancyPageState();
}

class _PatientPregnancyPageState extends State<PatientPregnancyPage> {
  final SupabaseClient _supabase = SupabaseConfig.client;

  // Contrôleurs
  final _weightController = TextEditingController();
  final _notesController = TextEditingController();

  // Variables d'état
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  Pregnancy? _pregnancy;
  List<Pregnancy> _allPregnancies = [];

  // Données du formulaire
  DateTime _conceptionDate = DateTime.now().subtract(const Duration(days: 14 * 7)); // ~14 semaines
  DateTime? _dueDate;
  double? _weightGain;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = AuthController.instance.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Récupérer toutes les grossesses du patient
      final response = await _supabase
          .from('health_pregnancies')
          .select('*')
          .eq('patient_id', user.id)
          .order('conception_date', ascending: false);

      if (response is List) {
        _allPregnancies = response
            .map((data) => Pregnancy.fromJson(data))
            .toList();
      }

      // Si un ID est fourni, on le sélectionne
      if (widget.pregnancyId != null) {
        final found = _allPregnancies
            .firstWhere((p) => p.id == widget.pregnancyId, orElse: () => throw Exception('Grossesse introuvable'));
        _pregnancy = found;
        _fillFromPregnancy(found);
      } else if (_allPregnancies.isNotEmpty) {
        // Si pas d'ID, on prend la plus récente
        _pregnancy = _allPregnancies.first;
        _fillFromPregnancy(_pregnancy!);
      } else {
        // Aucune grossesse : mode création
        _pregnancy = null;
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _fillFromPregnancy(Pregnancy pregnancy) {
    _conceptionDate = pregnancy.conceptionDate;
    _dueDate = pregnancy.dueDate;
    _weightGain = pregnancy.weightGain;
    _weightController.text = pregnancy.weightGain?.toString() ?? '';
    _notesController.text = pregnancy.notes ?? '';
  }

  Future<void> _save() async {
    final weightText = _weightController.text.trim();
    if (weightText.isNotEmpty) {
      _weightGain = double.tryParse(weightText);
      if (_weightGain == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez entrer un poids valide.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    } else {
      _weightGain = null;
    }

    setState(() => _isSaving = true);

    try {
      final user = AuthController.instance.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      final Map<String, dynamic> payload = {
        'patient_id': user.id,
        'conception_date': _conceptionDate.toIso8601String(),
        'due_date': _dueDate?.toIso8601String(),
        'weight_gain': _weightGain,
        'notes': _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      };

      if (_pregnancy == null) {
        // Création
        final created = await _supabase
            .from('health_pregnancies')
            .insert(payload)
            .select()
            .single();
        final newPregnancy = Pregnancy.fromJson(created);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Suivi de grossesse créé avec succès.'),
            backgroundColor: Colors.green,
          ),
        );
        if (!mounted) return;
        context.push('/sante/patient/pregnancy/${newPregnancy.id}');
      } else {
        // Mise à jour
        await _supabase
            .from('health_pregnancies')
            .update(payload)
            .eq('id', _pregnancy!.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Suivi de grossesse mis à jour.'),
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
        title: const Text('Supprimer ce suivi ?'),
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
    if (confirm != true || _pregnancy == null) return;

    try {
      await _supabase
          .from('health_pregnancies')
          .delete()
          .eq('id', _pregnancy!.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Suivi supprimé.'),
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
    final isNew = _pregnancy == null;
    final title = isNew
        ? 'Ajouter un suivi grossesse'
        : (widget.isEditing ? 'Modifier le suivi' : 'Suivi de grossesse');

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (!isNew && !widget.isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                context.push('/sante/patient/pregnancy/${_pregnancy!.id}?edit=true');
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
                      const SizedBox(height: 16),
                      if (_allPregnancies.length > 1 && !widget.isEditing)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Historique des grossesses',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              ..._allPregnancies.map((p) {
                                return ListTile(
                                  title: Text(
                                    'Début : ${_formatDate(p.conceptionDate)}',
                                  ),
                                  subtitle: Text(
                                    p.dueDate != null
                                        ? 'Accouchement prévu : ${_formatDate(p.dueDate!)}'
                                        : 'Date d\'accouchement non définie',
                                  ),
                                  trailing: p.id == _pregnancy?.id
                                      ? const Icon(Icons.check_circle, color: Colors.green)
                                      : null,
                                  onTap: () {
                                    context.push('/sante/patient/pregnancy/${p.id}');
                                  },
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildDetailView() {
    final p = _pregnancy!;
    final weeks = p.weekOfPregnancy ?? p.weeksElapsed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoRow('Semaine actuelle', '$weeks semaines'),
        _infoRow('Date de conception', _formatDate(p.conceptionDate)),
        if (p.dueDate != null)
          _infoRow('Accouchement prévu', _formatDate(p.dueDate!)),
        if (p.weightGain != null)
          _infoRow('Prise de poids', '${p.weightGain} kg'),
        if (p.notes != null)
          _infoRow('Notes', p.notes!),
        if (p.symptoms != null)
          _infoRow('Symptômes', p.symptoms!.join(', ')),
      ],
    );
  }

  Widget _buildFormView() {
    return Column(
      children: [
        Row(
          children: [
            const Icon(Icons.calendar_today),
            const SizedBox(width: 8),
            const Text('Date de conception : '),
            TextButton(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _conceptionDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
                  lastDate: DateTime.now(),
                );
                if (date != null) setState(() => _conceptionDate = date);
              },
              child: Text(_formatDate(_conceptionDate)),
            ),
          ],
        ),
        Row(
          children: [
            const Icon(Icons.calendar_today),
            const SizedBox(width: 8),
            const Text('Accouchement prévu : '),
            TextButton(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _dueDate ?? _conceptionDate.add(const Duration(days: 280)),
                  firstDate: _conceptionDate,
                  lastDate: _conceptionDate.add(const Duration(days: 365)),
                );
                if (date != null) setState(() => _dueDate = date);
              },
              child: Text(_dueDate != null ? _formatDate(_dueDate!) : 'Non défini'),
            ),
            if (_dueDate != null)
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => setState(() => _dueDate = null),
              ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _weightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Prise de poids (kg)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.monitor_weight),
          ),
        ),
        const SizedBox(height: 12),
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
