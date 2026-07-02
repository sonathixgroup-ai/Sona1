// lib/presentation/chat/group_admin/group_roles_manager.dart
// Gestion des rôles des membres (admin, moderateur, membre)

import 'package:flutter/material.dart';

enum GroupRole { admin, moderator, member }

class GroupRolesManager extends StatefulWidget {
  final String groupId;
  final Map<String, GroupRole> currentRoles; // userId -> role
  final Function(String userId, GroupRole newRole) onRoleChanged;

  const GroupRolesManager({
    Key? key,
    required this.groupId,
    required this.currentRoles,
    required this.onRoleChanged,
  }) : super(key: key);

  @override
  State<GroupRolesManager> createState() => _GroupRolesManagerState();
}

class _GroupRolesManagerState extends State<GroupRolesManager> {
  late Map<String, GroupRole> _roles;

  @override
  void initState() {
    super.initState();
    _roles = Map.from(widget.currentRoles);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gérer les rôles')),
      body: ListView.builder(
        itemCount: _roles.length,
        itemBuilder: (context, index) {
          final entry = _roles.entries.elementAt(index);
          final userId = entry.key;
          final role = entry.value;
          return ListTile(
            title: Text('Utilisateur $userId'), // À remplacer par vrai nom
            trailing: DropdownButton<GroupRole>(
              value: role,
              items: const [
                DropdownMenuItem(value: GroupRole.admin, child: Text('Admin')),
                DropdownMenuItem(value: GroupRole.moderator, child: Text('Modérateur')),
                DropdownMenuItem(value: GroupRole.member, child: Text('Membre')),
              ],
              onChanged: (newRole) {
                if (newRole != null) {
                  setState(() => _roles[userId] = newRole);
                  widget.onRoleChanged(userId, newRole);
                }
              },
            ),
          );
        },
      ),
    );
  }
}
