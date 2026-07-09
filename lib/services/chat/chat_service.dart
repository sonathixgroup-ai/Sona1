import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../models/chat/chat_message.dart';
import '../../models/chat/chat_conversation.dart';
import '../../models/chat/chat_participant.dart';
import '../../models/chat/user_status.dart';

class ChatService {
  final SupabaseClient _supabase;

  ChatService(this._supabase);

  String get currentUserId => _supabase.auth.currentUser?.id ?? '';

  // ---------- CONVERSATIONS ----------
  Future<List<ChatConversation>> getConversations() async {
    try {
      final uid = currentUserId;
      if (uid.isEmpty) return [];

      final participantResponse = await _supabase
          .from('conversation_participants')
          .select('conversation_id')
          .eq('user_id', uid);

      if (participantResponse.isEmpty) return [];

      final conversationIds = (participantResponse as List)
          .map((e) => e['conversation_id'] as String)
          .toList();

      final response = await _supabase
          .from('conversations')
          .select('*')
          .inFilter('id', conversationIds)
          .order('updated_at', ascending: false);

      final conversations = <ChatConversation>[];

      for (var conv in response as List) {
        final participants = await _supabase
            .from('conversation_participants')
            .select('user_id')
            .eq('conversation_id', conv['id']);

        final participantIds = (participants as List)
            .map((e) => e['user_id'] as String)
            .toList();

        final lastMsg = await _supabase
            .from('messages')
            .select('*')
            .eq('conversation_id', conv['id'])
            .eq('is_deleted', false)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

        ChatMessage? lastMessage;
        if (lastMsg != null) {
          lastMessage = ChatMessage.fromJson(lastMsg);
        }

        final unread = await _supabase
            .from('messages')
            .select('id')
            .eq('conversation_id', conv['id'])
            .eq('is_read', false)
            .neq('sender_id', uid);

        conversations.add(ChatConversation(
          id: conv['id'],
          isGroup: conv['is_group'] ?? false,
          groupName: conv['group_name'],
          groupAvatar: conv['group_avatar'],
          participantIds: participantIds,
          lastMessage: lastMessage,
          unreadCount: (unread as List).length,
          updatedAt: DateTime.parse(conv['updated_at']),
          isPinned: conv['is_pinned'] ?? false,
        ));
      }

      return conversations;
    } catch (e) {
      debugPrint('❌ getConversations: $e');
      return [];
    }
  }

  Future<ChatConversation> createConversation({
    required List<String> participantIds,
    bool isGroup = false,
    String? groupName,
    String? groupAvatar,
  }) async {
    final uid = currentUserId;
    if (uid.isEmpty) throw Exception('Not logged in');

    if (!participantIds.contains(uid)) {
      participantIds = [...participantIds, uid];
    }

    // Vérifier l'existant pour une conversation individuelle
    if (!isGroup && participantIds.length == 2) {
      final otherId = participantIds.firstWhere((id) => id != uid);
      final existing = await _supabase
          .from('conversation_participants')
          .select('conversation_id')
          .eq('user_id', uid);

      final convIds = (existing as List).map((e) => e['conversation_id'] as String).toList();
      for (var cid in convIds) {
        final other = await _supabase
            .from('conversation_participants')
            .select('user_id')
            .eq('conversation_id', cid)
            .neq('user_id', uid);
        if ((other as List).length == 1 && other[0]['user_id'] == otherId) {
          final convData = await _supabase
              .from('conversations')
              .select('*')
              .eq('id', cid)
              .single();
          return ChatConversation.fromJson(convData);
        }
      }
    }

    final response = await _supabase.from('conversations').insert({
      'is_group': isGroup,
      'group_name': groupName,
      'group_avatar': groupAvatar,
      'updated_at': DateTime.now().toIso8601String(),
      'is_pinned': false,
    }).select().single();

    final conversationId = response['id'];

    for (var pid in participantIds) {
      await _supabase.from('conversation_participants').insert({
        'conversation_id': conversationId,
        'user_id': pid,
        'role': pid == uid ? 'admin' : 'member',
        'last_read_at': DateTime.now().toIso8601String(),
      });
    }

    return ChatConversation.fromJson({
      ...response,
      'participant_ids': participantIds,
    });
  }

