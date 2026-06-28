// lib/presentation/network/services/notification_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/presentation/network/models/notification_model.dart';

class NotificationService {
  final SupabaseClient supabase;

  NotificationService({SupabaseClient? client}) : supabase = client ?? Supabase.instance.client;

  Future<void> createNotification({required String userId, required String actorId, required String type, Map<String, dynamic>? data}) async {
    await supabase.rpc('create_notification', params: {'p_user_id': userId, 'p_actor_id': actorId, 'p_type': type, 'p_data': data ?? {}}).execute();
  }

  Future<List<NotificationModel>> fetchNotifications({required String userId, int limit = 50}) async {
    final res = await supabase.from('notifications').select().eq('user_id', userId).order('created_at', ascending: false).limit(limit).execute();
    final data = res.data as List<dynamic>? ?? [];
    return data.map((e) => NotificationModel.fromMap(e as Map<String, dynamic>)).toList();
  }

  Future<void> markRead(String notificationId) async {
    await supabase.rpc('mark_notification_read', params: {'nid': notificationId}).execute();
  }

  RealtimeSubscription streamNotifications({required String userId, required void Function(List<NotificationModel>) onData}) {
    final channelName = 'public:notifications:$userId';
    final channel = supabase.channel(channelName);
    channel.on(RealtimeListenTypes.postgresChanges, ChannelFilter(event: '*', schema: 'public', table: 'notifications', filter: 'user_id=eq.$userId'), (payload, {ref}) async {
      try {
        final items = await fetchNotifications(userId: userId);
        onData(items);
      } catch (e) {
        // ignore
      }
    }).subscribe();
    return channel;
  }

  Future<void> registerDeviceToken({required String profileId, required String provider, required String token}) async {
    await supabase.from('device_tokens').insert({'profile_id': profileId, 'provider': provider, 'token': token}).execute();
  }
}
