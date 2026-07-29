import 'dart:async';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../models/chat/chat_message.dart';
import '../../models/chat/chat_conversation.dart';
import '../../models/chat/user_status.dart';
import '../../models/chat/group_info.dart';
import 'package:thix_id/models/chat/sentiment.dart';

class ChatService {
  final SupabaseClient _supabase;

  ChatService(this._supabase);

  String get currentUserId => _supabase.auth.currentUser?.id ?? '';

  static String _resolveDisplayName(Map<String, dynamic>? profile) {
    if (profile == null) return 'Utilisateur inconnu';
    final displayName = profile['display_name'] as String?;
    if (displayName != null && displayName.trim().isNotEmpty) return displayName;
    final fullName = profile['full_name'] as String?;
    if (fullName != null && fullName.trim().isNotEmpty) return fullName;
    return 'Utilisateur inconnu';
  }

  // ============================================================
  // CONVERSATIONS
  // ============================================================

  Future<int> getTotalUnreadCount() async {
    try {
      final uid = currentUserId;
      if (uid.isEmpty) return 0;

      final participantResponse = await _supabase
          .from('conversation_participants')
          .select('conversation_id')
          .eq('user_id', uid);

      if (participantResponse.isEmpty) return 0;

      final conversationIds = (participantResponse as List)
          .map((e) => e['conversation_id'] as String)
          .toList();

      final unreadResponse = await _supabase
          .from('messages')
          .select('id')
          .inFilter('conversation_id', conversationIds)
          .eq('is_read', false)
          .neq('sender_id', uid);

      return (unreadResponse as List).length;
    } catch (e) {
      debugPrint('❌ getTotalUnreadCount: $e');
      return 0;
    }
  }