  Future<void> addParticipant(String conversationId, String userId) async {
    await _supabase.from('conversation_participants').insert({
      'conversation_id': conversationId,
      'user_id': userId,
      'role': 'member',
      'last_read_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> removeParticipant(String conversationId, String userId) async {
    await _supabase
        .from('conversation_participants')
        .delete()
        .eq('conversation_id', conversationId)
        .eq('user_id', userId);
  }

  Future<void> togglePinned(String conversationId) async {
    final conv = await _supabase
        .from('conversations')
        .select('is_pinned')
        .eq('id', conversationId)
        .single();
    await _supabase
        .from('conversations')
        .update({'is_pinned': !(conv['is_pinned'] ?? false)})
        .eq('id', conversationId);
  }

  // ---------- MESSAGES ----------
  Future<List<ChatMessage>> getMessages(
    String conversationId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final uid = currentUserId;
      if (uid.isEmpty) return [];

      final response = await _supabase
          .from('messages')
          .select('*')
          .eq('conversation_id', conversationId)
          .eq('is_deleted', false)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List).map((e) => ChatMessage.fromJson(e)).toList();
    } catch (e) {
      debugPrint('❌ getMessages: $e');
      return [];
    }
  }

  Future<ChatMessage> sendMessage({
    required String conversationId,
    required String content,
    String? mediaUrl,
    String? mediaType,
    String? replyToId,
    bool isEphemeral = false,
    int? ephemeralDuration,
    bool isCodeSnippet = false,
    String? codeLanguage,
    String? codeContent,
  }) async {
    final uid = currentUserId;
    if (uid.isEmpty) throw Exception('Not logged in');

    final now = DateTime.now();
    final deleteAt = isEphemeral && ephemeralDuration != null
        ? now.add(Duration(seconds: ephemeralDuration))
        : null;

    final response = await _supabase.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': uid,
      'content': content,
      'created_at': now.toIso8601String(),
      'media_url': mediaUrl,
      'media_type': mediaType,
      'reply_to_id': replyToId,
      'is_read': false,
      'is_delivered': false,
      'is_deleted': false,
      'is_ephemeral': isEphemeral,
      'ephemeral_duration': ephemeralDuration,
      'delete_at': deleteAt?.toIso8601String(),
      'is_code_snippet': isCodeSnippet,
      'code_language': codeLanguage,
      'code_content': codeContent,
    }).select().single();

    await _supabase
        .from('conversations')
        .update({'updated_at': now.toIso8601String()})
        .eq('id', conversationId);

    return ChatMessage.fromJson(response);
  }

  Future<void> markAsRead(String conversationId) async {
    final uid = currentUserId;
    if (uid.isEmpty) return;

    await _supabase
        .from('messages')
        .update({'is_read': true})
        .eq('conversation_id', conversationId)
        .neq('sender_id', uid)
        .eq('is_read', false);

    await _supabase
        .from('conversation_participants')
        .update({'last_read_at': DateTime.now().toIso8601String()})
        .eq('conversation_id', conversationId)
        .eq('user_id', uid);
  }

  Future<void> deleteMessage(String messageId) async {
    final uid = currentUserId;
    if (uid.isEmpty) throw Exception('Not logged in');

    final msg = await _supabase
        .from('messages')
        .select('sender_id')
        .eq('id', messageId)
        .single();

    if (msg['sender_id'] != uid) {
      throw Exception('You cannot delete this message');
    }

    await _supabase
        .from('messages')
        .update({'is_deleted': true})
        .eq('id', messageId);
  }

  Future<void> toggleReaction(String messageId, String reaction) async {
    final uid = currentUserId;
    if (uid.isEmpty) return;

    final existing = await _supabase
        .from('message_reactions')
        .select('id')
        .eq('message_id', messageId)
        .eq('user_id', uid)
        .maybeSingle();

    if (existing != null) {
      await _supabase
          .from('message_reactions')
          .delete()
          .eq('message_id', messageId)
          .eq('user_id', uid);
    } else {
      await _supabase.from('message_reactions').insert({
        'message_id': messageId,
        'user_id': uid,
        'reaction': reaction,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<ChatMessage?> getMessageById(String messageId) async {
    try {
      final response = await _supabase
          .from('messages')
          .select('*')
          .eq('id', messageId)
          .eq('is_deleted', false)
          .maybeSingle();
      if (response == null) return null;
      return ChatMessage.fromJson(response);
    } catch (e) {
      debugPrint('❌ getMessageById: $e');
      return null;
    }
  }
}
