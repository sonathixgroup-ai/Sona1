// lib/services/chat_service.dart
import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/models/app_user.dart';
import 'package:thix_id/supabase/supabase_config.dart';
import 'package:thix_id/services/platform_file_from_path_stub.dart' if (dart.library.io) 'package:thix_id/services/platform_file_from_path_io.dart';

// ============================================================
// CLASSES DE DONNÉES
// ============================================================

class ChatSummary {
  final String id;
  final String type;
  final String? directKey;
  final List<String> participants;
  final Map<String, String> participantName;
  final Map<String, String> participantThix;
  final String lastMessage;
  final DateTime? lastMessageAt;

  const ChatSummary({
    required this.id,
    required this.type,
    required this.directKey,
    required this.participants,
    required this.participantName,
    required this.participantThix,
    required this.lastMessage,
    required this.lastMessageAt,
  });

  get unreadCount => null;

  static List<String> _parseParticipants(Object? raw) {
    if (raw == null) return const <String>[];
    if (raw is List) return raw.whereType<String>().toList(growable: false);
    if (raw is Map) {
      final v = raw['uids'] ?? raw['participants'] ?? raw['users'];
      if (v is List) return v.whereType<String>().toList(growable: false);
    }
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        return _parseParticipants(decoded);
      } catch (_) {
        return const <String>[];
      }
    }
    return const <String>[];
  }

  static ChatSummary fromRow(Map<String, dynamic> row) {
    final id = (row['id'] as String?) ?? '';
    final participants = _parseParticipants(row['participants']);
    final pn = (row['participant_name'] as Map?)?.cast<String, dynamic>() ?? const {};
    final pt = (row['participant_thix'] as Map?)?.cast<String, dynamic>() ?? const {};
    final dk = (row['direct_key'] as String?)?.trim();
    return ChatSummary(
      id: id,
      type: (row['type'] as String?) ?? 'direct',
      directKey: (dk == null || dk.isEmpty) ? null : dk,
      participants: participants,
      participantName: pn.map((k, v) => MapEntry(k, (v as String?) ?? 'Utilisateur')),
      participantThix: pt.map((k, v) => MapEntry(k, (v as String?) ?? '')),
      lastMessage: (row['last_message'] as String?) ?? '',
      lastMessageAt: _tryParseDate(row['last_message_at']),
    );
  }
}

class ChatMessage {
  final String id;
  final String chatId;
  final String type;
  final String senderId;
  final String senderName;
  final String senderThixId;
  final String? senderAvatarUrl;
  final bool senderCertified;
  final String text;
  final DateTime? createdAt;
  final Map<String, dynamic> extra;

  const ChatMessage({
    required this.id,
    required this.chatId,
    required this.type,
    required this.senderId,
    required this.senderName,
    required this.senderThixId,
    required this.senderAvatarUrl,
    required this.senderCertified,
    required this.text,
    required this.createdAt,
    required this.extra,
  });

  static ChatMessage fromRow(Map<String, dynamic> row) {
    final id = (row['id'] as String?) ?? '';
    final chatId = (row['chat_id'] as String?) ?? '';
    final type = (row['type'] as String?) ?? 'text';
    final senderId = (row['sender_id'] as String?) ?? '';
    final senderName = (row['sender_name'] as String?) ?? '';
    final senderThixId = (row['sender_thix_id'] as String?) ?? '';
    final senderAvatarUrl = (row['sender_profile_avatar_url'] as String?) ?? (row['avatar_url'] as String?);
    final profileName = (row['sender_profile_display_name'] as String?)?.trim();
    final effectiveName = profileName != null && profileName.isNotEmpty ? profileName : senderName;
    final nationalId = (row['sender_profile_national_id_number'] as String?) ?? (row['national_id_number'] as String?);
    final senderCertified = (nationalId ?? '').trim().isNotEmpty;
    final text = (row['text'] as String?) ?? '';
    final createdAt = _tryParseDate(row['created_at']);

    final extra = Map<String, dynamic>.from(row);
    extra.removeWhere((k, _) => const {
      'id',
      'chat_id',
      'type',
      'sender_id',
      'sender_name',
      'sender_thix_id',
      'sender_profile_display_name',
      'sender_profile_avatar_url',
      'sender_profile_national_id_number',
      'text',
      'created_at'
    }.contains(k));
    return ChatMessage(
      id: id,
      chatId: chatId,
      type: type,
      senderId: senderId,
      senderName: effectiveName,
      senderThixId: senderThixId,
      senderAvatarUrl: senderAvatarUrl,
      senderCertified: senderCertified,
      text: text,
      createdAt: createdAt,
      extra: extra,
    );
  }
}

