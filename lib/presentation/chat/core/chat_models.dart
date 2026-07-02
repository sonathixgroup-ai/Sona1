// lib/presentation/chat/core/chat_models.dart
// [PARTIE] Modèles de données

import 'package:equatable/equatable.dart';

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
  final Map<String, dynamic>? metadata; // tag, etc.

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
    this.metadata,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'],
      name: json['name'],
      avatarUrl: json['avatar_url'],
      isGroup: json['is_group'] ?? false,
      participantIds: List<String>.from(json['participant_ids'] ?? []),
      lastMessage: json['last_message'],
      lastMessageTime: DateTime.parse(json['last_message_time']),
      unreadCount: json['unread_count'] ?? 0,
      isArchived: json['is_archived'] ?? false,
      metadata: json['metadata'],
    );
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
    'metadata': metadata,
  };

  @override
  List<Object?> get props => [id, name, lastMessageTime, unreadCount];
}

// ---------- Message ----------
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
      id: json['id'],
      conversationId: json['conversation_id'],
      senderId: json['sender_id'],
      type: json['type'],
      content: json['content'],
      mediaUrl: json['media_url'],
      thumbnailUrl: json['thumbnail_url'],
      durationSeconds: json['duration_seconds'],
      fileSize: json['file_size'],
      sentAt: DateTime.parse(json['sent_at']),
      editedAt: json['edited_at'] != null ? DateTime.parse(json['edited_at']) : null,
      isDeleted: json['is_deleted'] ?? false,
      reactions: List<String>.from(json['reactions'] ?? []),
      metadata: json['metadata'],
    );
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

// ---------- Message éphémère (spécialisation) ----------
class EphemeralMessage extends Message {
  final int durationSeconds;
  final DateTime? openedAt;

  const EphemeralMessage({
    required super.id,
    required super.conversationId,
    required super.senderId,
    required super.type,
    super.content,
    super.mediaUrl,
    required this.durationSeconds,
    this.openedAt,
  });
}

// ---------- Message confidentiel (spécialisation) ----------
class ConfidentialMessage extends Message {
  final String requiredCodeHash;
  final bool isBiometric;
  final bool isOpened;

  const ConfidentialMessage({
    required super.id,
    required super.conversationId,
    required super.senderId,
    required super.type,
    super.content,
    super.mediaUrl,
    required this.requiredCodeHash,
    this.isBiometric = false,
    this.isOpened = false,
  });
}

// ---------- Utilisateur (pour présence) ----------
class ChatUser extends Equatable {
  final String id;
  final String displayName;
  final String? avatarUrl;
  final String status;
  final DateTime? lastSeen;

  const ChatUser({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    this.status = ChatConstants.statusOffline,
    this.lastSeen,
  });

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      id: json['id'],
      displayName: json['display_name'],
      avatarUrl: json['avatar_url'],
      status: json['status'] ?? ChatConstants.statusOffline,
      lastSeen: json['last_seen'] != null ? DateTime.parse(json['last_seen']) : null,
    );
  }

  @override
  List<Object?> get props => [id, status];
}

// ---------- Story (pour l'affichage) ----------
class Story extends Equatable {
  final String id;
  final String name;
  final String? avatarUrl;
  final bool hasNewStory;

  const Story({required this.id, required this.name, this.avatarUrl, this.hasNewStory = false});

  @override
  List<Object?> get props => [id];
}

// ---------- Statistiques du chat ----------
class ChatStats {
  final int onlineCount;
  final int newMessagesCount;
  final int activeMeetingsCount;
  final int securityAlertsCount;

  const ChatStats({
    this.onlineCount = 0,
    this.newMessagesCount = 0,
    this.activeMeetingsCount = 0,
    this.securityAlertsCount = 0,
  });
}
