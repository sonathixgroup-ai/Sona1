// lib/presentation/network/services/message_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/presentation/network/models/message_model.dart';
import 'package:thix_id/presentation/network/models/conversation_model.dart';

class MessageService {
  final SupabaseClient supabase;

  MessageService({SupabaseClient? client}) : supabase = client ?? Supabase.instance.client;

  Future<String> createConversation({required List<String> participantProfileIds, String? title}) async {
    // call rpc create_conversation
    final res = await supabase.rpc('create_conversation', params: {'p_title': title, 'p_participants': participantProfileIds}).execute();
    if (res.error != null) throw Exception(res.error!.message);
    return res.data as String;
  }

  Future<List<ConversationModel>> fetchConversations({int limit = 50}) async {
    final res = await supabase.from('conversations').select().order('created_at', ascending: false).limit(limit).execute();
    final data = res.data as List<dynamic>? ?? [];
    return data.map((e) => ConversationModel.fromMap(e as Map<String, dynamic>)).toList();
  }

  Future<List<MessageModel>> fetchMessages({required String conversationId, int limit = 100}) async {
    final res = await supabase.from('messages').select().eq('conversation_id', conversationId).order('created_at', ascending: true).limit(limit).execute();
    final data = res.data as List<dynamic>? ?? [];
    return data.map((e) => MessageModel.fromMap(e as Map<String, dynamic>)).toList();
  }

  RealtimeSubscription streamMessages({required String conversationId, required void Function(List<MessageModel>) onData}) {
    final channelName = 'public:messages:$conversationId';
    final channel = supabase.channel(channelName);
    channel.on(RealtimeListenTypes.postgresChanges, ChannelFilter(event: '*', schema: 'public', table: 'messages', filter: 'conversation_id=eq.$conversationId'), (payload, {ref}) async {
      try {
        final messages = await fetchMessages(conversationId: conversationId);
        onData(messages);
      } catch (e) {
        // ignore
      }
    }).subscribe();
    return channel;
  }

  Future<MessageModel> sendMessage({required String conversationId, required String senderProfileId, String? content, Map<String, dynamic>? media}) async {
    final insert = await supabase.from('messages').insert({'conversation_id': conversationId, 'sender_profile_id': senderProfileId, 'content': content, 'media': media}).select().single();
    return MessageModel.fromMap(insert as Map<String, dynamic>);
  }
}
