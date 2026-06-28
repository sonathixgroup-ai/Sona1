/// Message model for THIX CHAT
class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String content;
  final MessageType type;
  final MessageStatus status;
  final DateTime timestamp;
  final DateTime? editedAt;
  final bool isEdited;
  final bool isPinned;
  final bool isEncrypted;
  final bool isSelfDestructing;
  final Duration? selfDestructDuration;
  final String? replyToId;
  final List<String> reactionEmojis;
  final Map<String, int> reactionCounts;
  final List<MediaAttachment> attachments;
  final String? threadId;
  final bool isForwarded;
  final String? forwardedFromId;
  final List<String> mentionedUserIds;
  final bool isHighPriority;
  final String? secretCode;
  final bool isRecall;

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.content,
    this.type = MessageType.text,
    this.status = MessageStatus.sent,
    required this.timestamp,
    this.editedAt,
    this.isEdited = false,
    this.isPinned = false,
    this.isEncrypted = false,
    this.isSelfDestructing = false,
    this.selfDestructDuration,
    this.replyToId,
    this.reactionEmojis = const [],
    this.reactionCounts = const {},
    this.attachments = const [],
    this.threadId,
    this.isForwarded = false,
    this.forwardedFromId,
    this.mentionedUserIds = const [],
    this.isHighPriority = false,
    this.secretCode,
    this.isRecall = false,
  });

  Message copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    String? content,
    MessageType? type,
    MessageStatus? status,
    DateTime? timestamp,
    DateTime? editedAt,
    bool? isEdited,
    bool? isPinned,
    bool? isEncrypted,
    bool? isSelfDestructing,
    Duration? selfDestructDuration,
    String? replyToId,
    List<String>? reactionEmojis,
    Map<String, int>? reactionCounts,
    List<MediaAttachment>? attachments,
    String? threadId,
    bool? isForwarded,
    String? forwardedFromId,
    List<String>? mentionedUserIds,
    bool? isHighPriority,
    String? secretCode,
    bool? isRecall,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      content: content ?? this.content,
      type: type ?? this.type,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      editedAt: editedAt ?? this.editedAt,
      isEdited: isEdited ?? this.isEdited,
      isPinned: isPinned ?? this.isPinned,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      isSelfDestructing: isSelfDestructing ?? this.isSelfDestructing,
      selfDestructDuration: selfDestructDuration ?? this.selfDestructDuration,
      replyToId: replyToId ?? this.replyToId,
      reactionEmojis: reactionEmojis ?? this.reactionEmojis,
      reactionCounts: reactionCounts ?? this.reactionCounts,
      attachments: attachments ?? this.attachments,
      threadId: threadId ?? this.threadId,
      isForwarded: isForwarded ?? this.isForwarded,
      forwardedFromId: forwardedFromId ?? this.forwardedFromId,
      mentionedUserIds: mentionedUserIds ?? this.mentionedUserIds,
      isHighPriority: isHighPriority ?? this.isHighPriority,
      secretCode: secretCode ?? this.secretCode,
      isRecall: isRecall ?? this.isRecall,
    );
  }
}

enum MessageType {
  text,
  image,
  video,
  audio,
  file,
  gif,
  sticker,
  emoji,
  voiceTranscription,
  location,
  contact,
  poll,
  game,
  system
}

enum MessageStatus { sending, sent, delivered, read, failed, edited, recalled }

class MediaAttachment {
  final String id;
  final String url;
  final String fileName;
  final String mimeType;
  final int sizeBytes;
  final int? width;
  final int? height;
  final Duration? duration;
  final String? thumbnailUrl;
  final bool isUploading;
  final double uploadProgress;

  const MediaAttachment({
    required this.id,
    required this.url,
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
    this.width,
    this.height,
    this.duration,
    this.thumbnailUrl,
    this.isUploading = false,
    this.uploadProgress = 0.0,
  });
}
