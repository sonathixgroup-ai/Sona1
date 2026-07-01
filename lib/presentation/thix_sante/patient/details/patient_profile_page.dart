// presentation/thix_sante/patient/details/patient_profile_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/presentation/thix_sante/health_constants.dart';
import 'package:thix_id/supabase/supabase_config.dart';

class PatientProfilePage extends StatefulWidget {
  const PatientProfilePage({super.key});

  @override
  State<PatientProfilePage> createState() => _PatientProfilePageState();
}

class _PatientProfilePageState extends State<PatientProfilePage> {
  final SupabaseClient _supabase = SupabaseConfig.client;

  // Contrôleurs pour les champs modifiables
  final _phoneController = TextEditingController();
  final _bloodTypeController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;
  String? _error;

  // Données utilisateur
  String _displayName = '';
  String _email = '';
  String _photoUrl = '';
  String _phone = '';
  String _bloodType = '';
  String _allergies = '';
  String _emergencyContact = '';
  String _address = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _bloodTypeController.dispose();
    _allergiesController.dispose();
    _emergencyContactController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = AuthController.instance.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      _displayName = user.displayName ?? '';
      _email = user.email ?? '';
      _photoUrl = user.photoUrl ?? '';

      // Récupérer les informations supplémentaires du patient
      final response = await _supabase
          .from('patient_profiles')
          .select('*')
          .eq('id', user.id)
          .maybeSingle();

      if (response != null) {
        _phone = response['phone'] ?? '';
        _bloodType = response['blood_type'] ?? '';
        _allergies = response['allergies'] ?? '';
        _emergencyContact = response['emergency_contact'] ?? '';
        _address = response['address'] ?? '';
      }

      _fillControllers();

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

  void _fillControllers() {
    _phoneController.text = _phone;
    _bloodTypeController.text = _bloodType;
    _allergiesController.text = _allergies;
    _emergencyContactController.text = _emergencyContact;
    _addressController.text = _address;
  }

  Future<void> _saveProfile() async {
    final phone = _phoneController.text.trim();
    final bloodType = _bloodTypeController.text.trim();
    final allergies = _allergiesController.text.trim();
    final emergencyContact = _emergencyContactController.text.trim();
    final address = _addressController.text.trim();

    setState(() => _isSaving = true);

    try {
      final user = AuthController.instance.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Mettre à jour la table patient_profiles
      final payload = {
        'id': user.id,
        'phone': phone.isNotEmpty ? phone : null,
        'blood_type': bloodType.isNotEmpty ? bloodType : null,
        'allergies': allergies.isNotEmpty ? allergies : null,
        'emergency_contact': emergencyContact.isNotEmpty ? emergencyContact : null,
        'address': address.isNotEmpty ? address : null,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Vérifier si une ligne existe déjà
      final existing = await _supabase
          .from('patient_profiles')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();

      if (existing == null) {
        // Créer une nouvelle ligne
        await _supabase.from('patient_profiles').insert(payload);
      } else {
        // Mettre à jour la ligne existante
        await _supabase
            .from('patient_profiles')
            .update(payload)
            .eq('id', user.id);
      }

      // Mettre à jour les variables locales
      _phone = phone;
      _bloodType = bloodType;
      _allergies = allergies;
      _emergencyContact = emergencyContact;
      _address = address;

      setState(() {
        _isEditing = false;
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil mis à jour avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isSaving = false);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon profil'),
        backgroundColor: const Color(0xFF2563FF),
        foregroundColor: Colors.white,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                  _fillControllers();
                });
              },
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _fillControllers(); // Réinitialiser les valeurs
                });
              },
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
                        onPressed: _loadProfile,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Avatar et nom
                      _buildProfileHeader(),
                      const SizedBox(height: 24),

                      // Informations personnelles
                      if (!_isEditing) _buildInfoView() else _buildEditView(),

                      const SizedBox(height: 24),

                      // Bouton de sauvegarde (en mode édition)
                      if (_isEditing)
                        ElevatedButton(
                          onPressed: _isSaving ? null : _saveProfile,
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
                              : const Text('Enregistrer les modifications'),
                        ),

                      const SizedBox(height: 12),

                      // Bouton de déconnexion
                      OutlinedButton(
                        onPressed: () {
                          _showLogoutDialog();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        child: const Text('Se déconnecter'),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.grey[300],
          backgroundImage: _photoUrl.isNotEmpty
              ? NetworkImage(_photoUrl)
              : null,
          child: _photoUrl.isEmpty
              ? Text(
                  _displayName.isNotEmpty ? _displayName[0].toUpperCase() : 'U',
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                )
              : null,
        ),
        const SizedBox(height: 12),
        Text(
          _displayName.isNotEmpty ? _displayName : 'Utilisateur',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          _email.isNotEmpty ? _email : 'Email non renseigné',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF2563FF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Patient THIX Santé',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2563FF),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoView() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _infoRow('Téléphone', _phone.isEmpty ? 'Non renseigné' : _phone),
            _divider(),
            _infoRow('Groupe sanguin', _bloodType.isEmpty ? 'Non renseigné' : _bloodType),
            _divider(),
            _infoRow('Allergies', _allergies.isEmpty ? 'Aucune déclarée' : _allergies),
            _divider(),
            _infoRow('Contact d\'urgence', _emergencyContact.isEmpty ? 'Non renseigné' : _emergencyContact),
            _divider(),
            _infoRow('Adresse', _address.isEmpty ? 'Non renseignée' : _address),
          ],
        ),
      ),
    );
  }

  Widget _buildEditView() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Téléphone',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bloodTypeController,
              decoration: const InputDecoration(
                labelText: 'Groupe sanguin (ex: A+, O-)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.bloodtype),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _allergiesController,
              decoration: const InputDecoration(
                labelText: 'Allergies (ex: pénicilline, acariens)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.warning_amber),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emergencyContactController,
              decoration: const InputDecoration(
                labelText: 'Contact d\'urgence (nom + téléphone)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.contact_emergency),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Adresse',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
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

  Widget _divider() {
    return Divider(
      height: 1,
      color: Colors.grey[200],
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await Supabase.instance.client.auth.signOut();
                if (!mounted) return;
                context.go('/login');
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur de déconnexion : $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
  }
}
