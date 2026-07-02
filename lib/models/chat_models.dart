// lib/models/chat_models.dart

// ============================================================
// UTILISATEUR
// ============================================================
class ChatUser {
  final String id;
  final String displayName;
  final String? email;
  final String? photoURL;
  final String? phone;
  final String status; // online, offline, away, busy
  final DateTime? lastSeen;

  ChatUser({
    required this.id,
    required this.displayName,
    this.email,
    this.photoURL,
    this.phone,
    this.status = 'offline',
    this.lastSeen,
  });

  factory ChatUser.fromJson(Map<String, dynamic> json) => ChatUser(
        id: json['id'],
        displayName: json['display_name'] ?? json['displayName'],
        email: json['email'],
        photoURL: json['photo_url'] ?? json['photoURL'],
        phone: json['phone'],
        status: json['status'] ?? 'offline',
        lastSeen: json['last_seen'] != null
            ? DateTime.parse(json['last_seen'])
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'display_name': displayName,
        'email': email,
        'photo_url': photoURL,
        'phone': phone,
        'status': status,
        'last_seen': lastSeen?.toIso8601String(),
      };
}

// ============================================================
// CONVERSATION
// ============================================================
enum ConversationType { private, group, space }
enum ConversationStatus { active, archived, deleted }

class Conversation {
  final String id;
  final ConversationType type;
  final String? name;
  final String? avatarURL;
  final String createdBy;
  final List<String> participantIds;
  final String? lastMessageId;
  final DateTime? lastMessageAt;
  final ConversationStatus status;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  Conversation({
    required this.id,
    required this.type,
    this.name,
    this.avatarURL,
    required this.createdBy,
    required this.participantIds,
    this.lastMessageId,
    this.lastMessageAt,
    this.status = ConversationStatus.active,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
        id: json['id'],
        type: _stringToConversationType(json['type']),
        name: json['name'],
        avatarURL: json['avatar_url'] ?? json['avatarURL'],
        createdBy: json['created_by'],
        participantIds: List<String>.from(json['participants'] ?? []),
        lastMessageId: json['last_message_id'],
        lastMessageAt: json['last_message_at'] != null
            ? DateTime.parse(json['last_message_at'])
            : null,
        status: _stringToConversationStatus(json['status'] ?? 'active'),
        metadata: json['metadata'],
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: DateTime.parse(json['updated_at']),
      );

  static ConversationType _stringToConversationType(String type) {
    switch (type) {
      case 'private':
        return ConversationType.private;
      case 'group':
        return ConversationType.group;
      case 'space':
        return ConversationType.space;
      default:
        return ConversationType.private;
    }
  }

  static String _conversationTypeToString(ConversationType type) {
    switch (type) {
      case ConversationType.private:
        return 'private';
      case ConversationType.group:
        return 'group';
      case ConversationType.space:
        return 'space';
    }
  }

  static ConversationStatus _stringToConversationStatus(String status) {
    switch (status) {
      case 'archived':
        return ConversationStatus.archived;
      case 'deleted':
        return ConversationStatus.deleted;
      default:
        return ConversationStatus.active;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': _conversationTypeToString(type),
        'name': name,
        'avatar_url': avatarURL,
        'created_by': createdBy,
        'participants': participantIds,
        'last_message_id': lastMessageId,
        'last_message_at': lastMessageAt?.toIso8601String(),
        'status': status.toString().split('.').last,
        'metadata': metadata,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}

// ============================================================
// PARTICIPANT
// ============================================================
enum ParticipantRole { admin, moderator, member, guest }

class Participant {
  final String userId;
  final String conversationId;
  final ParticipantRole role;
  final DateTime lastReadAt;
  final int unreadCount;
  final bool isMuted;
  final bool pinned;
  final DateTime joinedAt;

  Participant({
    required this.userId,
    required this.conversationId,
    this.role = ParticipantRole.member,
    required this.lastReadAt,
    this.unreadCount = 0,
    this.isMuted = false,
    this.pinned = false,
    required this.joinedAt,
  });

  factory Participant.fromJson(Map<String, dynamic> json) => Participant(
        userId: json['user_id'],
        conversationId: json['conversation_id'],
        role: _stringToParticipantRole(json['role'] ?? 'member'),
        lastReadAt: DateTime.parse(json['last_read_at']),
        unreadCount: json['unread_count'] ?? 0,
        isMuted: json['is_muted'] ?? false,
        pinned: json['pinned'] ?? false,
        joinedAt: DateTime.parse(json['joined_at']),
      );

  static ParticipantRole _stringToParticipantRole(String role) {
    switch (role) {
      case 'admin':
        return ParticipantRole.admin;
      case 'moderator':
        return ParticipantRole.moderator;
      case 'guest':
        return ParticipantRole.guest;
      default:
        return ParticipantRole.member;
    }
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'conversation_id': conversationId,
        'role': role.toString().split('.').last,
        'last_read_at': lastReadAt.toIso8601String(),
        'unread_count': unreadCount,
        'is_muted': isMuted,
        'pinned': pinned,
        'joined_at': joinedAt.toIso8601String(),
      };
}

// ============================================================
// MESSAGE
// ============================================================
enum MessageType { text, image, audio, video, file, reaction, poll, location, contact, call }
enum MessageStatus { sending, sent, delivered, read, failed }

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final MessageType type;
  final String content;
  final String? mediaURL;
  final int? mediaDuration;
  final String? fileName;
  final int? fileSize;
  final String? replyToId;
  final bool isPinned;
  final bool isPriority;
  final Map<String, List<String>> reactions;
  final MessageStatus status;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.type,
    required this.content,
    this.mediaURL,
    this.mediaDuration,
    this.fileName,
    this.fileSize,
    this.replyToId,
    this.isPinned = false,
    this.isPriority = false,
    this.reactions = const {},
    this.status = MessageStatus.sent,
    this.deliveredAt,
    this.readAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'],
        conversationId: json['conversation_id'],
        senderId: json['sender_id'],
        type: stringToMessageType(json['type'] ?? 'text'),
        content: json['content'] ?? '',
        mediaURL: json['media_url'] ?? json['mediaURL'],
        mediaDuration: json['media_duration'],
        fileName: json['file_name'],
        fileSize: json['file_size'],
        replyToId: json['reply_to_id'],
        isPinned: json['is_pinned'] ?? false,
        isPriority: json['is_priority'] ?? false,
        reactions: Map<String, List<String>>.from(json['reactions'] ?? {}),
        status: stringToMessageStatus(json['status'] ?? 'sent'),
        deliveredAt: json['delivered_at'] != null
            ? DateTime.parse(json['delivered_at'])
            : null,
        readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: DateTime.parse(json['updated_at']),
      );

  static MessageType stringToMessageType(String type) {
    switch (type) {
      case 'text':
        return MessageType.text;
      case 'image':
        return MessageType.image;
      case 'audio':
        return MessageType.audio;
      case 'video':
        return MessageType.video;
      case 'file':
        return MessageType.file;
      case 'reaction':
        return MessageType.reaction;
      case 'poll':
        return MessageType.poll;
      case 'location':
        return MessageType.location;
      case 'contact':
        return MessageType.contact;
      case 'call':
        return MessageType.call;
      default:
        return MessageType.text;
    }
  }

  static String messageTypeToString(MessageType type) {
    switch (type) {
      case MessageType.text:
        return 'text';
      case MessageType.image:
        return 'image';
      case MessageType.audio:
        return 'audio';
      case MessageType.video:
        return 'video';
      case MessageType.file:
        return 'file';
      case MessageType.reaction:
        return 'reaction';
      case MessageType.poll:
        return 'poll';
      case MessageType.location:
        return 'location';
      case MessageType.contact:
        return 'contact';
      case MessageType.call:
        return 'call';
    }
  }

  static MessageStatus stringToMessageStatus(String status) {
    switch (status) {
      case 'sending':
        return MessageStatus.sending;
      case 'sent':
        return MessageStatus.sent;
      case 'delivered':
        return MessageStatus.delivered;
      case 'read':
        return MessageStatus.read;
      case 'failed':
        return MessageStatus.failed;
      default:
        return MessageStatus.sent;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversation_id': conversationId,
        'sender_id': senderId,
        'type': messageTypeToString(type),
        'content': content,
        'media_url': mediaURL,
        'media_duration': mediaDuration,
        'file_name': fileName,
        'file_size': fileSize,
        'reply_to_id': replyToId,
        'is_pinned': isPinned,
        'is_priority': isPriority,
        'reactions': reactions,
        'status': status.toString().split('.').last,
        'delivered_at': deliveredAt?.toIso8601String(),
        'read_at': readAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  ChatMessage copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    MessageType? type,
    String? content,
    String? mediaURL,
    int? mediaDuration,
    String? fileName,
    int? fileSize,
    String? replyToId,
    bool? isPinned,
    bool? isPriority,
    Map<String, List<String>>? reactions,
    MessageStatus? status,
    DateTime? deliveredAt,
    DateTime? readAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      type: type ?? this.type,
      content: content ?? this.content,
      mediaURL: mediaURL ?? this.mediaURL,
      mediaDuration: mediaDuration ?? this.mediaDuration,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      replyToId: replyToId ?? this.replyToId,
      isPinned: isPinned ?? this.isPinned,
      isPriority: isPriority ?? this.isPriority,
      reactions: reactions ?? this.reactions,
      status: status ?? this.status,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// ============================================================
// MESSAGE ÉPHÉMÈRE
// ============================================================
class EphemeralMessage extends ChatMessage {
  final int ttl; // secondes
  final DateTime expiresAt;
  final List<String> viewedBy;
  final bool screenshotNotified;

  EphemeralMessage({
    required super.id,
    required super.conversationId,
    required super.senderId,
    required super.type,
    required super.content,
    super.mediaURL,
    super.mediaDuration,
    super.fileName,
    super.fileSize,
    super.replyToId,
    super.isPinned,
    super.isPriority,
    super.reactions,
    super.status,
    super.deliveredAt,
    super.readAt,
    required super.createdAt,   // ✅ fourni
    required super.updatedAt,   // ✅ fourni
    required this.ttl,
    required this.expiresAt,
    this.viewedBy = const [],
    this.screenshotNotified = false,
  });

  factory EphemeralMessage.fromJson(Map<String, dynamic> json) => EphemeralMessage(
        id: json['id'],
        conversationId: json['conversation_id'],
        senderId: json['sender_id'],
        type: ChatMessage.stringToMessageType(json['type'] ?? 'text'), // ✅ qualifié
        content: json['content'] ?? '',
        mediaURL: json['media_url'] ?? json['mediaURL'],
        mediaDuration: json['media_duration'],
        fileName: json['file_name'],
        fileSize: json['file_size'],
        replyToId: json['reply_to_id'],
        isPinned: json['is_pinned'] ?? false,
        isPriority: json['is_priority'] ?? false,
        reactions: Map<String, List<String>>.from(json['reactions'] ?? {}),
        status: ChatMessage.stringToMessageStatus(json['status'] ?? 'sent'), // ✅ qualifié
        deliveredAt: json['delivered_at'] != null
            ? DateTime.parse(json['delivered_at'])
            : null,
        readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: DateTime.parse(json['updated_at']),
        ttl: json['ttl'] ?? 30,
        expiresAt: DateTime.parse(json['expires_at']),
        viewedBy: List<String>.from(json['viewed_by'] ?? []),
        screenshotNotified: json['screenshot_notified'] ?? false,
      );

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'ttl': ttl,
        'expires_at': expiresAt.toIso8601String(),
        'viewed_by': viewedBy,
        'screenshot_notified': screenshotNotified,
      };

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

// ============================================================
// APPEL
// ============================================================
enum CallType { audio, video }
enum CallStatus { initiated, ringing, ongoing, ended, missed, rejected }

class Call {
  final String id;
  final String conversationId;
  final String callerId;
  final String receiverId;
  final CallType type;
  final CallStatus status;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int? duration; // secondes
  final String? recordingURL;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  Call({
    required this.id,
    required this.conversationId,
    required this.callerId,
    required this.receiverId,
    required this.type,
    required this.status,
    this.startedAt,
    this.endedAt,
    this.duration,
    this.recordingURL,
    this.metadata,
    required this.createdAt,
  });

  factory Call.fromJson(Map<String, dynamic> json) => Call(
        id: json['id'],
        conversationId: json['conversation_id'],
        callerId: json['caller_id'],
        receiverId: json['receiver_id'],
        type: json['type'] == 'video' ? CallType.video : CallType.audio,
        status: _stringToCallStatus(json['status'] ?? 'initiated'),
        startedAt: json['started_at'] != null
            ? DateTime.parse(json['started_at'])
            : null,
        endedAt: json['ended_at'] != null
            ? DateTime.parse(json['ended_at'])
            : null,
        duration: json['duration'],
        recordingURL: json['recording_url'],
        metadata: json['metadata'],
        createdAt: DateTime.parse(json['created_at']),
      );

  static CallStatus _stringToCallStatus(String status) {
    switch (status) {
      case 'initiated':
        return CallStatus.initiated;
      case 'ringing':
        return CallStatus.ringing;
      case 'ongoing':
        return CallStatus.ongoing;
      case 'ended':
        return CallStatus.ended;
      case 'missed':
        return CallStatus.missed;
      case 'rejected':
        return CallStatus.rejected;
      default:
        return CallStatus.initiated;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversation_id': conversationId,
        'caller_id': callerId,
        'receiver_id': receiverId,
        'type': type == CallType.video ? 'video' : 'audio',
        'status': status.toString().split('.').last,
        'started_at': startedAt?.toIso8601String(),
        'ended_at': endedAt?.toIso8601String(),
        'duration': duration,
        'recording_url': recordingURL,
        'metadata': metadata,
        'created_at': createdAt.toIso8601String(),
      };
}

// ============================================================
// SONDAGE
// ============================================================
class Poll {
  final String id;
  final String conversationId;
  final String messageId;
  final String question;
  final List<String> options;
  final Map<int, List<String>> votes; // optionIndex -> userId[]
  final bool isAnonymous;
  final bool isMultiple;
  final DateTime? expiresAt;
  final String createdBy;
  final DateTime createdAt;

  Poll({
    required this.id,
    required this.conversationId,
    required this.messageId,
    required this.question,
    required this.options,
    this.votes = const {},
    this.isAnonymous = false,
    this.isMultiple = false,
    this.expiresAt,
    required this.createdBy,
    required this.createdAt,
  });

  factory Poll.fromJson(Map<String, dynamic> json) {
    final votesMap = <int, List<String>>{};
    final rawVotes = json['votes'] as Map<String, dynamic>? ?? {};
    rawVotes.forEach((key, value) {
      votesMap[int.parse(key)] = List<String>.from(value);
    });
    return Poll(
      id: json['id'],
      conversationId: json['conversation_id'],
      messageId: json['message_id'],
      question: json['question'],
      options: List<String>.from(json['options']),
      votes: votesMap,
      isAnonymous: json['is_anonymous'] ?? false,
      isMultiple: json['is_multiple'] ?? false,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : null,
      createdBy: json['created_by'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversation_id': conversationId,
        'message_id': messageId,
        'question': question,
        'options': options,
        'votes': votes.map((key, value) => MapEntry(key.toString(), value)),
        'is_anonymous': isAnonymous,
        'is_multiple': isMultiple,
        'expires_at': expiresAt?.toIso8601String(),
        'created_by': createdBy,
        'created_at': createdAt.toIso8601String(),
      };

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  Map<int, int> get results {
    final result = <int, int>{};
    for (var i = 0; i < options.length; i++) {
      result[i] = votes[i]?.length ?? 0;
    }
    return result;
  }

  int get totalVotes => votes.values.fold(0, (sum, list) => sum + list.length);
}

// ============================================================
// MESSAGE PROGRAMMÉ
// ============================================================
enum RecurringPattern { none, daily, weekly, monthly }
enum ScheduledStatus { pending, sent, cancelled }

class ScheduledMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final String? mediaURL;
  final DateTime scheduledAt;
  final RecurringPattern recurring;
  final DateTime? lastSentAt;
  final DateTime? nextSentAt;
  final ScheduledStatus status;
  final DateTime createdAt;

  ScheduledMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    this.mediaURL,
    required this.scheduledAt,
    this.recurring = RecurringPattern.none,
    this.lastSentAt,
    this.nextSentAt,
    this.status = ScheduledStatus.pending,
    required this.createdAt,
  });

  factory ScheduledMessage.fromJson(Map<String, dynamic> json) => ScheduledMessage(
        id: json['id'],
        conversationId: json['conversation_id'],
        senderId: json['sender_id'],
        content: json['content'],
        mediaURL: json['media_url'],
        scheduledAt: DateTime.parse(json['scheduled_at']),
        recurring: _stringToRecurringPattern(json['recurring'] ?? 'none'),
        lastSentAt: json['last_sent_at'] != null
            ? DateTime.parse(json['last_sent_at'])
            : null,
        nextSentAt: json['next_sent_at'] != null
            ? DateTime.parse(json['next_sent_at'])
            : null,
        status: _stringToScheduledStatus(json['status'] ?? 'pending'),
        createdAt: DateTime.parse(json['created_at']),
      );

  static RecurringPattern _stringToRecurringPattern(String pattern) {
    switch (pattern) {
      case 'daily':
        return RecurringPattern.daily;
      case 'weekly':
        return RecurringPattern.weekly;
      case 'monthly':
        return RecurringPattern.monthly;
      default:
        return RecurringPattern.none;
    }
  }

  static ScheduledStatus _stringToScheduledStatus(String status) {
    switch (status) {
      case 'sent':
        return ScheduledStatus.sent;
      case 'cancelled':
        return ScheduledStatus.cancelled;
      default:
        return ScheduledStatus.pending;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversation_id': conversationId,
        'sender_id': senderId,
        'content': content,
        'media_url': mediaURL,
        'scheduled_at': scheduledAt.toIso8601String(),
        'recurring': recurring.toString().split('.').last,
        'last_sent_at': lastSentAt?.toIso8601String(),
        'next_sent_at': nextSentAt?.toIso8601String(),
        'status': status.toString().split('.').last,
        'created_at': createdAt.toIso8601String(),
      };
}

// ============================================================
// ACCUSÉ DE LECTURE
// ============================================================
class ReadReceipt {
  final String messageId;
  final String userId;
  final DateTime? deliveredAt;
  final DateTime? readAt;

  ReadReceipt({
    required this.messageId,
    required this.userId,
    this.deliveredAt,
    this.readAt,
  });

  factory ReadReceipt.fromJson(Map<String, dynamic> json) => ReadReceipt(
        messageId: json['message_id'],
        userId: json['user_id'],
        deliveredAt: json['delivered_at'] != null
            ? DateTime.parse(json['delivered_at'])
            : null,
        readAt: json['read_at'] != null
            ? DateTime.parse(json['read_at'])
            : null,
      );

  Map<String, dynamic> toJson() => {
        'message_id': messageId,
        'user_id': userId,
        'delivered_at': deliveredAt?.toIso8601String(),
        'read_at': readAt?.toIso8601String(),
      };

  bool get isDelivered => deliveredAt != null;
  bool get isRead => readAt != null;
}

// ============================================================
// LOCALISATION PARTAGÉE
// ============================================================
class SharedLocation {
  final String id;
  final String conversationId;
  final String userId;
  final double latitude;
  final double longitude;
  final String? address;
  final DateTime? expiresAt;
  final DateTime sharedAt;

  SharedLocation({
    required this.id,
    required this.conversationId,
    required this.userId,
    required this.latitude,
    required this.longitude,
    this.address,
    this.expiresAt,
    required this.sharedAt,
  });

  factory SharedLocation.fromJson(Map<String, dynamic> json) => SharedLocation(
        id: json['id'],
        conversationId: json['conversation_id'],
        userId: json['user_id'],
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        address: json['address'],
        expiresAt: json['expires_at'] != null
            ? DateTime.parse(json['expires_at'])
            : null,
        sharedAt: DateTime.parse(json['shared_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversation_id': conversationId,
        'user_id': userId,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'expires_at': expiresAt?.toIso8601String(),
        'shared_at': sharedAt.toIso8601String(),
      };

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
}

// ============================================================
// PRÉSENCE (STATUT EN LIGNE)
// ============================================================
enum UserStatus { online, offline, away, busy }

class Presence {
  final String userId;
  final UserStatus status;
  final String? customStatus;
  final DateTime lastSeen;
  final String? typingIn; // conversationId ou null
  final DateTime updatedAt;

  Presence({
    required this.userId,
    required this.status,
    this.customStatus,
    required this.lastSeen,
    this.typingIn,
    required this.updatedAt,
  });

  factory Presence.fromJson(Map<String, dynamic> json) => Presence(
        userId: json['user_id'],
        status: _stringToUserStatus(json['status'] ?? 'offline'),
        customStatus: json['custom_status'],
        lastSeen: DateTime.parse(json['last_seen']),
        typingIn: json['typing_in'],
        updatedAt: DateTime.parse(json['updated_at']),
      );

  static UserStatus _stringToUserStatus(String status) {
    switch (status) {
      case 'online':
        return UserStatus.online;
      case 'offline':
        return UserStatus.offline;
      case 'away':
        return UserStatus.away;
      case 'busy':
        return UserStatus.busy;
      default:
        return UserStatus.offline;
    }
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'status': status.toString().split('.').last,
        'custom_status': customStatus,
        'last_seen': lastSeen.toIso8601String(),
        'typing_in': typingIn,
        'updated_at': updatedAt.toIso8601String(),
      };

  bool get isOnline => status == UserStatus.online;
}
