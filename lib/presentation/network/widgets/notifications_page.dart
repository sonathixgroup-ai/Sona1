// lib/presentation/network/widgets/notifications_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thix_id/presentation/network/services/notification_service.dart';
import 'package:thix_id/presentation/network/models/notification_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  static Future<void> open(BuildContext context) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsPage()));
  }

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<NotificationModel> _items = [];
  bool _loading = true;
  RealtimeChannel? _sub;

  @override
  void initState() {
    super.initState();
    _load();
    final supabase = Supabase.instance.client;
    final uid = supabase.auth.currentUser?.id;
    if (uid != null) {
      _sub = context.read<NotificationService>().streamNotifications(userId: uid, onData: (items) {
        if (mounted) setState(() => _items = items);
      });
    }
  }

  @override
  void dispose() {
    _sub?.unsubscribe();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final supabase = Supabase.instance.client;
      final uid = supabase.auth.currentUser?.id;
      if (uid != null) {
        final items = await context.read<NotificationService>().fetchNotifications(userId: uid);
        if (mounted) setState(() => _items = items);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(child: Text('Aucune notification'))
              : ListView.separated(
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final n = _items[i];
                    return ListTile(
                      leading: Icon(n.type == 'message' ? Icons.message : Icons.notifications),
                      title: Text(n.type ?? 'Notification'),
                      subtitle: Text(n.data != null ? (n.data!['text']?.toString() ?? '') : ''),
                      trailing: n.read ? null : Container(width: 10, height: 10, decoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle)),
                      onTap: () async {
                        await context.read<NotificationService>().markRead(n.id);
                        // navigate depending on type
                      },
                    );
                  },
                ),
    );
  }
}
