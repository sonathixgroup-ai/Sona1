// lib/presentation/chat/core/chat_repository.dart
// [PARTIE] Repository : communication via Edge Functions Supabase avec token

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/auth/token_service.dart';
import 'chat_models.dart';
import 'chat_constants.dart';
import 'chat_utils.dart';

class ChatRepository {
  // ✅ URL réelle du projet Supabase (d'après tes captures)
  final String _baseUrl = 'https://kfzkxaatdbapqwxcely.supabase.co/functions/v1';
  
  // Pour les appels Realtime (non modifiés car natifs à Supabase)
  final SupabaseClient _supabase = Supabase.instance.client;

  // Helper pour les requêtes HTTP authentifiées avec le token
  Future<http.Response> _authenticatedRequest(
    String endpoint, {
    String method = 'GET',
    Map<String, dynamic>? body,
  }) async {
    final token = await TokenService.getToken();
    final uri = Uri.parse('$_baseUrl/$endpoint');
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    
    switch (method) {
      case 'GET':
        return await http.get(uri, headers: headers);
      case 'POST':
        return await http.post(uri, headers: headers, body: jsonEncode(body));
      case 'PUT':
        return await http.put(uri, headers: headers, body: jsonEncode(body));
      case 'DELETE':
        return await http.delete(uri, headers: headers);
      default:
        throw Exception('Méthode non supportée');
    }
  }

  // ==================== CONVERSATIONS ====================
  Future<List<Conversation>> fetchConversations(String userId) async {
    final response = await _authenticatedRequest('conversations?user_id=$userId');
    if (response.statusCode != 200) {
      throw Exception('Erreur fetchConversations: ${response.body}');
    }
    final List<dynamic> jsonList = jsonDecode(response.body);
    return jsonList.map((json) => Conversation.fromJson(json)).toList();
  }

  // ==================== MESSAGES ====================
  Future<List<Message>> fetchMessages(String conversationId, {int limit = 50}) async {
    final response = await _authenticatedRequest(
      'messages?conversation_id=$conversationId&limit=$limit'
    );
    if (response.statusCode != 200) {
      throw Exception('Erreur fetchMessages: ${response.body}');
    }
    final List<dynamic> jsonList = jsonDecode(response.body);
    return jsonList.map((json) => Message.fromJson(json)).toList();
  }

  Future<Message> sendMessage(Message message) async {
    final response = await _authenticatedRequest(
      'send_message',
      method: 'POST',
      body: message.toJson(),
    );
    if (response.statusCode != 200) {
      throw Exception('Erreur sendMessage: ${response.body}');
    }
    final Map<String, dynamic> json = jsonDecode(response.body);
    return Message.fromJson(json);
  }

  // ==================== CONFIDENTIEL ====================
  Future<bool> verifyConfidentialCode(String messageId, String enteredCode) async {
    final response = await _authenticatedRequest(
      'verify_confidential',
      method: 'POST',
      body: {'message_id': messageId, 'code': enteredCode},
    );
    if (response.statusCode != 200) {
      throw Exception('Erreur verifyConfidentialCode: ${response.body}');
    }
    final Map<String, dynamic> json = jsonDecode(response.body);
    return json['valid'] as bool;
  }

  // ==================== ACCUSÉS DE LECTURE ====================
  Future<void> markAsRead(String messageId, String userId) async {
    final response = await _authenticatedRequest(
      'mark_read',
      method: 'POST',
      body: {'message_id': messageId, 'user_id': userId},
    );
    if (response.statusCode != 200) {
      throw Exception('Erreur markAsRead: ${response.body}');
    }
  }

  // ==================== RÉACTIONS ====================
  Future<void> addReaction(String messageId, String reaction, String userId) async {
    final response = await _authenticatedRequest(
      'add_reaction',
      method: 'POST',
      body: {'message_id': messageId, 'reaction': reaction, 'user_id': userId},
    );
    if (response.statusCode != 200) {
      throw Exception('Erreur addReaction: ${response.body}');
    }
  }

