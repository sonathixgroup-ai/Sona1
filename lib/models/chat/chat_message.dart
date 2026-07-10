class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;  // 👈 AJOUTÉ
  final String? senderAvatar;  // 👈 AJOUTÉ (optionnel)
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? mediaUrl;
  final String? mediaType;
  final bool isRead;
  final bool isDelivered;
  final String? replyToId;
  final bool isDeleted;
  final bool isEphemeral;
  final int? ephemeralDuration;
  final DateTime? deleteAt;
  final bool isCodeSnippet;
  final String? codeLanguage;
  final String? codeContent;
  final List<MessageReaction> reactions;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,  // 👈 REQUIS
    this.senderAvatar,  // 👈 OPTIONNEL
    required this.content,
    required this.createdAt,
    this.updatedAt,
    this.mediaUrl,
    this.mediaType,
    this.isRead = false,
    this.isDelivered = false,
    this.replyToId,
    this.isDeleted = false,
    this.isEphemeral = false,
    this.ephemeralDuration,
    this.deleteAt,
    this.isCodeSnippet = false,
    this.codeLanguage,
    this.codeContent,
    this.reactions = const [],
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    // 👈 Récupérer les infos du profil
    final profile = json['profiles'] as Map<String, dynamic>?;
    
    return ChatMessage(
      id: json['id'] ?? '',
      conversationId: json['conversation_id'] ?? '',
      senderId: json['sender_id'] ?? '',
      senderName: profile?['full_name'] ?? profile?['username'] ?? 'Utilisateur inconnu',  // 👈
      senderAvatar: profile?['avatar_url'],  // 👈
      content: json['content'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      mediaUrl: json['media_url'],
      mediaType: json['media_type'],
      isRead: json['is_read'] ?? false,
      isDelivered: json['is_delivered'] ?? false,
      replyToId: json['reply_to_id'],
      isDeleted: json['is_deleted'] ?? false,
      isEphemeral: json['is_ephemeral'] ?? false,
      ephemeralDuration: json['ephemeral_duration'],
      deleteAt: json['delete_at'] != null
          ? DateTime.parse(json['delete_at'])
          : null,
      isCodeSnippet: json['is_code_snippet'] ?? false,
      codeLanguage: json['code_language'],
      codeContent: json['code_content'],
      reactions: (json['reactions'] as List?)
              ?.map((r) => MessageReaction.fromJson(r))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'conversation_id': conversationId,
    'sender_id': senderId,
    'content': content,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
    'media_url': mediaUrl,
    'media_type': mediaType,
    'is_read': isRead,
    'is_delivered': isDelivered,
    'reply_to_id': replyToId,
    'is_deleted': isDeleted,
    'is_ephemeral': isEphemeral,
    'ephemeral_duration': ephemeralDuration,
    'delete_at': deleteAt?.toIso8601String(),
    'is_code_snippet': isCodeSnippet,
    'code_language': codeLanguage,
    'code_content': codeContent,
    'reactions': reactions.map((r) => r.toJson()).toList(),
  };

  ChatMessage copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderName,  // 👈
    String? senderAvatar,  // 👈
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? mediaUrl,
    String? mediaType,
    bool? isRead,
    bool? isDelivered,
    String? replyToId,
    bool? isDeleted,
    bool? isEphemeral,
    int? ephemeralDuration,
    DateTime? deleteAt,
    bool? isCodeSnippet,
    String? codeLanguage,
    String? codeContent,
    List<MessageReaction>? reactions,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,  // 👈
      senderAvatar: senderAvatar ?? this.senderAvatar,  // 👈
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      isRead: isRead ?? this.isRead,
      isDelivered: isDelivered ?? this.isDelivered,
      replyToId: replyToId ?? this.replyToId,
      isDeleted: isDeleted ?? this.isDeleted,
      isEphemeral: isEphemeral ?? this.isEphemeral,
      ephemeralDuration: ephemeralDuration ?? this.ephemeralDuration,
      deleteAt: deleteAt ?? this.deleteAt,
      isCodeSnippet: isCodeSnippet ?? this.isCodeSnippet,
      codeLanguage: codeLanguage ?? this.codeLanguage,
      codeContent: codeContent ?? this.codeContent,
      reactions: reactions ?? this.reactions,
    );
  }

  bool get isActive => !isDeleted && (deleteAt == null || deleteAt!.isAfter(DateTime.now()));
}
