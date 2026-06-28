/// Conversation model for THIX CHAT
class Conversation {
  final String id;
  final String name;
  final String? description;
  final String? avatarUrl;
  final bool isGroup;
  final bool isPrivate;
  final bool isEncrypted;
  final List<String> memberIds;
  final List<String> adminIds;
  final List<String> moderatorIds;
  final String createdById;
  final DateTime createdAt;
  final DateTime lastMessageAt;
  final String? lastMessagePreview;
  final int unreadCount;
  final bool isMuted;
  final bool isArchived;
  final bool isPinned;
  final bool isSpammed;
  final bool isBlocked;
  final List<String> pinnedMessageIds;
  final String? joinCode;
  final int maxMembers;
  final ConversationSettings settings;

  const Conversation({
    required this.id,
    required this.name,
    this.description,
    this.avatarUrl,
    this.isGroup = false,
    this.isPrivate = true,
    this.isEncrypted = true,
    this.memberIds = const [],
    this.adminIds = const [],
    this.moderatorIds = const [],
    required this.createdById,
    required this.createdAt,
    required this.lastMessageAt,
    this.lastMessagePreview,
    this.unreadCount = 0,
    this.isMuted = false,
    this.isArchived = false,
    this.isPinned = false,
    this.isSpammed = false,
    this.isBlocked = false,
    this.pinnedMessageIds = const [],
    this.joinCode,
    this.maxMembers = 500,
    required this.settings,
  });

  Conversation copyWith({
    String? id,
    String? name,
    String? description,
    String? avatarUrl,
    bool? isGroup,
    bool? isPrivate,
    bool? isEncrypted,
    List<String>? memberIds,
    List<String>? adminIds,
    List<String>? moderatorIds,
    String? createdById,
    DateTime? createdAt,
    DateTime? lastMessageAt,
    String? lastMessagePreview,
    int? unreadCount,
    bool? isMuted,
    bool? isArchived,
    bool? isPinned,
    bool? isSpammed,
    bool? isBlocked,
    List<String>? pinnedMessageIds,
    String? joinCode,
    int? maxMembers,
    ConversationSettings? settings,
  }) {
    return Conversation(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isGroup: isGroup ?? this.isGroup,
      isPrivate: isPrivate ?? this.isPrivate,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      memberIds: memberIds ?? this.memberIds,
      adminIds: adminIds ?? this.adminIds,
      moderatorIds: moderatorIds ?? this.moderatorIds,
      createdById: createdById ?? this.createdById,
      createdAt: createdAt ?? this.createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      unreadCount: unreadCount ?? this.unreadCount,
      isMuted: isMuted ?? this.isMuted,
      isArchived: isArchived ?? this.isArchived,
      isPinned: isPinned ?? this.isPinned,
      isSpammed: isSpammed ?? this.isSpammed,
      isBlocked: isBlocked ?? this.isBlocked,
      pinnedMessageIds: pinnedMessageIds ?? this.pinnedMessageIds,
      joinCode: joinCode ?? this.joinCode,
      maxMembers: maxMembers ?? this.maxMembers,
      settings: settings ?? this.settings,
    );
  }
}

class ConversationSettings {
  final bool allowPinMessages;
  final bool allowReactions;
  final bool allowForwarding;
  final bool allowScreenshots;
  final bool requireApprovalForNewMembers;
  final Duration? messageAutoDeleteDuration;
  final List<String> bannedWords;
  final NotificationLevel notificationLevel;

  const ConversationSettings({
    this.allowPinMessages = true,
    this.allowReactions = true,
    this.allowForwarding = true,
    this.allowScreenshots = false,
    this.requireApprovalForNewMembers = false,
    this.messageAutoDeleteDuration,
    this.bannedWords = const [],
    this.notificationLevel = NotificationLevel.all,
  });
}

enum NotificationLevel { all, mentions, none }