  // ==================== SUPPRESSION ====================
  Future<void> deleteMessage(String messageId, String userId, {bool forEveryone = false}) async {
    final response = await _authenticatedRequest(
      'delete_message',
      method: 'POST',
      body: {'message_id': messageId, 'user_id': userId, 'for_everyone': forEveryone},
    );
    if (response.statusCode != 200) {
      throw Exception('Erreur deleteMessage: ${response.body}');
    }
  }

  // ==================== PRÉSENCE ====================
  Future<void> updatePresence(String userId, String status) async {
    final response = await _authenticatedRequest(
      'update_presence',
      method: 'POST',
      body: {'user_id': userId, 'status': status},
    );
    if (response.statusCode != 200) {
      throw Exception('Erreur updatePresence: ${response.body}');
    }
  }

  // ==================== STORIES ====================
  Future<List<Story>> fetchStories(String userId) async {
    final response = await _authenticatedRequest('stories?user_id=$userId');
    if (response.statusCode != 200) {
      throw Exception('Erreur fetchStories: ${response.body}');
    }
    final List<dynamic> jsonList = jsonDecode(response.body);
    return jsonList.map((json) => Story.fromJson(json)).toList();
  }

  // ==================== STATS CHAT ====================
  Future<ChatStats> fetchChatStats(String userId) async {
    final response = await _authenticatedRequest('chat_stats?user_id=$userId');
    if (response.statusCode != 200) {
      throw Exception('Erreur fetchChatStats: ${response.body}');
    }
    final Map<String, dynamic> json = jsonDecode(response.body);
    return ChatStats(
      onlineCount: json['online_count'] ?? 0,
      newMessagesCount: json['new_messages_count'] ?? 0,
      activeMeetingsCount: json['active_meetings_count'] ?? 0,
      securityAlertsCount: json['security_alerts_count'] ?? 0,
    );
  }

  // ==================== TYPING (signal) ====================
  Future<void> sendTyping(String conversationId, String userId) async {
    try {
      await _authenticatedRequest('typing', method: 'POST', body: {
        'conversation_id': conversationId,
        'user_id': userId,
      });
    } catch (e) {
      // Ignorer les erreurs de typing (non critique)
    }
  }

  // ==================== ARCHIVES ====================
  Future<void> archiveConversation(String conversationId, String userId) async {
    final response = await _authenticatedRequest(
      'archive_conversation',
      method: 'POST',
      body: {'conversation_id': conversationId, 'user_id': userId},
    );
    if (response.statusCode != 200) throw Exception('Erreur archiveConversation');
  }

  Future<void> deleteConversation(String conversationId, String userId) async {
    final response = await _authenticatedRequest(
      'delete_conversation',
      method: 'POST',
      body: {'conversation_id': conversationId, 'user_id': userId},
    );
    if (response.statusCode != 200) throw Exception('Erreur deleteConversation');
  }

  // ==================== EXPORT ====================
  Future<String> exportChat(String conversationId, String userId) async {
    final response = await _authenticatedRequest('export_chat?conversation_id=$conversationId');
    if (response.statusCode != 200) throw Exception('Erreur exportChat');
    return response.body; // JSON brut
  }

  // ==================== RECHERCHE ====================
  Future<List<Message>> searchMessages(String userId, String query, {String? conversationId}) async {
    final response = await _authenticatedRequest(
      'search_messages',
      method: 'POST',
      body: {'user_id': userId, 'query': query, 'conversation_id': conversationId},
    );
    if (response.statusCode != 200) throw Exception('Erreur searchMessages');
    final List<dynamic> jsonList = jsonDecode(response.body);
    return jsonList.map((json) => Message.fromJson(json)).toList();
  }

