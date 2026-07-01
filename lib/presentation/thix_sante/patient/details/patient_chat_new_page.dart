// presentation/thix_sante/patient/details/patient_chat_new_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/supabase/supabase_config.dart';

class PatientChatNewPage extends StatefulWidget {
  const PatientChatNewPage({super.key});

  @override
  State<PatientChatNewPage> createState() => _PatientChatNewPageState();
}

class _PatientChatNewPageState extends State<PatientChatNewPage> {
  final SupabaseClient _supabase = SupabaseConfig.client;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _contacts = [];
  List<Map<String, dynamic>> _filteredContacts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _searchController.addListener(_filterContacts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = AuthController.instance.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Récupérer les médecins du patient (via les rendez-vous)
      final appointmentsResponse = await _supabase
          .from('health_appointments')
          .select('doctor_id, doctor_name, doctor_specialty')
          .eq('patient_id', user.id);

      // Récupérer les pharmacies avec lesquelles le patient a interagi
      // (si une table existe)
      final pharmaciesResponse = await _supabase
          .from('health_pharmacies')
          .select('id, name, address, phone')
          .limit(5);

      // Construire la liste des contacts
      final contacts = <Map<String, dynamic>>[];

      // Ajouter les médecins
      if (appointmentsResponse is List) {
        for (final row in appointmentsResponse) {
          final doctorId = row['doctor_id'] as String?;
          final doctorName = row['doctor_name'] as String? ?? 'Médecin';
          if (doctorId != null) {
            contacts.add({
              'id': doctorId,
              'name': doctorName,
              'type': 'Médecin',
              'subtitle': row['doctor_specialty'] as String? ?? 'Généraliste',
              'icon': Icons.medical_services,
            });
          }
        }
      }

      // Ajouter les pharmacies
      if (pharmaciesResponse is List) {
        for (final row in pharmaciesResponse) {
          final pharmaId = row['id'] as String?;
          final pharmaName = row['name'] as String? ?? 'Pharmacie';
          if (pharmaId != null) {
            contacts.add({
              'id': pharmaId,
              'name': pharmaName,
              'type': 'Pharmacie',
              'subtitle': row['address'] as String? ?? '',
              'icon': Icons.local_pharmacy,
            });
          }
        }
      }

      // Si aucun contact, ajouter des contacts par défaut (pour la démo)
      if (contacts.isEmpty) {
        contacts.add({
          'id': 'doc_demo1',
          'name': 'Dr. Dupont',
          'type': 'Médecin',
          'subtitle': 'Généraliste',
          'icon': Icons.medical_services,
        });
        contacts.add({
          'id': 'doc_demo2',
          'name': 'Dr. Martin',
          'type': 'Médecin',
          'subtitle': 'Cardiologue',
          'icon': Icons.medical_services,
        });
        contacts.add({
          'id': 'pharma_demo1',
          'name': 'Pharmacie Centrale',
          'type': 'Pharmacie',
          'subtitle': '1 Rue de la Santé',
          'icon': Icons.local_pharmacy,
        });
      }

      // Enlever les doublons
      final seen = <String>{};
      final uniqueContacts = contacts.where((c) {
        final id = c['id'] as String;
        if (seen.contains(id)) return false;
        seen.add(id);
        return true;
      }).toList();

      setState(() {
        _contacts = uniqueContacts;
        _filteredContacts = uniqueContacts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterContacts() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _filteredContacts = _contacts;
      });
      return;
    }
    setState(() {
      _filteredContacts = _contacts.where((c) {
        final name = (c['name'] as String).toLowerCase();
        final subtitle = (c['subtitle'] as String).toLowerCase();
        return name.contains(query) || subtitle.contains(query);
      }).toList();
    });
  }

  void _startChat(Map<String, dynamic> contact) {
    // Naviguer vers la page de chat avec l'ID du contact
    final id = contact['id'] as String;
    final name = contact['name'] as String;
    context.push('/sante/patient/chat/$id', extra: name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau message'),
        backgroundColor: const Color(0xFF2563FF),
        foregroundColor: Colors.white,
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
                        onPressed: _loadContacts,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Barre de recherche
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Rechercher un contact...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    // Liste des contacts
                    Expanded(
                      child: _filteredContacts.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: Text(
                                  'Aucun contact trouvé.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              itemCount: _filteredContacts.length,
                              itemBuilder: (context, index) {
                                final contact = _filteredContacts[index];
                                return _ContactTile(
                                  contact: contact,
                                  onTap: () => _startChat(contact),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final Map<String, dynamic> contact;
  final VoidCallback onTap;

  const _ContactTile({
    required this.contact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final icon = contact['icon'] as IconData? ?? Icons.person;
    final name = contact['name'] as String;
    final type = contact['type'] as String? ?? '';
    final subtitle = contact['subtitle'] as String? ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF2563FF).withOpacity(0.1),
                child: Icon(
                  icon,
                  color: const Color(0xFF2563FF),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (type.isNotEmpty || subtitle.isNotEmpty)
                      Text(
                        type.isNotEmpty ? '$type • $subtitle' : subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
