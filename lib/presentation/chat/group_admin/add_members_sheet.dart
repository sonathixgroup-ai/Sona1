// lib/presentation/chat/group_admin/add_members_sheet.dart
// Feuille modale pour ajouter des membres à un groupe (recherche + sélection)

import 'package:flutter/material.dart';

class AddMembersSheet extends StatefulWidget {
  final List<String> existingMemberIds;
  final Function(List<String> selectedUserIds) onAdd;

  const AddMembersSheet({
    Key? key,
    required this.existingMemberIds,
    required this.onAdd,
  }) : super(key: key);

  @override
  State<AddMembersSheet> createState() => _AddMembersSheetState();
}

class _AddMembersSheetState extends State<AddMembersSheet> {
  final Set<String> _selectedIds = {};
  final TextEditingController _searchController = TextEditingController();
  List<String> _availableUsers = []; // À remplacer par vraie liste depuis API
  List<String> _filteredUsers = [];

  @override
  void initState() {
    super.initState();
    _loadAvailableUsers();
    _searchController.addListener(_filter);
  }

  Future<void> _loadAvailableUsers() async {
    // Appel repository.getAvailableContacts() -> List<User>
    // Pour l'exemple, on simule
    _availableUsers = ['user1', 'user2', 'user3', 'user4'];
    _filter();
  }

  void _filter() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = _availableUsers
          .where((u) => !widget.existingMemberIds.contains(u) && u.contains(query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Ajouter des membres', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Rechercher un contact',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _filteredUsers.length,
              itemBuilder: (context, index) {
                final userId = _filteredUsers[index];
                return CheckboxListTile(
                  title: Text(userId), // À remplacer par nom réel
                  value: _selectedIds.contains(userId),
                  onChanged: (val) {
                    setState(() {
                      if (val == true) _selectedIds.add(userId);
                      else _selectedIds.remove(userId);
                    });
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
              ElevatedButton(
                onPressed: () {
                  widget.onAdd(_selectedIds.toList());
                  Navigator.pop(context);
                },
                child: Text('Ajouter (${_selectedIds.length})'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
