import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/auth/token_service.dart';
import 'chat_models.dart';
import 'chat_constants.dart';
import 'chat_utils.dart';
import '../archive/search_filters.dart';

class ChatRepository {
  // ✅ Utiliser le client Supabase global (initialisé avec la bonne URL)
  final SupabaseClient _supabase = Supabase.instance.client;

  // ==================== CONVERSATIONS ====================
  Future<List<Conversation>> fetchConversations(String userId) async {
    final response = await _supabase
        .from('thix_chat_chats')
        .select('''
          *,
          participants:user_id(*),
          last_message:last_message_id(*)
        ''')
        .contains('participant_ids', [userId])
        .order('updated_at', ascending: false);

    return response.map((json) => Conversation.fromJson(json)).toList();
  }

  // ==================== MESSAGES ====================
  Future<List<Message>> fetchMessages(String conversationId, {int limit = 50}) async {
    final response = await _supabase
        .from('thix_chat_messages')
        .select('*')
        .eq('chat_id', conversationId)
        .order('created_at', ascending: false)
        .limit(limit);

    return response.map((json) => Message.fromJson(json)).toList();
  }

  Future<Message> sendMessage(Message message) async {
    final response = await _supabase
        .from('thix_chat_messages')
        .insert({
          'chat_id': message.conversationId,
          'sender_id': message.senderId,
          'content': message.content,
          'created_at': message.sentAt.toIso8601String(),
        })
        .select()
        .single();

    return Message.fromJson(response);
  }

  // ==================== CONFIDENTIEL ====================
  Future<bool> verifyConfidentialCode(String messageId, String enteredCode) async {
    final response = await _supabase
        .from('thix_chat_messages')
        .select('confidential_code')
        .eq('id', messageId)
        .single();

    final storedCode = response['confidential_code'] as String?;
    return storedCode == enteredCode;
  }

  // ==================== ACCUSÉS DE LECTURE ====================
  Future<void> markAsRead(String messageId, String userId) async {
    await _supabase
        .from('thix_chat_reads')
        .upsert({
          'message_id': messageId,
          'user_id': userId,
          'read_at': DateTime.now().toIso8601String(),
        });
  }

  // ==================== RÉACTIONS ====================
  Future<void> addReaction(String messageId, String reaction, String userId) async {
    await _supabase
        .from('thix_chat_reactions')
        .upsert({
          'message_id': messageId,
          'user_id': userId,
          'reaction': reaction,
        });
  }

  // ==================== SUPPRESSION ====================
  Future<void> deleteMessage(String messageId, String userId, {bool forEveryone = false}) async {
    if (forEveryone) {
      await _supabase.from('thix_chat_messages').delete().eq('id', messageId);
    } else {
      await _supabase
          .from('thix_chat_deletions')
          .upsert({'message_id': messageId, 'user_id': userId});
    }
  }

  // ==================== ÉPINGLAGE ====================
  Future<void> pinMessage(String messageId, bool pinned) async {
    await _supabase
        .from('thix_chat_messages')
        .update({'pinned': pinned})
        .eq('id', messageId);
  }

  // ==================== PRÉSENCE ====================
  Future<void> updatePresence(String userId, String status) async {
    await _supabase
        .from('thix_presence')
        .upsert({
          'user_id': userId,
          'status': status,
          'updated_at': DateTime.now().toIso8601String(),
        });
  }

  // ==================== STORIES ====================
  Future<List<Story>> fetchStories(String userId) async {
    final response = await _supabase
        .from('thix_stories')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return response.map((json) => Story.fromJson(json)).toList();
  }

  // ==================== STATS CHAT ====================
  Future<ChatStats> fetchChatStats(String userId) async {
    // ✅ Utiliser CountOption.exact ou CountOption.estimated
    // On utilise exact pour une précision parfaite (lent sur des grandes tables)
    // Pour de meilleures performances, on peut utiliser CountOption.estimated
    final onlineCountResponse = await _supabase
        .from('thix_presence')
        .select('user_id', count: CountOption.exact)  // ✅ au lieu de CountEstimate
        .eq('status', 'online');

    final newMessagesResponse = await _supabase
        .from('thix_chat_messages')
        .select('id', count: CountOption.exact)      // ✅ au lieu de CountEstimate
        .gt('created_at', DateTime.now().subtract(const Duration(hours: 24)));

    // ✅ Accéder au compteur via .count
    final onlineCount = onlineCountResponse.count ?? 0;
    final newMessagesCount = newMessagesResponse.count ?? 0;

    return ChatStats(
      onlineCount: onlineCount,
      newMessagesCount: newMessagesCount,
      activeMeetingsCount: 0, // à adapter si vous avez une table de réunions
      securityAlertsCount: 0,
    );
  }

  // ==================== TYPING (signal) ====================
  Future<void> sendTyping(String conversationId, String userId) async {
    try {
      await _supabase
          .from('thix_typing')
          .upsert({
            'conversation_id': conversationId,
            'user_id': userId,
            'updated_at': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      // Ignorer
    }
  }

  // ==================== ARCHIVES ====================
  Future<void> archiveConversation(String conversationId, String userId) async {
    await _supabase
        .from('thix_chat_participants')
        .update({'archived_at': DateTime.now().toIso8601String()})
        .eq('chat_id', conversationId)
        .eq('user_id', userId);
  }

  Future<void> deleteConversation(String conversationId, String userId) async {
    await _supabase
        .from('thix_chat_participants')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('chat_id', conversationId)
        .eq('user_id', userId);
  }

  Future<List<Conversation>> fetchArchivedConversations(String userId) async {
    final response = await _supabase
        .from('thix_chat_chats')
        .select('*, participants:user_id(*)')
        .eq('participants.user_id', userId)
        .not('archived_at', 'is', null);

    return response.map((json) => Conversation.fromJson(json)).toList();
  }

  Future<void> unarchiveConversation(String conversationId, String userId) async {
    await _supabase
        .from('thix_chat_participants')
        .update({'archived_at': null})
        .eq('chat_id', conversationId)
        .eq('user_id', userId);
  }

  // ==================== REALTIME ====================
  Stream<Message> listenForNewMessages(String conversationId) {
    return _supabase
        .from('thix_chat_messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', conversationId)
        .order('created_at', ascending: false)
        .limit(1)
        .map((event) => Message.fromJson(event.first));
  }
}
