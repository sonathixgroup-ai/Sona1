// presentation/thix_sante/patient/details/patient_family_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/presentation/thix_sante/shared/models/health_models.dart';
import 'package:thix_id/supabase/supabase_config.dart';

class PatientFamilyPage extends StatefulWidget {
  final String? memberId;
  final bool isEditing;

  const PatientFamilyPage({
    super.key,
    this.memberId,
    this.isEditing = false,
  });

  @override
  State<PatientFamilyPage> createState() => _PatientFamilyPageState();
}

class _PatientFamilyPageState extends State<PatientFamilyPage> {
  final SupabaseClient _supabase = SupabaseConfig.client;
  final _formKey = GlobalKey<FormState>();

  // Contrôleurs du formulaire
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _relationshipController = TextEditingController();
  final _healthNotesController = TextEditingController();

  // Variables d'état
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  List<FamilyMember> _members = [];
  FamilyMember? _selectedMember;
  bool _shareAccess = false;
  DateTime? _dateOfBirth;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _relationshipController.dispose();
    _healthNotesController.dispose();
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

      // Récupérer tous les membres de la famille
      final response = await _supabase
          .from('health_family_members')
          .select('*')
          .eq('patient_id', user.id)
          .order('first_name', ascending: true);

      if (response is List) {
        _members = response
            .map((data) => FamilyMember.fromJson(data))
            .toList();
      }

