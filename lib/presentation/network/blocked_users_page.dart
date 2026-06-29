import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BlockedUsersPage extends StatefulWidget {
  const BlockedUsersPage({super.key});

  @override
  State<BlockedUsersPage> createState() => _BlockedUsersPageState();
}

class _BlockedUsersPageState extends State<BlockedUsersPage> {
  List<Map<String, dynamic>> _blockedUsers = [];
  bool _loading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    if (mounted) setState(() => _loading = true);

    try {
      final supabase = Supabase.instance.client;
      final currentUserId = supabase.auth.currentUser?.id;

      if (currentUserId == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final response = await supabase
          .from('blocked_users')
          .select('''
            blocked:profiles!blocked_user_id (
              id,
              display_name,
              avatar_url,
              title
            )
          ''')
          .eq('user_id', currentUserId);

      if (!mounted) return;

      setState(() {
        _blockedUsers = (response as List)
            .map((e) => e['blocked'] as Map<String, dynamic>)
            .toList();
      });
    } catch (e) {
      debugPrint('Error loading blocked users: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _unblockUser(String userId, String userName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Débloquer l\'utilisateur'),
        content: Text('Voulez-vous vraiment débloquer $userName ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('Débloquer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);

    try {
      final supabase = Supabase.instance.client;
      final currentUserId = supabase.auth.currentUser?.id;

      if (currentUserId == null) return;

      await supabase
          .from('blocked_users')
          .delete()
          .eq('user_id', currentUserId)
          .eq('blocked_user_id', userId);

      if (!mounted) return;

      setState(() {
        _blockedUsers.removeWhere((u) => u['id'] == userId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Utilisateur débloqué'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _unblockAllUsers() async {
    if (_blockedUsers.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tout débloquer'),
        content: const Text('Voulez-vous vraiment débloquer tous les utilisateurs ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Tout débloquer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);

    try {
      final supabase = Supabase.instance.client;
      final currentUserId = supabase.auth.currentUser?.id;

      if (currentUserId == null) return;

      await supabase
          .from('blocked_users')
          .delete()
          .eq('user_id', currentUserId);

      if (mounted) {
        setState(() => _blockedUsers.clear());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tous les utilisateurs ont été débloqués'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Utilisateurs bloqués',
          style: TextStyle(color: Color(0xFF0B1B3D), fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0B1B3D)),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_blockedUsers.isNotEmpty && !_loading)
            TextButton(
              onPressed: _isProcessing ? null : _unblockAllUsers,
              child: Text(
                'Tout débloquer',
                style: TextStyle(color: _isProcessing ? Colors.grey : const Color(0xFFD4AF37)),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _blockedUsers.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.block, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Aucun utilisateur bloqué'),
                      SizedBox(height: 8),
                      Text(
                        'Les utilisateurs que vous bloquerez apparaîtront ici',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _blockedUsers.length,
                  itemBuilder: (context, index) {
                    return _buildBlockedUserTile(_blockedUsers[index]);
                  },
                ),
    );
  }

  Widget _buildBlockedUserTile(Map<String, dynamic> user) {
    final avatarUrl = user['avatar_url'] as String?;
    final displayName = (user['display_name'] as String?) ?? 'Utilisateur';
    final title = user['title'] as String?;
    final userId = user['id'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null || avatarUrl.isEmpty ? const Icon(Icons.person) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                if (title != null && title.isNotEmpty)
                  Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: _isProcessing ? null : () => _unblockUser(userId, displayName),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.green),
            ),
            child: const Text('Débloquer', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }
}
