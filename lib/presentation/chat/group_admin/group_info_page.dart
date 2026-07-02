// lib/presentation/chat/group_admin/group_info_page.dart
// Page d'information détaillée du groupe (membres, fichiers, paramètres)

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'group_roles_manager.dart';
import 'group_settings_page.dart';
import 'add_members_sheet.dart';

class GroupInfoPage extends StatelessWidget {
  final String groupId;
  final String groupName;
  final String? avatarUrl;
  final String? description;
  final List<GroupMember> members;
  final bool isAdmin;

  const GroupInfoPage({
    Key? key,
    required this.groupId,
    required this.groupName,
    this.avatarUrl,
    this.description,
    required this.members,
    this.isAdmin = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Info groupe')),
      body: ListView(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: avatarUrl != null
                      ? CachedNetworkImageProvider(avatarUrl!)
                      : const AssetImage('assets/default_group.png') as ImageProvider,
                ),
                const SizedBox(height: 8),
                Text(groupName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                if (description != null) ...[
                  const SizedBox(height: 4),
                  Text(description!, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ],
            ),
          ),
          if (isAdmin) ...[
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Paramètres du groupe'),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GroupSettingsPage(
                      groupId: groupId,
                      initialName: groupName,
                      initialAvatarUrl: avatarUrl,
                      initialDescription: description,
                      onSave: (name, desc, avatarPath) {
                        // Appel API pour mettre à jour
                      },
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('Gérer les rôles'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GroupRolesManager(
                      groupId: groupId,
                      currentRoles: {for (var m in members) m.userId: m.role},
                      onRoleChanged: (userId, newRole) {
                        // Appel API
                      },
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Ajouter des membres'),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (_) => AddMembersSheet(
                    existingMemberIds: members.map((m) => m.userId).toList(),
                    onAdd: (ids) {
                      // Appel API
                    },
                  ),
                );
              },
            ),
          ],
          const Divider(),
          ListTile(
            leading: const Icon(Icons.group),
            title: const Text('Membres'),
            subtitle: Text('${members.length} participants'),
            onTap: () {
              // Naviguer vers liste détaillée des membres
            },
          ),
          ...members.map((m) => ListTile(
                leading: CircleAvatar(
                  backgroundImage: m.avatarUrl != null
                      ? CachedNetworkImageProvider(m.avatarUrl!)
                      : null,
                  child: m.avatarUrl == null ? Text(m.displayName[0]) : null,
                ),
                title: Text(m.displayName),
                trailing: Text(_roleString(m.role), style: const TextStyle(fontSize: 12)),
              )),
        ],
      ),
    );
  }

  String _roleString(GroupRole role) {
    switch (role) {
      case GroupRole.admin: return 'Admin';
      case GroupRole.moderator: return 'Modérateur';
      case GroupRole.member: return 'Membre';
    }
  }
}

class GroupMember {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final GroupRole role;
  GroupMember({required this.userId, required this.displayName, this.avatarUrl, required this.role});
}
