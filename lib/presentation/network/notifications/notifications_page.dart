import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';  // ← AJOUTER CET IMPORT
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/services/network_service.dart';
import 'package:thix_id/models/network_notification.dart';  // ← AJOUTER CET IMPORT

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late NetworkService _networkService;
  List<NetworkNotification> _notifications = [];  // ✅ CORRIGÉ: utiliser le modèle
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _networkService = NetworkService(Supabase.instance.client);
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _loading = true);
    try {
      final notifs = await _networkService.getNotifications();
      setState(() => _notifications = notifs);
      await _networkService.markAllNotificationsAsRead();
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    } finally {
      setState(() => _loading = false);
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
          'Notifications',
          style: TextStyle(color: Color(0xFF0B1B3D), fontWeight: FontWeight.bold),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Aucune notification'),
                      Text('Les notifications apparaîtront ici'),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.separated(
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) => const Divider(height: 0),
                    itemBuilder: (context, index) {
                      final notif = _notifications[index];
                      return _buildNotificationTile(notif);
                    },
                  ),
                ),
    );
  }

  Widget _buildNotificationTile(NetworkNotification notif) {  // ✅ CORRIGÉ: utiliser le modèle
    IconData icon;
    Color iconColor;
    
    if (notif.type == 'like') {
      icon = Icons.favorite;
      iconColor = Colors.red;
    } else if (notif.type == 'comment') {
      icon = Icons.comment;
      iconColor = Colors.blue;
    } else if (notif.type == 'connection_request') {
      icon = Icons.person_add;
      iconColor = Colors.green;
    } else if (notif.type == 'connection_accepted') {
      icon = Icons.people;
      iconColor = const Color(0xFFD4AF37);
    } else {
      icon = Icons.notifications;
      iconColor = Colors.grey;
    }

    return GestureDetector(
      onTap: () => _handleNotificationTap(notif),
      child: Container(
        padding: const EdgeInsets.all(16),
        color: notif.isRead == false ? Colors.white : null,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notif.title,
                    style: TextStyle(
                      fontWeight: notif.isRead == false ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif.body,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(notif.createdAt),
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            if (notif.isRead == false)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFD4AF37),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _handleNotificationTap(NetworkNotification notif) {  // ✅ CORRIGÉ: utiliser le modèle
    // Navigation selon le type
    if (notif.type == 'connection_request' && notif.actorId != null) {
      context.push('/network/profile/${notif.actorId}');  // ✅ CORRIGÉ: context.go ou context.push
    } else if (notif.postId != null) {
      context.push('/network/post/${notif.postId}');  // ✅ CORRIGÉ: context.go ou context.push
    }
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (diff.inDays > 0) {
      return 'il y a ${diff.inDays}j';
    } else if (diff.inHours > 0) {
      return 'il y a ${diff.inHours}h';
    } else if (diff.inMinutes > 0) {
      return 'il y a ${diff.inMinutes}min';
    } else {
      return 'à l\'instant';
    }
  }
}