      // Si un ID est fourni pour édition/détail
      if (widget.memberId != null) {
        final found = _members
            .firstWhere((m) => m.id == widget.memberId, orElse: () => throw Exception('Membre introuvable'));
        _selectedMember = found;
        _fillForm(found);
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

  void _fillForm(FamilyMember member) {
    _firstNameController.text = member.firstName;
    _lastNameController.text = member.lastName;
    _relationshipController.text = member.relationship;
    _healthNotesController.text = member.healthNotes ?? '';
    _shareAccess = member.shareAccess;
    _dateOfBirth = member.dateOfBirth;
  }

  void _clearForm() {
    _firstNameController.clear();
    _lastNameController.clear();
    _relationshipController.clear();
    _healthNotesController.clear();
    _shareAccess = false;
    _dateOfBirth = null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final relationship = _relationshipController.text.trim();

    if (firstName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer le prénom.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (lastName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer le nom.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (relationship.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez préciser le lien de parenté.'),
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
        'first_name': firstName,
        'last_name': lastName,
        'relationship': relationship,
        'date_of_birth': _dateOfBirth?.toIso8601String(),
        'health_notes': _healthNotesController.text.trim().isNotEmpty
            ? _healthNotesController.text.trim()
            : null,
        'share_access': _shareAccess,
      };

      if (_selectedMember == null) {
        // Création
        final created = await _supabase
            .from('health_family_members')
            .insert(payload)
            .select()
            .single();
        final newMember = FamilyMember.fromJson(created);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Membre ajouté avec succès.'),
            backgroundColor: Colors.green,
          ),
        );
        if (!mounted) return;
        setState(() {
          _members.add(newMember);
          _clearForm();
          _selectedMember = null;
        });
        context.pop(true);
      } else {
        // Mise à jour
        await _supabase
            .from('health_family_members')
            .update(payload)
            .eq('id', _selectedMember!.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Membre mis à jour.'),
            backgroundColor: Colors.green,
          ),
        );
        if (!mounted) return;
        await _loadData();
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

  Future<void> _deleteMember(FamilyMember member) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce membre ?'),
        content: Text('Supprimer ${member.fullName} de votre espace famille ?'),
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
    if (confirm != true) return;

    try {
      await _supabase
          .from('health_family_members')
          .delete()
          .eq('id', member.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Membre supprimé.'),
          backgroundColor: Colors.orange,
        ),
      );
      setState(() {
        _members.removeWhere((m) => m.id == member.id);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAddDialog() {
    _clearForm();
    _selectedMember = null;
    setState(() {});
    _showFormDialog('Ajouter un membre', Icons.person_add);
  }

  void _showEditDialog(FamilyMember member) {
    _selectedMember = member;
    _fillForm(member);
    setState(() {});
    _showFormDialog('Modifier un membre', Icons.edit);
  }

  void _showFormDialog(String title, IconData icon) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(icon, color: const Color(0xFF2563FF)),
                const SizedBox(width: 8),
                Text(title),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: _firstNameController,
                        decoration: const InputDecoration(
                          labelText: 'Prénom *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _lastNameController,
                        decoration: const InputDecoration(
                          labelText: 'Nom *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _relationshipController,
                        decoration: const InputDecoration(
                          labelText: 'Lien de parenté * (ex: Époux, Fille)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today),
                          const SizedBox(width: 8),
                          const Text('Date de naissance : '),
                          TextButton(
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: ctx,
                                initialDate: _dateOfBirth ?? DateTime.now().subtract(const Duration(days: 365 * 20)),
                                firstDate: DateTime.now().subtract(const Duration(days: 365 * 100)),
                                lastDate: DateTime.now(),
                              );
                              if (date != null) {
                                setStateDialog(() {
                                  _dateOfBirth = date;
                                });
                              }
                            },
                            child: Text(
                              _dateOfBirth != null
                                  ? '${_dateOfBirth!.day.toString().padLeft(2, '0')}/${_dateOfBirth!.month.toString().padLeft(2, '0')}/${_dateOfBirth!.year}'
                                  : 'Non définie',
                            ),
                          ),
                          if (_dateOfBirth != null)
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () => setStateDialog(() => _dateOfBirth = null),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _healthNotesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes de santé (optionnel)',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Switch(
                            value: _shareAccess,
                            onChanged: (value) => setStateDialog(() => _shareAccess = value),
                            activeColor: const Color(0xFF2563FF),
                          ),
                          const Text('Partager l\'accès au dossier'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563FF),
                  foregroundColor: Colors.white,
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
                    : const Text('Enregistrer'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDetail = widget.memberId != null && !widget.isEditing;

    if (isDetail && _selectedMember != null) {
      return _buildDetailView();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Espace famille'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
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
              : _members.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.family_restroom,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Aucun membre dans votre espace famille.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Ajoutez vos proches pour gérer leur santé.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _showAddDialog,
                              icon: const Icon(Icons.person_add),
                              label: const Text('Ajouter un membre'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563FF),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _members.length,
                        itemBuilder: (context, index) {
                          final member = _members[index];
                          return _FamilyMemberCard(
                            member: member,
                            onTap: () {
                              context.push('/sante/patient/family/${member.id}');
                            },
                            onEdit: () => _showEditDialog(member),
                            onDelete: () => _deleteMember(member),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: const Color(0xFF2563FF),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDetailView() {
    final m = _selectedMember!;
    return Scaffold(
      appBar: AppBar(
        title: Text(m.fullName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              context.push('/sante/patient/family/${m.id}?edit=true');
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _deleteMember(m),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: const Color(0xFF2563FF),
              child: Text(
                m.firstName.isNotEmpty ? m.firstName[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 32,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _infoRow('Nom complet', m.fullName),
            _infoRow('Lien de parenté', m.relationship),
            if (m.dateOfBirth != null)
              _infoRow('Date de naissance', _formatDate(m.dateOfBirth!)),
            _infoRow('Partage d\'accès', m.shareAccess ? 'Activé' : 'Désactivé'),
            if (m.healthNotes != null)
              _infoRow('Notes de santé', m.healthNotes!),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => context.pop(),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Retour'),
            ),
          ],
        ),
      ),
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

class _FamilyMemberCard extends StatelessWidget {
  final FamilyMember member;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FamilyMemberCard({
    required this.member,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFF2563FF).withOpacity(0.1),
                child: Text(
                  member.firstName.isNotEmpty ? member.firstName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2563FF),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.fullName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      member.relationship,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (member.shareAccess)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Dossier partagé',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: onEdit,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
