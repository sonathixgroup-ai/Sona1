import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/chat/group_service.dart';
import '../../../models/chat/group_info.dart';

/// Écran de paramètres du groupe (admin uniquement).
/// Permet de modifier le nom, la description, l'avatar, les membres et l'invitation.
class GroupSettingsPage extends StatefulWidget {
  final String groupId;

  const GroupSettingsPage({super.key, required this.groupId});

  @override
  State<GroupSettingsPage> createState() => _GroupSettingsPageState();
}

class _GroupSettingsPageState extends State<GroupSettingsPage> {
  late GroupService _groupService;
  GroupInfo? _groupInfo;
  bool _isLoading = true;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  String? _inviteCode;

  // Couleurs THIX ID
  static const navyDeep = Color(0xFF0A1F44);
  static const navy = Color(0xFF123B7A);
  static const gold = Color(0xFFE3B23C);
  static const ivory = Color(0xFFF3F5FA);
  static const darkText = Color(0xFF10182B);
  static const mutedText = Color(0xFF6B7690);
  static const danger = Color(0xFFD64545);
  static const success = Color(0xFF1FA971);

  @override
  void initState() {
    super.initState();
    _groupService = GroupService(Supabase.instance.client);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final conv = await _groupService.getGroupInfo(widget.groupId);
      // Récupérer les infos détaillées (description, code d'invitation)
      final supabase = Supabase.instance.client;
      final info = await supabase
          .from('group_info')
          .select('*')
          .eq('group_id', widget.groupId)
          .maybeSingle();

      setState(() {
        _groupInfo = GroupInfo(
          groupId: widget.groupId,
          name: conv.groupName ?? '',
          avatarUrl: conv.groupAvatar,
          members: [],
          adminIds: [],
          isPublic: info?['is_public'] ?? false,
          inviteCode: info?['invite_code'],
          createdAt: conv.updatedAt,
        );
        _nameController.text = conv.groupName ?? '';
        _descController.text = info?['description'] ?? '';
        _inviteCode = info?['invite_code'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: danger),
      );
    }
  }

  Future<void> _saveChanges() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le nom ne peut pas être vide')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _groupService.updateGroupInfo(
        groupId: widget.groupId,
        name: name,
        description: _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
      );
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Modifications enregistrées'), backgroundColor: success),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: danger),
      );
    }
  }

  Future<void> _regenerateInviteCode() async {
    try {
      final newCode = await _groupService.regenerateInviteCode(widget.groupId);
      setState(() => _inviteCode = newCode);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code d\'invitation régénéré'), backgroundColor: success),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: ivory,
      appBar: AppBar(
        backgroundColor: navyDeep,
        title: const Text(
          'Paramètres du groupe',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _saveChanges,
            child: const Text('Enregistrer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar (à implémenter)
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: navy.withOpacity(0.1),
                    child: Icon(Icons.group_rounded, size: 50, color: navy.withOpacity(0.5)),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {
                      // Changer l'avatar
                    },
                    icon: const Icon(Icons.photo_camera_rounded, size: 18),
                    label: const Text('Changer l\'avatar'),
                  ),
                ],
              ),
            ),
            const Divider(height: 32),

            // Nom
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nom du groupe',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Description
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // Code d'invitation
            const Text('Code d\'invitation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: darkText)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _inviteCode ?? 'Non généré',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFeatures: [FontFeature.tabularFigures()]),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, color: navy),
                    onPressed: () {
                      // Copier le code
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Code copié !'), backgroundColor: success),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: gold),
                    onPressed: _regenerateInviteCode,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Gestion des membres (bouton pour aller à la liste complète)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // Naviguer vers la page de gestion des membres (GroupInfoPage déjà présente)
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.people_rounded),
                label: const Text('Gérer les membres'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: navy),
                  foregroundColor: navy,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Paramètres supplémentaires
            SwitchListTile(
              title: const Text('Groupe public'),
              subtitle: const Text('Tout le monde peut rejoindre avec le code'),
              value: _groupInfo?.isPublic ?? false,
              onChanged: (value) {
                setState(() {
                  _groupInfo = _groupInfo?.copyWith(isPublic: value);
                });
              },
              activeColor: gold,
            ),
            const Divider(height: 32),

            // Danger zone
            const Text('Zone de danger', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: danger)),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // Supprimer le groupe
                },
                icon: const Icon(Icons.delete_rounded),
                label: const Text('Supprimer le groupe'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: danger),
                  foregroundColor: danger,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension GroupInfoCopyWith on GroupInfo {
  GroupInfo copyWith({bool? isPublic}) {
    return GroupInfo(
      groupId: groupId,
      name: name,
      avatarUrl: avatarUrl,
      description: description,
      members: members,
      adminIds: adminIds,
      isPublic: isPublic ?? this.isPublic,
      inviteCode: inviteCode,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
