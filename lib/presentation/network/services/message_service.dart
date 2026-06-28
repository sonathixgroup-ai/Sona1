// lib/presentation/network/services/message_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/presentation/network/models/message_model.dart';
import 'package:thix_id/presentation/network/models/conversation_model.dart';

class MessageService {
  final SupabaseClient supabase;

  MessageService({SupabaseClient? client}) : supabase = client ?? Supabase.instance.client;

  Future<String> createConversation({required List<String> participantProfileIds, String? title}) async {
    try {
      final data = await supabase.rpc('create_conversation', params: {
        'p_title': title,
        'p_participants': participantProfileIds,
      });
      return data is String ? data : (data as dynamic).toString();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<List<ConversationModel>> fetchConversations({int limit = 50}) async {
    final data = await supabase
        .from('conversations')
        .select()
        .order('created_at', ascending: false)
        .limit(limit) as List<dynamic>;
    return data.map((e) => ConversationModel.fromMap(e as Map<String, dynamic>)).toList();
  }

  Future<List<MessageModel>> fetchMessages({required String conversationId, int limit = 100}) async {
    final data = await supabase
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true)
        .limit(limit) as List<dynamic>;
    return data.map((e) => MessageModel.fromMap(e as Map<String, dynamic>)).toList();
  }

  RealtimeChannel streamMessages({required String conversationId, required void Function(List<MessageModel>) onData}) {
    final channelName = 'public:messages:$conversationId';
    final channel = supabase.channel(channelName);
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'conversation_id', value: conversationId),
          callback: (payload) async {
            try {
              final messages = await fetchMessages(conversationId: conversationId);
              onData(messages);
            } catch (_) {}
          },
        )
        .subscribe();
    return channel;
  }

  Future<MessageModel> sendMessage({required String conversationId, required String senderProfileId, String? content, Map<String, dynamic>? media}) async {
    final insert = await supabase.from('messages').insert({'conversation_id': conversationId, 'sender_profile_id': senderProfileId, 'content': content, 'media': media}).select().single();
    return MessageModel.fromMap(insert as Map<String, dynamic>);
  }
}
