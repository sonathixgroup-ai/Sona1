/// User model for THIX CHAT
class ChatUser {
  final String id;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final String? statusMessage;
  final UserStatus status;
  final DateTime? lastSeen;
  final bool isOnline;
  final bool isVerified;
  final bool isBlocked;
  final bool blockingMe;
  final bool isFavorite;
  final List<String> mutualFriends;
  final UserPrivacy privacy;

  const ChatUser({
    required this.id,
    required this.username,
    this.displayName,
    this.avatarUrl,
    this.statusMessage,
    this.status = UserStatus.online,
    this.lastSeen,
    this.isOnline = false,
    this.isVerified = false,
    this.isBlocked = false,
    this.blockingMe = false,
    this.isFavorite = false,
    this.mutualFriends = const [],
    required this.privacy,
  });

  ChatUser copyWith({
    String? id,
    String? username,
    String? displayName,
    String? avatarUrl,
    String? statusMessage,
    UserStatus? status,
    DateTime? lastSeen,
    bool? isOnline,
    bool? isVerified,
    bool? isBlocked,
    bool? blockingMe,
    bool? isFavorite,
    List<String>? mutualFriends,
    UserPrivacy? privacy,
  }) {
    return ChatUser(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      statusMessage: statusMessage ?? this.statusMessage,
      status: status ?? this.status,
      lastSeen: lastSeen ?? this.lastSeen,
      isOnline: isOnline ?? this.isOnline,
      isVerified: isVerified ?? this.isVerified,
      isBlocked: isBlocked ?? this.isBlocked,
      blockingMe: blockingMe ?? this.blockingMe,
      isFavorite: isFavorite ?? this.isFavorite,
      mutualFriends: mutualFriends ?? this.mutualFriends,
      privacy: privacy ?? this.privacy,
    );
  }
}

enum UserStatus { online, away, busy, dnd, offline }

class UserPrivacy {
  final bool showLastSeen;
  final bool showProfilePicture;
  final bool showOnlineStatus;
  final bool allowScreenshots;
  final bool allowForwarding;
  final bool allowCalls;
  final bool allowGroupInvites;

  const UserPrivacy({
    this.showLastSeen = true,
    this.showProfilePicture = true,
    this.showOnlineStatus = true,
    this.allowScreenshots = false,
    this.allowForwarding = true,
    this.allowCalls = true,
    this.allowGroupInvites = true,
  });
}