  Future<List<ChatConversation>> getConversations({int limit = 20, int offset = 0}) async {
    try {
      final uid = currentUserId;
      if (uid.isEmpty) return [];

      final participantResponse = await _supabase
          .from('conversation_participants')
          .select('conversation_id')
          .eq('user_id', uid);

      if (participantResponse.isEmpty) return [];

      final allConversationIds = (participantResponse as List)
          .map((e) => e['conversation_id'] as String)
          .toList();

      final response = await _supabase
          .from('conversations')
          .select('''
            *,
            conversation_participants!inner (
              user_id,
              role,
              profiles!user_id (
                display_name,
                full_name,
                avatar_url
              )
            )
          ''')
          .inFilter('id', allConversationIds)
          .order('updated_at', ascending: false)
          .range(offset, offset + limit - 1);

      final paginatedConversations = response as List;
      if (paginatedConversations.isEmpty) return [];

      final pageConversationIds = paginatedConversations.map((c) => c['id'] as String).toList();

      final unreadResponse = await _supabase
          .from('messages')
          .select('conversation_id')
          .inFilter('conversation_id', pageConversationIds)
          .eq('is_read', false)
          .neq('sender_id', uid);

      final unreadCounts = <String, int>{};
      for (var msg in unreadResponse as List) {
        final cid = msg['conversation_id'] as String;
        unreadCounts[cid] = (unreadCounts[cid] ?? 0) + 1;
      }

      // 💡 NOTE ARCHITECTURE : Pour passer à 100 000 utilisateurs, il faudra remplacer 
      // ce bloc Future.wait par une "Postgres View" ou un "RPC" côté base de données
      // qui renvoie directement le dernier message joint à la conversation.
      final futures = paginatedConversations.map((conv) async {
        final cid = conv['id'] as String;
        final participants = conv['conversation_participants'] as List;
        final participantIds = participants.map((p) => p['user_id'] as String).toList();

        String? otherName, otherAvatar;
        if (!(conv['is_group'] ?? false) && participants.length == 2) {
          final other = participants.firstWhere((p) => p['user_id'] != uid, orElse: () => null);
          if (other != null) {
            final profile = other['profiles'] as Map<String, dynamic>?;
            otherName = _resolveDisplayName(profile);
            otherAvatar = profile?['avatar_url'] as String?;
          }
        }

        final lastMsg = await _supabase
            .from('messages')
            .select('*, profiles!sender_id(display_name, full_name, avatar_url)')
            .eq('conversation_id', cid)
            .eq('is_deleted', false)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

        ChatMessage? lastMessage;
        if (lastMsg != null) {
          final profile = lastMsg['profiles'] as Map<String, dynamic>?;
          lastMsg['sender_name'] = _resolveDisplayName(profile);
          lastMsg['sender_avatar'] = profile?['avatar_url'];
          lastMessage = ChatMessage.fromJson(lastMsg);
        }

        return ChatConversation(
          id: cid,
          isGroup: conv['is_group'] ?? false,
          groupName: conv['group_name'],
          groupAvatar: conv['group_avatar'],
          participantIds: participantIds,
          otherParticipantName: otherName ?? 'Utilisateur inconnu',
          otherParticipantAvatar: otherAvatar,
          lastMessage: lastMessage,
          unreadCount: unreadCounts[cid] ?? 0,
          updatedAt: DateTime.parse(conv['updated_at']),
          isPinned: conv['is_pinned'] ?? false,
        );
      });

      final conversations = await Future.wait(futures);
      conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
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

    if (!participantIds.contains(uid)) participantIds = [...participantIds, uid];

    // Vérification optimisée d'une conversation 1v1 existante
    if (!isGroup && participantIds.length == 2) {
      final otherId = participantIds.firstWhere((id) => id != uid);
      // RPC recommandé ici dans le futur (ex: get_direct_conversation(uid1, uid2))
      final existing = await _supabase.from('conversation_participants').select('conversation_id').eq('user_id', uid);
      final convIds = (existing as List).map((e) => e['conversation_id'] as String).toList();
      
      for (var cid in convIds) {
        final other = await _supabase.from('conversation_participants').select('user_id').eq('conversation_id', cid).neq('user_id', uid);
        if ((other as List).length == 1 && other[0]['user_id'] == otherId) {
          final convData = await _supabase.from('conversations').select('*').eq('id', cid).single();
          final otherProfile = await _supabase.from('profiles').select('display_name, full_name, avatar_url').eq('id', otherId).single();
          return ChatConversation.fromJson({
            ...convData,
            'other_participant_name': _resolveDisplayName(otherProfile),
            'other_participant_avatar': otherProfile['avatar_url'],
          });
        }
      }
    }

    final String conversationId = const Uuid().v4();

    await _supabase.from('conversations').insert({
      'id': conversationId,
      'is_group': isGroup,
      'group_name': groupName,
      'group_avatar': groupAvatar,
      'updated_at': DateTime.now().toIso8601String(),
    });

    // 💡 Optimisation: Insertion en parallèle pour l'atomicité de l'action
    await Future.wait(participantIds.map((pid) => _supabase.from('conversation_participants').insert({
      'conversation_id': conversationId,
      'user_id': pid,
      'role': pid == uid ? 'admin' : 'member',
      'last_read_at': DateTime.now().toIso8601String(),
    })));

    if (isGroup) {
      await _supabase.from('group_info').upsert({
        'group_id': conversationId,
        'name': groupName ?? 'Groupe',
        'is_public': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    }

    String? otherName, otherAvatar;
    if (!isGroup && participantIds.length == 2) {
      final otherId = participantIds.firstWhere((id) => id != uid);
      final otherProfile = await _supabase.from('profiles').select('display_name, full_name, avatar_url').eq('id', otherId).single();
      otherName = _resolveDisplayName(otherProfile);
      otherAvatar = otherProfile['avatar_url'];
    }

    return ChatConversation.fromJson({
      'id': conversationId,
      'is_group': isGroup,
      'group_name': groupName,
      'group_avatar': groupAvatar,
      'updated_at': DateTime.now().toIso8601String(),
      'is_pinned': false,
      'participant_ids': participantIds,
      'other_participant_name': otherName,
      'other_participant_avatar': otherAvatar,
    });
  }

  // ============================================================
  // MESSAGES
  // ============================================================

  Future<List<ChatMessage>> getMessages(String conversationId, {int limit = 50, int offset = 0}) async {
    try {
      final response = await _supabase
          .from('messages')
          .select('*, profiles!sender_id(display_name, full_name, avatar_url)')
          .eq('conversation_id', conversationId)
          .eq('is_deleted', false)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List).map((e) {
        final profile = e['profiles'] as Map<String, dynamic>?;
        e['sender_name'] = _resolveDisplayName(profile);
        e['sender_avatar'] = profile?['avatar_url'];
        return ChatMessage.fromJson(e);
      }).toList();
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
    String? mediaName,
    int? mediaSize,
    String? replyToId,
    bool isEphemeral = false,
    int? ephemeralDuration,
  }) async {
    final uid = currentUserId;
    if (uid.isEmpty) throw Exception('Not logged in');

    final now = DateTime.now();
    final deleteAt = isEphemeral && ephemeralDuration != null ? now.add(Duration(seconds: ephemeralDuration)) : null;

    final response = await _supabase.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': uid,
      'content': content,
      'created_at': now.toIso8601String(),
      'media_url': mediaUrl,
      'media_type': mediaType,
      'reply_to_id': replyToId,
      'is_ephemeral': isEphemeral,
      'ephemeral_duration': ephemeralDuration,
      'delete_at': deleteAt?.toIso8601String(),
    }).select('*, profiles!sender_id(display_name, full_name, avatar_url)').single();

    final profile = response['profiles'] as Map<String, dynamic>?;
    response['sender_name'] = _resolveDisplayName(profile);
    response['sender_avatar'] = profile?['avatar_url'];

    // 💡 Avertissement: Ceci devrait être un "Trigger Base de données" pour être vraiment robuste.
    await _supabase.from('conversations').update({'updated_at': now.toIso8601String()}).eq('id', conversationId);

    return ChatMessage.fromJson(response);
  }