  // ==================== MESSAGES PROGRAMMÉS ====================
  Future<Map<String, dynamic>> scheduleMessage({
    required String conversationId,
    required String userId,
    required String content,
    required DateTime scheduledAt,
    bool isRecurring = false,
  }) async {
    final response = await _authenticatedRequest(
      'schedule_message',
      method: 'POST',
      body: {
        'conversation_id': conversationId,
        'user_id': userId,
        'content': content,
        'scheduled_at': scheduledAt.toIso8601String(),
        'is_recurring': isRecurring,
      },
    );
    if (response.statusCode != 200) throw Exception('Erreur scheduleMessage');
    return jsonDecode(response.body);
  }

  Future<List<Map<String, dynamic>>> getScheduledMessages(String userId, {String? conversationId}) async {
    final endpoint = conversationId != null
        ? 'get_scheduled_messages?conversation_id=$conversationId'
        : 'get_scheduled_messages';
    final response = await _authenticatedRequest(endpoint);
    if (response.statusCode != 200) throw Exception('Erreur getScheduledMessages');
    final List<dynamic> jsonList = jsonDecode(response.body);
    return jsonList.cast<Map<String, dynamic>>();
  }

  Future<void> cancelScheduledMessage(String messageId, String userId) async {
    final response = await _authenticatedRequest(
      'cancel_scheduled_message',
      method: 'POST',
      body: {'message_id': messageId, 'user_id': userId},
    );
    if (response.statusCode != 200) throw Exception('Erreur cancelScheduledMessage');
  }

  // ==================== SONDAGES ====================
  Future<void> votePoll(String pollId, String userId, int optionIndex) async {
    final response = await _authenticatedRequest(
      'poll_vote',
      method: 'POST',
      body: {'poll_id': pollId, 'user_id': userId, 'option_index': optionIndex},
    );
    if (response.statusCode != 200) throw Exception('Erreur votePoll');
  }

  Future<Map<String, dynamic>> getPollResults(String pollId) async {
    final response = await _authenticatedRequest('poll_results?poll_id=$pollId');
    if (response.statusCode != 200) throw Exception('Erreur getPollResults');
    return jsonDecode(response.body);
  }

  // ==================== TÂCHES ====================
  Future<Map<String, dynamic>> createTask({
    required String conversationId,
    required String userId,
    required String title,
    String? description,
    String? assignedTo,
    DateTime? dueDate,
    int priority = 1,
  }) async {
    final response = await _authenticatedRequest(
      'task_create',
      method: 'POST',
      body: {
        'conversation_id': conversationId,
        'user_id': userId,
        'title': title,
        'description': description,
        'assigned_to': assignedTo,
        'due_date': dueDate?.toIso8601String(),
        'priority': priority,
      },
    );
    if (response.statusCode != 200) throw Exception('Erreur createTask');
    return jsonDecode(response.body);
  }

  Future<void> updateTask(String taskId, String userId, {bool? completed, String? assignedTo, String? title, String? description, DateTime? dueDate, int? priority}) async {
    final body = {'task_id': taskId, 'user_id': userId}..addAll({
      if (completed != null) 'completed': completed,
      if (assignedTo != null) 'assigned_to': assignedTo,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (dueDate != null) 'due_date': dueDate.toIso8601String(),
      if (priority != null) 'priority': priority,
    });
    final response = await _authenticatedRequest('task_update', method: 'POST', body: body);
    if (response.statusCode != 200) throw Exception('Erreur updateTask');
  }

  Future<List<Map<String, dynamic>>> getTasks(String userId, {String? conversationId}) async {
    final endpoint = conversationId != null ? 'task_list?conversation_id=$conversationId' : 'task_list';
    final response = await _authenticatedRequest(endpoint);
    if (response.statusCode != 200) throw Exception('Erreur getTasks');
    final List<dynamic> jsonList = jsonDecode(response.body);
    return jsonList.cast<Map<String, dynamic>>();
  }

