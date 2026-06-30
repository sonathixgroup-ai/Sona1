// presentation/thix_sante/patient/details/patient_sharing_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/supabase/supabase_config.dart';

// Modèle local pour le partage
class Share {
  final String id;
  final String patientId;
  final String recipientName;
  final String recipientEmail;
  final String accessLevel; // 'complet' ou 'limite'
  final DateTime expiresAt;
  final DateTime createdAt;

  Share({
    required this.id,
    required this.patientId,
    required this.recipientName,
    required this.recipientEmail,
    required this.accessLevel,
    required this.expiresAt,
    required this.createdAt,
  });

  factory Share.fromJson(Map<String, dynamic> json) {
    return Share(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      recipientName: json['recipient_name'] as String,
      recipientEmail: json['recipient_email'] as String,
      accessLevel: json['access_level'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'patient_id': patientId,
        'recipient_name': recipientName,
        'recipient_email': recipientEmail,
        'access_level': accessLevel,
        'expires_at': expiresAt.toIso8601String(),
      };

  bool get isExpired => expiresAt.isBefore(DateTime.now());
}

class PatientSharingPage extends StatefulWidget {
  final String? shareId;
  final bool isEditing;

  const PatientSharingPage({
    super.key,
    this.shareId,
    this.isEditing = false,
  });

  @override
  State<PatientSharingPage> createState() => _PatientSharingPageState();
}

class _PatientSharingPageState extends State<PatientSharingPage> {
  final SupabaseClient _supabase = SupabaseConfig.client;
  final _formKey = GlobalKey<FormState>();

  // Contrôleurs du formulaire
  final _recipientNameController = TextEditingController();
  final _recipientEmailController = TextEditingController();

  // Variables d'état
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  List<Share> _shares = [];
  Share? _selectedShare;

  // Données du formulaire
  String _accessLevel = 'limite';
  DateTime _expiresAt = DateTime.now().add(const Duration(days: 30));

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _recipientNameController.dispose();
    _recipientEmailController.dispose();
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

      // Récupérer tous les partages
      final response = await _supabase
          .from('health_shares')
          .select('*')
          .eq('patient_id', user.id)
          .order('created_at', ascending: false);

      if (response is List) {
        _shares = response
            .map((data) => Share.fromJson(data))
            .toList();
      }

      // Si un ID est fourni pour détail/édition
      if (widget.shareId != null) {
        final found = _shares
            .firstWhere((s) => s.id == widget.shareId, orElse: () => throw Exception('Partage introuvable'));
        _selectedShare = found;
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

  void _fillForm(Share share) {
    _recipientNameController.text = share.recipientName;
    _recipientEmailController.text = share.recipientEmail;
    _accessLevel = share.accessLevel;
    _expiresAt = share.expiresAt;
  }

  void _clearForm() {
    _recipientNameController.clear();
    _recipientEmailController.clear();
    _accessLevel = 'limite';
    _expiresAt = DateTime.now().add(const Duration(days: 30));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _recipientNameController.text.trim();
    final email = _recipientEmailController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer le nom du destinataire.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer l\'email du destinataire.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_expiresAt.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La date d\'expiration doit être dans le futur.'),
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

      final share = Share(
        id: '',
        patientId: user.id,
        recipientName: name,
        recipientEmail: email,
        accessLevel: _accessLevel,
        expiresAt: _expiresAt,
        createdAt: DateTime.now(),
      );

      if (_selectedShare == null) {
        // Création
        final created = await _supabase
            .from('health_shares')
            .insert(share.toJson())
            .select()
            .single();
        final newShare = Share.fromJson(created);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Partage créé avec succès.'),
            backgroundColor: Colors.green,
          ),
        );
        if (!mounted) return;
        context.push('/sante/patient/sharing/${newShare.id}');
      } else {
        // Mise à jour
        await _supabase
            .from('health_shares')
            .update(share.toJson())
            .eq('id', _selectedShare!.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Partage mis à jour.'),
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

  Future<void> _revokeShare(Share share) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Révoquer ce partage ?'),
        content: Text(
          'Le destinataire ${share.recipientName} n\'aura plus accès à votre dossier.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Révoquer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _supabase
          .from('health_shares')
          .delete()
          .eq('id', share.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Partage révoqué.'),
          backgroundColor: Colors.orange,
        ),
      );
      setState(() {
        _shares.removeWhere((s) => s.id == share.id);
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
    _selectedShare = null;
    setState(() {});
    _showFormDialog('Nouveau partage', Icons.share);
  }

  void _showEditDialog(Share share) {
    _selectedShare = share;
    _fillForm(share);
    setState(() {});
    _showFormDialog('Modifier le partage', Icons.edit);
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
                        controller: _recipientNameController,
                        decoration: const InputDecoration(
                          labelText: 'Nom du destinataire *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _recipientEmailController,
                        decoration: const InputDecoration(
                          labelText: 'Email du destinataire *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _accessLevel,
                        items: const [
                          DropdownMenuItem(value: 'complet', child: Text('Accès complet')),
                          DropdownMenuItem(value: 'limite', child: Text('Accès limité')),
                        ],
                        onChanged: (value) => setStateDialog(() => _accessLevel = value!),
                        decoration: const InputDecoration(
                          labelText: 'Niveau d\'accès *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.security),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today),
                          const SizedBox(width: 8),
                          const Text('Expire le : '),
                          TextButton(
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: ctx,
                                initialDate: _expiresAt,
                                firstDate: DateTime.now().add(const Duration(days: 1)),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (date != null) {
                                setStateDialog(() {
                                  _expiresAt = date;
                                });
                              }
                            },
                            child: Text(DateFormat('dd/MM/yyyy').format(_expiresAt)),
                          ),
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
    final isDetail = widget.shareId != null && !widget.isEditing;

    if (isDetail && _selectedShare != null) {
      return _buildDetailView();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Partage sécurisé'),
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
              : _shares.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.share_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Aucun partage actif.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Partagez votre dossier médical avec un médecin ou un proche.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _showAddDialog,
                              icon: const Icon(Icons.share),
                              label: const Text('Nouveau partage'),
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
                        itemCount: _shares.length,
                        itemBuilder: (context, index) {
                          final share = _shares[index];
                          return _ShareCard(
                            share: share,
                            onTap: () {
                              context.push('/sante/patient/sharing/${share.id}');
                            },
                            onEdit: () => _showEditDialog(share),
                            onRevoke: () => _revokeShare(share),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: const Color(0xFF2563FF),
        foregroundColor: Colors.white,
        child: const Icon(Icons.share),
      ),
    );
  }

  Widget _buildDetailView() {
    final s = _selectedShare!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail du partage'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              context.push('/sante/patient/sharing/${s.id}?edit=true');
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _revokeShare(s),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: s.isExpired ? Colors.grey[100] : Colors.green[50],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      s.isExpired ? Icons.cancel : Icons.check_circle,
                      color: s.isExpired ? Colors.red : Colors.green,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.isExpired ? 'Partage expiré' : 'Partage actif',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: s.isExpired ? Colors.red : Colors.green,
                          ),
                        ),
                        Text(
                          'Créé le ${_formatDate(s.createdAt)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _infoRow('Destinataire', s.recipientName),
            _infoRow('Email', s.recipientEmail),
            _infoRow('Niveau d\'accès', s.accessLevel == 'complet' ? 'Accès complet' : 'Accès limité'),
            _infoRow('Expire le', _formatDate(s.expiresAt)),
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

class _ShareCard extends StatelessWidget {
  final Share share;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onRevoke;

  const _ShareCard({
    required this.share,
    required this.onTap,
    required this.onEdit,
    required this.onRevoke,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: share.isExpired
                        ? Colors.grey[200]
                        : const Color(0xFF2563FF).withOpacity(0.1),
                    child: Icon(
                      Icons.person,
                      color: share.isExpired ? Colors.grey : const Color(0xFF2563FF),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          share.recipientName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          share.recipientEmail,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: share.isExpired ? Colors.grey : Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      share.isExpired ? 'Expiré' : 'Actif',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      share.accessLevel == 'complet' ? 'Accès complet' : 'Accès limité',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Expire le ${_formatDate(share.expiresAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: onEdit,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    onPressed: onRevoke,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