class ChatProfileBasics {
  final String uid;
  final String displayName;
  final String? avatarUrl;
  final bool certified;

  const ChatProfileBasics({required this.uid, required this.displayName, required this.avatarUrl, required this.certified});
}

class ChatContact {
  final String uid;
  final String displayName;
  final String thixId;

  const ChatContact({required this.uid, required this.displayName, required this.thixId});
}

DateTime? _tryParseDate(Object? v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is String) return DateTime.tryParse(v);
  return null;
}

// ============================================================
// SERVICE PRINCIPAL
// ============================================================

class ChatService {
  static const String moneyTransferMarker = '[[THIX_MONEY_TRANSFER_V1]]';

  final SupabaseClient _client;
  ChatService({SupabaseClient? client}) : _client = client ?? SupabaseConfig.client;

  static const String chatsTable = 'thix_chat_chats';
  static const String messagesTable = 'thix_chat_messages';
  static const String readsTable = 'thix_chat_reads';
  static const String typingTable = 'thix_chat_typing';
  static const String attachmentsBucket = 'thix-chat';
  static const String profilesTable = 'profiles';

  final Map<String, ChatProfileBasics> _profileCache = <String, ChatProfileBasics>{};
  bool? _legacySchema;

  // ============================================================
  // GETTERS
  // ============================================================

  String get currentUserId => _client.auth.currentUser?.id ?? '';

  // ============================================================
  // SCHEMA DETECTION
  // ============================================================

  Future<bool> _isLegacySchema() async {
    final cached = _legacySchema;
    if (cached != null) return cached;
    try {
      await _client.from(messagesTable).select('id').limit(1);
      _legacySchema = false;
      return false;
    } catch (e) {
      debugPrint('ChatService: canonical messages table missing; using legacy chat schema. err=$e');
      _legacySchema = true;
      return true;
    }
  }

  // ============================================================
  // MÉTHODES D'ARCHIVE (NOUVEAU)
  // ============================================================

  Future<List<Conversation>> getArchivedConversations() async {
    try {
      final response = await _client
          .from(chatsTable)
          .select('*')
          .eq('is_archived', true)
          .contains('participants', [currentUserId])
          .order('updated_at', ascending: false);
      if (response is! List) return [];
      return response.map((e) => Conversation.fromJson(e)).toList();
    } catch (e) {
      debugPrint('ChatService: getArchivedConversations error: $e');
      return [];
    }
  }

  Future<void> unarchiveConversation(String conversationId) async {
    try {
      await _client
          .from(chatsTable)
          .update({'is_archived': false})
          .eq('id', conversationId);
    } catch (e) {
      debugPrint('ChatService: unarchiveConversation error: $e');
      rethrow;
    }
  }

  Future<void> deleteArchivedConversation(String conversationId) async {
    try {
      await _client
          .from(chatsTable)
          .delete()
          .eq('id', conversationId);
    } catch (e) {
      debugPrint('ChatService: deleteArchivedConversation error: $e');
      rethrow;
    }
  }

  Future<List<Conversation>> searchArchivedConversations(Map<String, dynamic> filters) async {
    try {
      var query = _client
          .from(chatsTable)
          .select('*')
          .eq('is_archived', true)
          .contains('participants', [currentUserId]);

      if (filters['name'] != null && filters['name'].toString().isNotEmpty) {
        query = query.ilike('name', '%${filters['name']}%');
      }
      if (filters['type'] != null && filters['type'] != 'all') {
        query = query.eq('type', filters['type']);
      }
      if (filters['startDate'] != null) {
        query = query.gte('updated_at', filters['startDate']);
      }
      if (filters['endDate'] != null) {
        query = query.lte('updated_at', filters['endDate']);
      }
      final response = await query.order('updated_at', ascending: false);
      if (response is! List) return [];
      return response.map((e) => Conversation.fromJson(e)).toList();
    } catch (e) {
      debugPrint('ChatService: searchArchivedConversations error: $e');
      return [];
    }
  }

