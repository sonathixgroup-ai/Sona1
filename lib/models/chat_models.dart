// lib/models/chat_models.dart
class Conversation {
  final String id;
  final String type; // 'private', 'group', 'space'
  final String name;
  final String? avatarUrl;
  final String lastMessage;
  final String lastMessageTime;
  final int unreadCount;
  final bool isOnline;
  final bool isPinned;
  final bool isMuted;
  final List<String>? participantAvatars;

  Conversation({
    required this.id,
    required this.type,
    required this.name,
    this.avatarUrl,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.isOnline = false,
    this.isPinned = false,
    this.isMuted = false,
    this.participantAvatars,
  });
}

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String type; // 'text', 'image', 'audio', 'video', 'file', 'reaction'
  final String content;
  final String? mediaUrl;
  final int? mediaDuration;
  final String? fileName;
  final int? fileSize;
  final bool isFromMe;
  final bool isRead;
  final bool isDelivered;
  final bool isPinned;
  final bool isLiked;
  final int likesCount;
  final int commentsCount;
  final Map<String, List<String>> reactions;
  final DateTime createdAt;
  final String formattedTime;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.type,
    required this.content,
    this.mediaUrl,
    this.mediaDuration,
    this.fileName,
    this.fileSize,
    required this.isFromMe,
    this.isRead = false,
    this.isDelivered = false,
    this.isPinned = false,
    this.isLiked = false,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.reactions = const {},
    required this.createdAt,
    required this.formattedTime,
  });

  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    String? type,
    String? content,
    String? mediaUrl,
    int? mediaDuration,
    String? fileName,
    int? fileSize,
    bool? isFromMe,
    bool? isRead,
    bool? isDelivered,
    bool? isPinned,
    bool? isLiked,
    int? likesCount,
    int? commentsCount,
    Map<String, List<String>>? reactions,
    DateTime? createdAt,
    String? formattedTime,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      type: type ?? this.type,
      content: content ?? this.content,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaDuration: mediaDuration ?? this.mediaDuration,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      isFromMe: isFromMe ?? this.isFromMe,
      isRead: isRead ?? this.isRead,
      isDelivered: isDelivered ?? this.isDelivered,
      isPinned: isPinned ?? this.isPinned,
      isLiked: isLiked ?? this.isLiked,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      reactions: reactions ?? this.reactions,
      createdAt: createdAt ?? this.createdAt,
      formattedTime: formattedTime ?? this.formattedTime,
    );
  }
}

class Story {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String mediaUrl;
  final String type; // 'image', 'video'
  final bool isViewed;
  final DateTime createdAt;
  final DateTime expiresAt;

  Story({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.mediaUrl,
    required this.type,
    this.isViewed = false,
    required this.createdAt,
    required this.expiresAt,
  });
}

class Space {
  final String id;
  final String name;
  final String? description;
  final String? avatarUrl;
  final int memberCount;
  final int unreadCount;

  Space({
    required this.id,
    required this.name,
    this.description,
    this.avatarUrl,
    required this.memberCount,
    this.unreadCount = 0,
  });
}

class ChatStats {
  final int onlineCount;
  final int newMessagesCount;
  final int activeCallsCount;
  final int securityAlertsCount;

  ChatStats({
    this.onlineCount = 0,
    this.newMessagesCount = 0,
    this.activeCallsCount = 0,
    this.securityAlertsCount = 0,
  });

  ChatStats.empty()
      : onlineCount = 0,
        newMessagesCount = 0,
        activeCallsCount = 0,
        securityAlertsCount = 0;
}