  // ==================== BROUILLONS ====================
  Future<void> saveDraft(String conversationId, String userId, String text, {Map<String, dynamic>? metadata}) async {
    final response = await _authenticatedRequest(
      'draft_save',
      method: 'POST',
      body: {
        'conversation_id': conversationId,
        'user_id': userId,
        'text': text,
        'metadata': metadata,
      },
    );
    if (response.statusCode != 200) throw Exception('Erreur saveDraft');
  }

  Future<List<Map<String, dynamic>>> getDrafts(String userId) async {
    final response = await _authenticatedRequest('draft_list');
    if (response.statusCode != 200) throw Exception('Erreur getDrafts');
    final List<dynamic> jsonList = jsonDecode(response.body);
    return jsonList.cast<Map<String, dynamic>>();
  }

  Future<void> deleteDraft(String conversationId, String userId) async {
    final response = await _authenticatedRequest(
      'draft_delete',
      method: 'POST',
      body: {'conversation_id': conversationId, 'user_id': userId},
    );
    if (response.statusCode != 200) throw Exception('Erreur deleteDraft');
  }

  // ==================== TRADUCTION ====================
  Future<String> translateText(String text, String targetLanguage) async {
    final response = await _authenticatedRequest(
      'translate_message',
      method: 'POST',
      body: {'text': text, 'target_language': targetLanguage},
    );
    if (response.statusCode != 200) throw Exception('Erreur translateText');
    final Map<String, dynamic> json = jsonDecode(response.body);
    return json['translated'] ?? text;
  }

  // ==================== TRANSCRIPTION VOCALE ====================
  Future<String> transcribeAudio(http.MultipartFile audioFile) async {
    final token = await TokenService.getToken();
    final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/voice_to_text'));
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(audioFile);
    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    if (response.statusCode != 200) {
      throw Exception('Erreur voice_to_text: $responseBody');
    }
    final Map<String, dynamic> json = jsonDecode(responseBody);
    return json['text'] ?? '';
  }

  // ==================== SIGNALEMENT & BLOCAGE ====================
  Future<void> reportMessage(String messageId, String userId, String reason) async {
    final response = await _authenticatedRequest(
      'report_message',
      method: 'POST',
      body: {'message_id': messageId, 'user_id': userId, 'reason': reason},
    );
    if (response.statusCode != 200) throw Exception('Erreur reportMessage');
  }

  Future<void> reportUser(String reportedUserId, String userId, String reason) async {
    final response = await _authenticatedRequest(
      'report_user',
      method: 'POST',
      body: {'reported_user_id': reportedUserId, 'user_id': userId, 'reason': reason},
    );
    if (response.statusCode != 200) throw Exception('Erreur reportUser');
  }

  Future<void> blockUser(String blockedUserId, String userId) async {
    final response = await _authenticatedRequest(
      'block_user',
      method: 'POST',
      body: {'blocked_user_id': blockedUserId, 'user_id': userId},
    );
    if (response.statusCode != 200) throw Exception('Erreur blockUser');
  }

  Future<void> unblockUser(String blockedUserId, String userId) async {
    final response = await _authenticatedRequest(
      'unblock_user',
      method: 'POST',
      body: {'blocked_user_id': blockedUserId, 'user_id': userId},
    );
    if (response.statusCode != 200) throw Exception('Erreur unblockUser');
  }

  Future<List<Map<String, dynamic>>> getBlockedUsers(String userId) async {
    final response = await _authenticatedRequest('get_blocked_users');
    if (response.statusCode != 200) throw Exception('Erreur getBlockedUsers');
    final List<dynamic> jsonList = jsonDecode(response.body);
    return jsonList.cast<Map<String, dynamic>>();
  }

  // ==================== REALTIME ====================
  Stream<Message> listenForNewMessages(String conversationId) {
    return _supabase
        .from(ChatConstants.tableMessages)
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('sent_at', ascending: false)
        .limit(1)
        .map((event) => Message.fromJson(event.first));
  }

  // ==================== BIOMÉTRIE (placeholder) ====================
  Future<bool> _authenticateWithBiometrics() async {
    // À implémenter avec local_auth
    return true;
  }
}