  // ============================================================
  // MÉTHODES DE MESSAGERIE (ADAPTÉES POUR CHATPROVIDER)
  // ============================================================

  Future<List<ChatMessage>> fetchMessages(String conversationId) async {
    final uuid = await _resolveChatUuid(conversationId);
    final response = await _client
        .from(messagesTable)
        .select('*')
        .eq('chat_id', uuid)
        .order('created_at', ascending: false)
        .limit(200);
    if (response is! List) return [];
    final enriched = await _applyProfileEnrichmentForMessageRows(response.cast<Map<String, dynamic>>());
    return enriched.map((e) => ChatMessage.fromRow(e)).toList();
  }

  Future<ChatMessage> sendMessage(String conversationId, String content) async {
    return sendMessageWithType(conversationId, content, 'text');
  }

  Future<ChatMessage> sendMessageWithType(String conversationId, String content, String type) async {
    final authUid = _client.auth.currentUser?.id;
    if (authUid == null) throw Exception('User not logged in');
    final now = DateTime.now().toUtc().toIso8601String();

    final uuid = await _resolveChatUuid(conversationId);
    final inserted = await _client.from(messagesTable).insert({
      'chat_id': uuid,
      'type': type,
      'sender_id': authUid,
      'sender_name': '', // sera enrichi
      'sender_thix_id': '',
      'text': content,
      'created_at': now,
      'updated_at': now,
    }).select().single();

    // Mettre à jour le dernier message du chat
    try {
      await _client.from(chatsTable).update({
        'last_message': content,
        'last_message_at': now,
        'updated_at': now,
      }).eq('id', uuid);
    } catch (e) {
      debugPrint('ChatService: update chat preview failed (ignored) err=$e');
    }

    return ChatMessage.fromRow(inserted);
  }

  Future<ChatMessage> sendMedia(String conversationId, String filePath, String type) async {
    final authUid = _client.auth.currentUser?.id;
    if (authUid == null) throw Exception('User not logged in');
    final uuid = await _resolveChatUuid(conversationId);
    final ts = DateTime.now().millisecondsSinceEpoch;
    final fileName = filePath.split('/').last;
    final objectPath = 'chats/$uuid/${ts}_$fileName';
    final storage = _client.storage.from(attachmentsBucket);

    final file = fileFromPath(filePath);
    await storage.upload(objectPath, file as dynamic);
    final url = storage.getPublicUrl(objectPath);

    final now = DateTime.now().toUtc().toIso8601String();
    final inserted = await _client.from(messagesTable).insert({
      'chat_id': uuid,
      'type': type,
      'sender_id': authUid,
      'sender_name': '',
      'sender_thix_id': '',
      'text': '',
      'download_url': url,
      'file_name': fileName,
      'file_size': 0,
      'created_at': now,
      'updated_at': now,
    }).select().single();

    // Mettre à jour le dernier message
    await _client.from(chatsTable).update({
      'last_message': 'Média partagé',
      'last_message_at': now,
      'updated_at': now,
    }).eq('id', uuid);

    return ChatMessage.fromRow(inserted);
  }

  Future<void> toggleLike(String messageId) async {
    // TODO: implémenter si nécessaire
  }

  Future<void> addReaction(String messageId, String emoji) async {
    // Récupérer les réactions existantes
    final row = await _client
        .from(messagesTable)
        .select('reactions')
        .eq('id', messageId)
        .maybeSingle();
    Map<String, List<String>> reactions = {};
    if (row != null && row['reactions'] != null) {
      reactions = Map<String, List<String>>.from(row['reactions']);
    }
    final userId = currentUserId;
    if (!reactions.containsKey(emoji)) {
      reactions[emoji] = [];
    }
    if (!reactions[emoji]!.contains(userId)) {
      reactions[emoji]!.add(userId);
    }
    await _client
        .from(messagesTable)
        .update({'reactions': reactions})
        .eq('id', messageId);
  }

