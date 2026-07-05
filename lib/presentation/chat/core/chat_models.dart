import 'package:equatable/equatable.dart';
import 'chat_constants.dart';

// ---------- Conversation ----------
class Conversation extends Equatable {
  final String id;
  final String name;
  final String? avatarUrl;
  final bool isGroup;
  final List<String> participantIds;
  final String? lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final bool isArchived;
  final bool isOnline;
  final Map<String, dynamic>? metadata;

  const Conversation({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.isGroup,
    required this.participantIds,
    this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.isArchived = false,
    this.isOnline = false,
    this.metadata,
  });

  // ✅ Adapté aux colonnes réelles de la table thix_chat_chats
  factory Conversation.fromJson(Map<String, dynamic> json) {
    // participants est un JSONB : soit une liste d'IDs, soit un tableau
    List<String> participants = [];
    final rawParticipants = json['participants'];
    if (rawParticipants is List) {
      participants = rawParticipants.map((e) => e.toString()).toList();
    } else if (rawParticipants is String) {
      // si c'est une chaîne JSON, on peut la parser
      try {
        final list = jsonDecode(rawParticipants) as List;
        participants = list.map((e) => e.toString()).toList();
      } catch (_) {}
    }

    // participant_name est un JSONB : map userId -> displayName
    Map<String, String> participantNames = {};
    final rawNames = json['participant_name'];
    if (rawNames is Map) {
      participantNames = Map<String, String>.from(rawNames.map((k, v) => MapEntry(k.toString(), v?.toString() ?? '')));
    }

    // Déterminer le nom : si title non vide, utiliser title ; sinon dériver des participants
    String name = (json['title']?.toString() ?? '').trim();
    if (name.isEmpty) {
      // On prend les noms des participants (autre que l'utilisateur courant)
      // mais ici on ne connaît pas l'userId courant, on prend le premier nom trouvé
      final names = participantNames.values.where((n) => n.isNotEmpty).toList();
      if (names.isNotEmpty) {
        name = names.join(', ');
      } else {
        name = participants.isNotEmpty ? 'Conversation' : 'Sans nom';
      }
    }

    return Conversation(
      id: json['id']?.toString() ?? '',
      name: name,
      avatarUrl: json['avatar_url']?.toString(),
      isGroup: json['type'] == 'group',
      participantIds: participants,
      lastMessage: json['last_message']?.toString(),
      lastMessageTime: _parseDateTime(json['last_message_at'] ?? json['updated_at'] ?? json['created_at']),
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
      isArchived: json['archived_at'] != null,
      isOnline: false,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  static DateTime _parseDateTime(Object? value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }
    return DateTime.now();
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'avatar_url': avatarUrl,
    'is_group': isGroup,
    'participant_ids': participantIds,
    'last_message': lastMessage,
    'last_message_time': lastMessageTime.toIso8601String(),
    'unread_count': unreadCount,
    'is_archived': isArchived,
    'is_online': isOnline,
    'metadata': metadata,
  };

  @override
  List<Object?> get props => [id, name, lastMessageTime, unreadCount];
}

// ---------- Message (inchangé) ----------
class Message extends Equatable {
  final String id;
  final String conversationId;
  final String senderId;
  final String type;
  final String? content;
  final String? mediaUrl;
  final String? thumbnailUrl;
  final int? durationSeconds;
  final int? fileSize;
  final DateTime sentAt;
  final DateTime? editedAt;
  final bool isDeleted;
  final List<String> reactions;
  final Map<String, dynamic>? metadata;

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.type,
    this.content,
    this.mediaUrl,
    this.thumbnailUrl,
    this.durationSeconds,
    this.fileSize,
    required this.sentAt,
    this.editedAt,
    this.isDeleted = false,
    this.reactions = const [],
    this.metadata,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id']?.toString() ?? '',
      conversationId: json['chat_id']?.toString() ?? json['conversation_id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'text',
      content: json['content']?.toString(),
      mediaUrl: json['media_url']?.toString(),
      thumbnailUrl: json['thumbnail_url']?.toString(),
      durationSeconds: (json['duration_seconds'] as num?)?.toInt(),
      fileSize: (json['file_size'] as num?)?.toInt(),
      sentAt: _parseDateTime(json['created_at'] ?? json['sent_at']),
      editedAt: json['edited_at'] != null ? _parseDateTime(json['edited_at']) : null,
      isDeleted: json['is_deleted'] == true,
      reactions: json['reactions'] is List ? List<String>.from(json['reactions']) : [],
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  static DateTime _parseDateTime(Object? value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }
    return DateTime.now();
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'conversation_id': conversationId,
    'sender_id': senderId,
    'type': type,
    'content': content,
    'media_url': mediaUrl,
    'thumbnail_url': thumbnailUrl,
    'duration_seconds': durationSeconds,
    'file_size': fileSize,
    'sent_at': sentAt.toIso8601String(),
    'edited_at': editedAt?.toIso8601String(),
    'is_deleted': isDeleted,
    'reactions': reactions,
    'metadata': metadata,
  };

  @override
  List<Object?> get props => [id, conversationId, sentAt];
}

// ---------- Les autres classes (Story, ChatStats, etc.) inchangées ----------
// ... (vous gardez vos définitions existantes)
