import 'dart:async';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../models/chat/chat_message.dart';
import '../../models/chat/chat_conversation.dart';
import '../../models/chat/chat_participant.dart';
import '../../models/chat/user_status.dart';

class ChatService {
  final SupabaseClient _supabase;

  ChatService(this._supabase);

  String get currentUserId => _supabase.auth.currentUser?.id ?? '';

  // ============================================================
  // CONVERSATIONS
  // ============================================================

  /// Récupère toutes les conversations de l'utilisateur connecté
  Future<List<ChatConversation>> getConversations() async {
    try {
      final uid = currentUserId;
      if (uid.isEmpty) return [];

      // 1. Récupérer les IDs des conversations du participant
      final participantResponse = await _supabase
          .from('conversation_participants')
          .select('conversation_id')
          .eq('user_id', uid);

      if (participantResponse.isEmpty) return [];

      final conversationIds = (participantResponse as List)
          .map((e) => e['conversation_id'] as String)
          .toList();

      // 2. Récupérer les conversations avec les participants
      final response = await _supabase
          .from('conversations')
          .select('''
              *,
              conversation_participants!inner (
                  user_id,
                  profiles!user_id (
                      username,
                      full_name,
                      avatar_url
                  )
              )
          ''')
          .inFilter('id', conversationIds)
          .order('updated_at', ascending: false);

      final conversations = <ChatConversation>[];

      for (var conv in response as List) {
        final participants = conv['conversation_participants'] as List;
        final participantIds = participants
            .map((p) => p['user_id'] as String)
            .toList();

        // Trouver l'autre participant (pour les conversations individuelles)
        String? otherParticipantName;
        String? otherParticipantAvatar;

        if (!(conv['is_group'] ?? false) && participants.length == 2) {
          final other = participants.firstWhere(
            (p) => p['user_id'] != uid,
            orElse: () => null,
          );
          if (other != null) {
            final profile = other['profiles'] as Map<String, dynamic>?;
            otherParticipantName = profile?['full_name'] ??
                profile?['username'] ??
                'Utilisateur inconnu';
            otherParticipantAvatar = profile?['avatar_url'];
          }
        }

        // 3. Récupérer le dernier message
        final lastMsg = await _supabase
            .from('messages')
            .select('''
                *,
                profiles!sender_id (
                    username,
                    full_name,
                    avatar_url
                )
            ''')
            .eq('conversation_id', conv['id'])
            .eq('is_deleted', false)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

        ChatMessage? lastMessage;
        if (lastMsg != null) {
          lastMessage = ChatMessage.fromJson(lastMsg);
        }

        // 4. Compter les messages non lus
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
          otherParticipantName: otherParticipantName,
          otherParticipantAvatar: otherParticipantAvatar,
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

  /// Crée une nouvelle conversation
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

      final convIds = (existing as List)
          .map((e) => e['conversation_id'] as String)
          .toList();
          
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

          final otherProfile = await _supabase
              .from('profiles')
              .select('username, full_name, avatar_url')
              .eq('id', otherId)
              .single();

          return ChatConversation.fromJson({
            ...convData,
            'other_participant_name': otherProfile['full_name'] ??
                otherProfile['username'] ??
                'Utilisateur inconnu',
            'other_participant_avatar': otherProfile['avatar_url'],
          });
        }
      }
    }

    // Générer l'ID de la conversation
    final String conversationId = const Uuid().v4();

    // Insérer la conversation
    await _supabase.from('conversations').insert({
      'id': conversationId,
      'is_group': isGroup,
      'group_name': groupName,
      'group_avatar': groupAvatar,
      'updated_at': DateTime.now().toIso8601String(),
      'is_pinned': false,
    });

    // Insérer les participants
    for (var pid in participantIds) {
      await _supabase.from('conversation_participants').insert({
        'conversation_id': conversationId,
        'user_id': pid,
        'role': pid == uid ? 'admin' : 'member',
        'last_read_at': DateTime.now().toIso8601String(),
      });
    }

