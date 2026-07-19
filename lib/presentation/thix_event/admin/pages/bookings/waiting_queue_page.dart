// lib/presentation/thix_event/admin/pages/bookings/waiting_queue_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/admin_app_bar.dart';
import '../../widgets/admin_paginated_list.dart';
import '../../providers/admin_state.dart';
import '../../services/admin_event_service.dart';

class WaitingQueuePage extends StatefulWidget {
  const WaitingQueuePage({super.key});

  @override
  State<WaitingQueuePage> createState() => _WaitingQueuePageState();
}

class _WaitingQueuePageState extends State<WaitingQueuePage> {
  AdminPaginatedState<Map<String, dynamic>> _state = const AdminPaginatedState<Map<String, dynamic>>();
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _load(refresh: true);
    _subscribeRealtime();
  }

  @override
  void dispose() {
    if (_channel != null) {
      Supabase.instance.client.removeChannel(_channel!);
    }
    super.dispose();
  }

  void _subscribeRealtime() {
    _channel = Supabase.instance.client
        .channel('admin_waiting_queue')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'event_waiting_queue',
          callback: (payload) {
            if (mounted) _load(refresh: true);
          },
        )
        .subscribe();
  }

  Future<void> _load({bool refresh = false, bool loadMore = false}) async {
    if (refresh) {
      setState(() => _state = _state.copyWith(
            status: AdminStatus.loading,
            currentPage: 0,
            hasMore: true,
            items: [],
          ));
    }
    if (loadMore) {
      if (!_state.hasMore || _state.isLoadingMore) return;
      setState(() => _state = _state.copyWith(status: AdminStatus.loadingMore));
    }

    try {
      final page = refresh ? 0 : _state.currentPage + (loadMore ? 1 : 0);
      final from = page * 50;
      final to = from + 50 - 1;

      final res = await Supabase.instance.client
          .from('event_waiting_queue')
          .select('*, events(title)')
          .order('created_at', ascending: true)
          .range(from, to);

      final data = List<Map<String, dynamic>>.from(res as List);

      setState(() {
        _state = AdminPaginatedState<Map<String, dynamic>>(
          items: refresh ? data : [..._state.items, ...data],
          status: data.isEmpty && refresh ? AdminStatus.empty : AdminStatus.success,
          hasMore: data.length == 50,
          currentPage: page,
        );
      });
    } catch (e) {
      setState(() => _state = _state.copyWith(status: AdminStatus.error, error: e.toString()));
    }
  }

  Future<void> _notifyUser(String queueId) async {
    try {
      await Supabase.instance.client
          .from('event_waiting_queue')
          .update({'status': 'notified', 'expires_at': DateTime.now().add(const Duration(minutes: 10)).toIso8601String()})
          .eq('id', queueId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Utilisateur notifié (10 min pour réserver)')));
        _load(refresh: true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      appBar: AdminAppBar(
        title: 'File d\'attente • Live (${_state.items.length})',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
            onPressed: () => _load(refresh: true),
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF5FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD0DDFF)),
            ),
            child: const Row(
              children: [
                Icon(Icons.live_tv_rounded, size: 14, color: Color(0xFF2D6CDF)),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Temps réel activé • La liste se met à jour automatiquement quand un user rejoint la queue',
                    style: TextStyle(fontSize: 10, color: Color(0xFF0A1F44), fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: AdminPaginatedList<Map<String, dynamic>>(
              state: _state,
              onRefresh: () => _load(refresh: true),
              onLoadMore: () => _load(loadMore: true),
              itemBuilder: (ctx, item, i) {
                final eventTitle = item['events']?['title'] ?? 'Event';
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE7EEFC)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(color: Color(0xFF0A1F44), shape: BoxShape.circle),
                        child: Center(child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800))),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(eventTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
                            Text('User: ${item['user_id'].toString().substring(0, 8)}... • ${item['requested_quantity']} place(s) • ${item['status']}',
                                style: const TextStyle(fontSize: 10, color: Color(0xFF7386A8))),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _notifyUser(item['id']),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2D6CDF),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          minimumSize: Size.zero,
                        ),
                        child: const Text('Notifier', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