  Future<void> markAsRead(String conversationId) async {
    final uid = currentUserId;
    if (uid.isEmpty) return;

    // Mise à jour de masse plus performante (on vérifie l'existence avant d'envoyer la requête)
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

  Future<ChatMessage?> getMessageById(String messageId) async {
    try {
      final response = await _supabase
          .from('messages')
          .select('*, profiles!sender_id(display_name, full_name, avatar_url)')
          .eq('id', messageId)
          .maybeSingle();
      if (response == null) return null;
      final profile = response['profiles'] as Map<String, dynamic>?;
      response['sender_name'] = _resolveDisplayName(profile);
      response['sender_avatar'] = profile?['avatar_url'];
      return ChatMessage.fromJson(response);
    } catch (e) {
      debugPrint('❌ getMessageById: $e');
      return null;
    }
  }

  // ============================================================
  // REALTIME / STREAMS (CORRECTION MAJEURE ICI 🚨)
  // ============================================================

  Stream<List<ChatMessage>> subscribeToMessages(String conversationId) {
    final controller = StreamController<List<ChatMessage>>();
    final channel = _supabase.channel('messages:$conversationId');

    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'messages',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq, 
        column: 'conversation_id',
        value: conversationId,
      ),
      callback: (payload) async {
        // 🔥 CORRECTION : On ne refetch JAMAIS toute la liste des messages.
        // On traite uniquement le delta (le message qui a changé/qui a été ajouté).
        
        if (payload.eventType == PostgresChangeEvent.insert || payload.eventType == PostgresChangeEvent.update) {
          // On fetch juste le message concerné pour récupérer sa jointure (nom/avatar)
          final msgId = payload.newRecord['id'] as String?;
          if (msgId != null) {
            final singleMessage = await getMessageById(msgId);
            if (singleMessage != null) {
              controller.add([singleMessage]); // Renvoie une liste d'1 élément (qui sera traitée par l'UI via upsertRealtime)
            }
          }
        } else if (payload.eventType == PostgresChangeEvent.delete) {
          // Si c'est une suppression définitive
          final oldId = payload.oldRecord['id'] as String?;
          if (oldId != null) {
             final deletedMsg = ChatMessage.fromJson({...payload.oldRecord, 'is_deleted': true});
             controller.add([deletedMsg]);
          }
        }
      },
    ).subscribe();

    controller.onCancel = () {
      _supabase.removeChannel(channel);
      controller.close();
    };

    return controller.stream;
  }
}