    // Récupérer les infos de l'autre participant (pour une conversation individuelle)
    String? otherName;
    String? otherAvatar;
    if (!isGroup && participantIds.length == 2) {
      final otherId = participantIds.firstWhere((id) => id != uid);
      final otherProfile = await _supabase
          .from('profiles')
          .select('username, full_name, avatar_url')
          .eq('id', otherId)
          .single();
      otherName = otherProfile['full_name'] ??
          otherProfile['username'] ??
          'Utilisateur inconnu';
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

  /// Ajoute un participant à une conversation de groupe
  Future<void> addParticipant(String conversationId, String userId) async {
    await _supabase.from('conversation_participants').insert({
      'conversation_id': conversationId,
      'user_id': userId,
      'role': 'member',
      'last_read_at': DateTime.now().toIso8601String(),
    });
  }

  /// Retire un participant d'une conversation de groupe
  Future<void> removeParticipant(String conversationId, String userId) async {
    await _supabase
        .from('conversation_participants')
        .delete()
        .eq('conversation_id', conversationId)
        .eq('user_id', userId);
  }

  /// Épingle ou désépingle une conversation
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

  /// Récupère une conversation par son ID
  Future<ChatConversation?> getConversation(String conversationId) async {
    try {
      final uid = currentUserId;
      if (uid.isEmpty) return null;

      final response = await _supabase
          .from('conversations')
          .select('''
              *,
              conversation_participants!inner (
                  user_id,
                  profiles!user_id (
                      username,
                      full_name,
                      avatar_url
                  )
              )
          ''')
          .eq('id', conversationId)
          .maybeSingle();

      if (response == null) return null;

      final participants = response['conversation_participants'] as List;
      final participantIds = participants
          .map((p) => p['user_id'] as String)
          .toList();

      String? otherParticipantName;
      String? otherParticipantAvatar;

      if (!(response['is_group'] ?? false) && participants.length == 2) {
        final other = participants.firstWhere(
          (p) => p['user_id'] != uid,
          orElse: () => null,
        );
        if (other != null) {
          final profile = other['profiles'] as Map<String, dynamic>?;
          otherParticipantName = profile?['full_name'] ??
              profile?['username'] ??
              'Utilisateur inconnu';
          otherParticipantAvatar = profile?['avatar_url'];
        }
      }

      return ChatConversation.fromJson({
        ...response,
        'participant_ids': participantIds,
        'other_participant_name': otherParticipantName,
        'other_participant_avatar': otherParticipantAvatar,
      });
    } catch (e) {
      debugPrint('❌ getConversation: $e');
      return null;
    }
  }

  // ============================================================
  // MESSAGES
  // ============================================================

  /// Récupère les messages d'une conversation avec les profils
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
          .select('''
              *,
              profiles!sender_id (
                  username,
                  full_name,
                  avatar_url
              )
          ''')
          .eq('conversation_id', conversationId)
          .eq('is_deleted', false)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      // Reversed pour avoir l'ordre chronologique
      return (response as List)
          .map((e) => ChatMessage.fromJson(e))
          .toList()
          .reversed
          .toList();
    } catch (e) {
      debugPrint('❌ getMessages: $e');
      return [];
    }
  }

  /// Envoie un message dans une conversation
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

    // Insérer le message
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
    }).select('''
        *,
        profiles!sender_id (
            username,
            full_name,
            avatar_url
        )
    ''').single();

    // Mettre à jour le timestamp de la conversation
    await _supabase
        .from('conversations')
        .update({'updated_at': now.toIso8601String()})
        .eq('id', conversationId);

    return ChatMessage.fromJson(response);
  }

  /// Marque tous les messages d'une conversation comme lus
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

  /// Supprime un message (soft delete)
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

  /// Ajoute ou retire une réaction à un message
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
      // Retirer la réaction
      await _supabase
          .from('message_reactions')
          .delete()
          .eq('message_id', messageId)
          .eq('user_id', uid);
    } else {
      // Ajouter la réaction
      await _supabase.from('message_reactions').insert({
        'message_id': messageId,
        'user_id': uid,
        'reaction': reaction,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  /// Récupère un message par son ID
  Future<ChatMessage?> getMessageById(String messageId) async {
    try {
      final response = await _supabase
          .from('messages')
          .select('''
              *,
              profiles!sender_id (
                  username,
                  full_name,
                  avatar_url
              )
          ''')
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

  // ============================================================
  // MESSAGES ÉPHÉMÈRES
  // ============================================================

  /// Nettoie les messages éphémères expirés
  Future<void> cleanupEphemeralMessages() async {
    try {
      await _supabase
          .from('messages')
          .delete()
          .eq('is_ephemeral', true)
          .lt('delete_at', DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('❌ cleanupEphemeralMessages: $e');
    }
  }

  // ============================================================
  // PRÉSENCE / STATUT
  // ============================================================

  /// Met à jour le statut de présence de l'utilisateur
  Future<void> updatePresence(String status, {String? customStatus}) async {
    final uid = currentUserId;
    if (uid.isEmpty) return;

    await _supabase.from('user_presence').upsert({
      'user_id': uid,
      'status': status,
      'custom_status': customStatus,
      'last_seen_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Récupère le statut de présence d'un utilisateur
  Future<UserStatus?> getUserPresence(String userId) async {
    try {
      final response = await _supabase
          .from('user_presence')
          .select('''
              *,
              profiles!user_id (
                  username,
                  full_name,
                  avatar_url
              )
          ''')
          .eq('user_id', userId)
          .maybeSingle();
      if (response == null) return null;
      return UserStatus.fromJson(response);
    } catch (e) {
      debugPrint('❌ getUserPresence: $e');
      return null;
    }
  }

  /// Récupère les statuts de présence de plusieurs utilisateurs
  Future<List<UserStatus>> getUsersPresence(List<String> userIds) async {
    try {
      if (userIds.isEmpty) return [];
      final response = await _supabase
          .from('user_presence')
          .select('''
              *,
              profiles!user_id (
                  username,
                  full_name,
                  avatar_url
              )
          ''')
          .inFilter('user_id', userIds);

      return (response as List)
          .map((e) => UserStatus.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('❌ getUsersPresence: $e');
      return [];
    }
  }

  // ============================================================
  // REALTIME / STREAMS
  // ============================================================

  /// Stream des nouveaux messages (utiliser avec listen)
  Stream<List<ChatMessage>> subscribeToMessages(String conversationId) {
    return _supabase
        .channel('messages:$conversationId')
        .on(
          RealtimeListenTypes.postgresChanges,
          ChannelFilter(
            event: '*',
            schema: 'public',
            table: 'messages',
            filter: 'conversation_id=eq.$conversationId',
          ),
          (payload) {},
        )
        .subscribe()
        .asStream()
        .map((_) => []);
  }

  /// Stream des changements de statut de présence
  Stream<List<UserStatus>> subscribeToPresence(List<String> userIds) {
    return _supabase
        .channel('presence:all')
        .on(
          RealtimeListenTypes.postgresChanges,
          ChannelFilter(
            event: '*',
            schema: 'public',
            table: 'user_presence',
          ),
          (payload) {},
        )
        .subscribe()
        .asStream()
        .map((_) async {
          return await getUsersPresence(userIds);
        })
        .asyncMap((future) => future);
  }

  // ============================================================
  // UPLOAD DE FICHIERS
  // ============================================================

  /// Upload un fichier vers Supabase Storage
  Future<String?> uploadFile(String bucket, String path, Uint8List fileData) async {
    try {
      await _supabase.storage.from(bucket).uploadBinary(path, fileData);
      final url = _supabase.storage.from(bucket).getPublicUrl(path);
      return url;
    } catch (e) {
      debugPrint('❌ uploadFile: $e');
      return null;
    }
  }

  /// Supprime un fichier de Supabase Storage
  Future<void> deleteFile(String bucket, String path) async {
    try {
      await _supabase.storage.from(bucket).remove([path]);
    } catch (e) {
      debugPrint('❌ deleteFile: $e');
    }
  }

  /// Upload un fichier avec un nom unique généré automatiquement
  Future<String?> uploadFileWithUniqueName(
    String bucket,
    String folder,
    Uint8List fileData,
    String extension,
  ) async {
    try {
      final fileName = '${const Uuid().v4()}.$extension';
      final path = '$folder/$fileName';
      final url = await uploadFile(bucket, path, fileData);
      return url;
    } catch (e) {
      debugPrint('❌ uploadFileWithUniqueName: $e');
      return null;
    }
  }

  // ============================================================
  // UTILITAIRES
  // ============================================================

  /// Vérifie si l'utilisateur est connecté
  bool get isAuthenticated => currentUserId.isNotEmpty;

  /// Se déconnecter
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Récupère l'utilisateur actuel
  User? get currentUser => _supabase.auth.currentUser;

  /// Récupère le profil de l'utilisateur actuel
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    try {
      final uid = currentUserId;
      if (uid.isEmpty) return null;
      final response = await _supabase
          .from('profiles')
          .select('*')
          .eq('id', uid)
          .maybeSingle();
      return response as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('❌ getCurrentUserProfile: $e');
      return null;
    }
  }
}