  Future<void> pinMessage(String messageId) async {
    await _client
        .from(messagesTable)
        .update({'is_pinned': true})
        .eq('id', messageId);
  }

  Future<void> deleteMessage(String messageId) async {
    await _client
        .from(messagesTable)
        .delete()
        .eq('id', messageId);
  }

  Future<void> markMessagesAsRead(String conversationId) async {
    final uid = currentUserId;
    if (uid.isEmpty) return;
    final uuid = await _resolveChatUuid(conversationId);
    await _client.from(readsTable).upsert({
      'chat_id': uuid,
      'user_id': uid,
      'read_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  // ============================================================
  // STATS, STORIES, SPACES (pour ChatProvider)
  // ============================================================

  Future<ChatStats> getStats() async {
    // Simulation de stats
    return ChatStats(
      onlineCount: 0,
      newMessagesCount: 0,
      activeCallsCount: 0,
      securityAlertsCount: 0,
    );
  }

  Future<List<Story>> getStories() async {
    // À implémenter selon votre modèle
    return [];
  }

  Future<List<Space>> getSpaces() async {
    // À implémenter
    return [];
  }

  Future<List<Story>> getMyStories() async {
    return [];
  }

  Future<void> createStory(File imageFile, String type) async {
    // À implémenter
  }

  Future<void> createStoryText(String text) async {
    // À implémenter
  }

  // ============================================================
  // CONVERSATIONS EXISTANTES
  // ============================================================

  Future<List<Conversation>> getConversations() async {
    final summaries = await _selectChatsForUser(currentUserId);
    return summaries.map((s) => Conversation(
      id: s['id'],
      type: s['type'] == 'group' ? ConversationType.group : ConversationType.private,
      name: s['title'],
      avatarURL: s['avatar_url'],
      createdBy: s['created_by'],
      participantIds: ChatSummary._parseParticipants(s['participants']),
      lastMessageId: null,
      lastMessageAt: _tryParseDate(s['last_message_at']),
      status: ConversationStatus.active,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    )).toList();
  }

  // ============================================================
  // MÉTHODES INTERNES
  // ============================================================

  Future<List<Map<String, dynamic>>> _selectChatsForUser(String uid) async {
    try {
      final rows = await _client
          .from(chatsTable)
          .select('id,type,direct_key,title,participants,participant_name,participant_thix,last_message,last_message_at,updated_at')
          .contains('participants', [uid])
          .order('last_message_at', ascending: false)
          .order('updated_at', ascending: false)
          .limit(100);
      if (rows is! List) return const <Map<String, dynamic>>[];
      return rows.map((r) => (r as Map).cast<String, dynamic>()).toList(growable: false);
    } catch (e) {
      debugPrint('ChatService: _selectChatsForUser canonical select failed uid=$uid err=$e');
      return [];
    }
  }

  Future<Map<String, ChatProfileBasics>> _fetchProfileBasics(List<String> uids) async {
    if (uids.isEmpty) return {};
    final missing = <String>{};
    for (final id in uids) {
      final v = id.trim();
      if (v.isEmpty) continue;
      if (!_profileCache.containsKey(v)) missing.add(v);
    }
    if (missing.isNotEmpty) {
      try {
        final fetched = await _client
            .from(profilesTable)
            .select('id, display_name, full_name, avatar_url, national_id_number')
            .inFilter('id', missing.toList(growable: false));
        if (fetched is List) {
          for (final raw in fetched) {
            final row = (raw as Map).cast<String, dynamic>();
            final id = (row['id'] as String?) ?? '';
            if (id.isEmpty) continue;
            final fullName = (row['full_name'] as String?)?.trim();
            final displayName = (fullName != null && fullName.isNotEmpty) ? fullName : ((row['display_name'] as String?)?.trim() ?? 'Utilisateur');
            final avatarUrl = (row['avatar_url'] as String?)?.trim();
            final certified = ((row['national_id_number'] as String?) ?? '').trim().isNotEmpty;
            _profileCache[id] = ChatProfileBasics(uid: id, displayName: displayName, avatarUrl: avatarUrl, certified: certified);
          }
        }
      } catch (e) {
        debugPrint('ChatService: profile basics fetch failed err=$e');
      }
    }
    final out = <String, ChatProfileBasics>{};
    for (final id in uids) {
      final p = _profileCache[id];
      if (p != null) out[id] = p;
    }
    return out;
  }

  Future<List<Map<String, dynamic>>> _applyProfileEnrichmentForMessageRows(List<Map<String, dynamic>> rows) async {
    final missing = <String>{};
    for (final r in rows) {
      final senderId = (r['sender_id'] as String?)?.trim() ?? '';
      if (senderId.isEmpty) continue;
      if (!_profileCache.containsKey(senderId)) missing.add(senderId);
    }
    if (missing.isNotEmpty) {
      await _fetchProfileBasics(missing.toList(growable: false));
    }
    return rows.map((r) {
      final senderId = (r['sender_id'] as String?)?.trim() ?? '';
      final p = _profileCache[senderId];
      if (p == null) return r;
      final out = Map<String, dynamic>.from(r);
      out['sender_profile_display_name'] = p.displayName;
      out['sender_profile_avatar_url'] = p.avatarUrl;
      out['sender_profile_national_id_number'] = p.certified ? '1' : '';
      return out;
    }).toList(growable: false);
  }

  Future<String> _resolveChatUuid(String chatId, {AppUser? me}) async {
    final raw = chatId.trim();
    if (isUuidLike(raw)) return raw;
    final parsed = _parseDirectChatVirtualId(raw);
    if (parsed == null) throw Exception('ChatId invalide.');
    final a = parsed.a;
    final b = parsed.b;
    final key = _directKey(a, b);
    return _getOrCreateChatByDirectKey(key: key, a: a, b: b, me: me);
  }

  ({String a, String b})? _parseDirectChatVirtualId(String chatId) {
    final raw = chatId.trim();
    if (!raw.startsWith('direct:')) return null;
    final key = raw.substring('direct:'.length);
    final parts = key.split('_');
    if (parts.length != 2) return null;
    final a = parts[0].trim();
    final b = parts[1].trim();
    if (a.isEmpty || b.isEmpty) return null;
    return (a: a, b: b);
  }

  bool isUuidLike(String v) => RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$').hasMatch(v.trim());

  String _directKey(String a, String b) {
    final pair = [a, b]..sort();
    return pair.join('_');
  }

  Future<String> _getOrCreateChatByDirectKey({
    required String key,
    required String a,
    required String b,
    AppUser? me,
  }) async {
    if (await _isLegacySchema()) return 'direct:$key';
    try {
      final existing = await _client.from(chatsTable).select('id').eq('direct_key', key).maybeSingle();
      if (existing != null) {
        final id = (existing['id'] as String?) ?? '';
        if (id.isNotEmpty) return id;
      }
    } catch (e) {
      debugPrint('ChatService: getOrCreateChatByDirectKey select failed key=$key err=$e');
    }

    final now = DateTime.now().toUtc().toIso8601String();
    final participants = [a, b];
    final profiles = await _fetchProfileBasics([a, b]);
    final participantName = {
      a: me?.id == a ? (me?.displayName ?? 'Utilisateur') : (profiles[a]?.displayName ?? 'Utilisateur'),
      b: me?.id == b ? (me?.displayName ?? 'Utilisateur') : (profiles[b]?.displayName ?? 'Utilisateur'),
    };

    try {
      final inserted = await _client.from(chatsTable).insert({
        'type': 'direct',
        'direct_key': key,
        'participants': participants,
        'participant_name': participantName,
        'participant_thix': {},
        'last_message': '',
        'last_message_at': null,
        'created_at': now,
        'updated_at': now,
      }).select('id').single();
      return inserted['id'] as String;
    } catch (e) {
      debugPrint('ChatService: getOrCreateChatByDirectKey insert failed key=$key err=$e');
      final existing = await _client.from(chatsTable).select('id').eq('direct_key', key).maybeSingle();
      if (existing != null) {
        return existing['id'] as String;
      }
      rethrow;
    }
  }
}
