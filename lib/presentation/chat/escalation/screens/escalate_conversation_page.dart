// ============================================================
// lib/presentation/chat/escalation/screens/escalate_conversation_page.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/escalation_level.dart';
import '../models/escalation_priority.dart';
import '../providers/escalation_provider.dart';
import '../services/escalation_service.dart';

class EscalateConversationPage extends StatefulWidget {
  final String conversationId;
  final String fromAgentId;
  final String? fromAgentName;

  const EscalateConversationPage({
    Key? key,
    required this.conversationId,
    required this.fromAgentId,
    this.fromAgentName,
  }) : super(key: key);

  @override
  State<EscalateConversationPage> createState() => _EscalateConversationPageState();
}

class _EscalateConversationPageState extends State<EscalateConversationPage> {
  final _formKey = GlobalKey<FormState>();
  EscalationLevel? _selectedLevel;
  EscalationPriority _selectedPriority = EscalationPriority.medium;
  final _reasonController = TextEditingController();
  final _commentController = TextEditingController();

  // ✅ Champ pour le destinataire (handle @username)
  final _targetController = TextEditingController();
  String? _targetUserId;
  bool _isSearching = false;
  String? _searchError;
  Map<String, dynamic>? _foundUser;

  @override
  void dispose() {
    _reasonController.dispose();
    _commentController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  // 🔍 Rechercher un utilisateur par son handle (ex: @nlumina)
  Future<void> _searchUser() async {
    final identifier = _targetController.text.trim();
    if (identifier.isEmpty) {
      setState(() {
        _searchError = 'Veuillez saisir un identifiant (ex: @nlumina)';
        _targetUserId = null;
        _foundUser = null;
      });
      return;
    }

    // Retirer le @ si présent
    final cleanIdentifier = identifier.startsWith('@') 
        ? identifier.substring(1) 
        : identifier;

    setState(() {
      _isSearching = true;
      _searchError = null;
      _targetUserId = null;
      _foundUser = null;
    });

    try {
      final service = EscalationService();
      // Recherche par handle (username) ou thix_id
      final user = await service.getUserByHandle(cleanIdentifier);
      
      if (user != null && user['id'] != null) {
        setState(() {
          _targetUserId = user['id'];
          _foundUser = user;
          _searchError = null;
        });
        // Afficher un snackbar avec le nom trouvé
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Utilisateur trouvé : ${user['display_name'] ?? user['username']}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _searchError = 'Aucun utilisateur trouvé avec @$cleanIdentifier';
          _targetUserId = null;
          _foundUser = null;
        });
      }
    } catch (e) {
      setState(() {
        _searchError = 'Erreur de recherche : $e';
        _targetUserId = null;
        _foundUser = null;
      });
    } finally {
      setState(() => _isSearching = false);
    }
  }

  // 📋 Ouvrir la liste des contacts
  void _openContactPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Barre de titre
            Row(
              children: [
                const Text(
                  'Sélectionner un destinataire',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Divider(),
            // Champ de recherche dans le modal
            TextField(
              decoration: const InputDecoration(
                hintText: 'Rechercher un contact...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                // Filtrer les contacts en temps réel
                _filterContacts(value);
              },
            ),
            const SizedBox(height: 8),
            // Liste des contacts (exemple)
            Expanded(
              child: _buildContactList(ctx),
            ),
          ],
        ),
      ),
    );
  }

  // 📋 Liste des contacts (exemple)
  Widget _buildContactList(BuildContext ctx) {
    // Dans une vraie implémentation, vous chargeriez cette liste depuis Supabase
    // avec la table 'profiles' ou une table de contacts.
    // Pour l'exemple, on utilise des données statiques.
    final List<Map<String, dynamic>> contacts = [
      {'id': '1', 'display_name': 'Nathan.L', 'username': 'nlumina'},
      {'id': '2', 'display_name': 'backymassamba@gmail.com', 'username': 'backy'},
      {'id': '3', 'display_name': 'THIX CENTRAL', 'username': 'contact_thix'},
      {'id': '4', 'display_name': 'Ustawi food', 'username': 'ustawif'},
    ];

    return ListView.builder(
      itemCount: contacts.length,
      itemBuilder: (context, index) {
        final contact = contacts[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blue.shade100,
            child: Text(
              contact['display_name']![0].toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(contact['display_name'] ?? ''),
          subtitle: Text('@${contact['username']}'),
          onTap: () {
            // Sélectionner le contact
            _targetController.text = '@${contact['username']}';
            _targetUserId = contact['id'];
            _foundUser = contact;
            setState(() {
              _searchError = null;
            });
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ ${contact['display_name']} sélectionné'),
                backgroundColor: Colors.green,
              ),
            );
          },
        );
      },
    );
  }

  // Filtrer les contacts (à implémenter avec une vraie liste)
  void _filterContacts(String query) {
    // À implémenter
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EscalationProvider>(context, listen: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Escalader la conversation'),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info conversation
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.chat, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Conversation #${widget.conversationId.substring(0, 8)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ✅ Destinataire (handle @username)
              const Text(
                'Destinataire (@identifiant) *',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _targetController,
                      decoration: InputDecoration(
                        hintText: 'ex: @nlumina',
                        border: const OutlineInputBorder(),
                        errorText: _searchError,
                        prefixIcon: const Icon(Icons.person),
                        suffixIcon: _isSearching
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : _foundUser != null
                                ? const Icon(Icons.check_circle, color: Colors.green)
                                : null,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez saisir un identifiant';
                        }
                        if (_targetUserId == null) {
                          return 'Appuyez sur "Vérifier" ou sélectionnez un contact';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    children: [
                      ElevatedButton(
                        onPressed: _isSearching ? null : _searchUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          minimumSize: const Size(70, 44),
                        ),
                        child: const Text('Vérifier'),
                      ),
                      const SizedBox(height: 4),
                      OutlinedButton(
                        onPressed: _openContactPicker,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: const Size(70, 30),
                        ),
                        child: const Text('📋 Contacts', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                ],
              ),
              if (_foundUser != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.person, size: 14, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        '✅ ${_foundUser!['display_name'] ?? _foundUser!['username']}',
                        style: const TextStyle(color: Colors.green, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // Sélection du niveau cible
              const Text(
                'Niveau cible',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: EscalationLevel.values
                    .where((level) => level != EscalationLevel.agent)
                    .map((level) => ChoiceChip(
                          label: Text(level.shortLabel),
                          selected: _selectedLevel == level,
                          onSelected: (selected) {
                            setState(() {
                              _selectedLevel = selected ? level : null;
                            });
                          },
                          selectedColor: level.color,
                          backgroundColor: level.color.withOpacity(0.1),
                        ))
                    .toList(),
              ),
              if (_selectedLevel != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Description: ${_selectedLevel!.label}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
              const SizedBox(height: 16),

              // Priorité
              const Text(
                'Priorité',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: EscalationPriority.values.map((priority) {
                  return ChoiceChip(
                    label: Text(priority.label),
                    selected: _selectedPriority == priority,
                    onSelected: (selected) {
                      setState(() {
                        _selectedPriority = selected ? priority : EscalationPriority.medium;
                      });
                    },
                    selectedColor: priority.color,
                    backgroundColor: priority.color.withOpacity(0.1),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Raison
              const Text(
                'Raison de l\'escalade *',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  hintText: 'Expliquez pourquoi vous escaladez',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer une raison';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Commentaire optionnel
              const Text(
                'Commentaire (optionnel)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _commentController,
                decoration: const InputDecoration(
                  hintText: 'Ajoutez un commentaire pour le destinataire',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // Boutons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: provider.isLoading ? null : _submit,
                      icon: provider.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send),
                      label: const Text('Escalader'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.pop(),
                      child: const Text('Annuler'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),

              if (provider.error != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Erreur: ${provider.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLevel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un niveau cible')),
      );
      return;
    }
    if (_targetUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un destinataire valide')),
      );
      return;
    }

    final provider = Provider.of<EscalationProvider>(context, listen: false);
    final success = await provider.createEscalation(
      conversationId: widget.conversationId,
      fromAgentId: widget.fromAgentId,
      targetAgentId: _targetUserId!,
      toLevel: _selectedLevel!,
      reason: _reasonController.text,
      priority: _selectedPriority,
      comment: _commentController.text.isNotEmpty ? _commentController.text : null,
      fromAgentName: widget.fromAgentName,
    );

    if (success != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escalade envoyée avec succès'),
          backgroundColor: Colors.green,
        ),
      );
      context.pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${provider.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
