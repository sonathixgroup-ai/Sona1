/// Chat constants and configuration
class ChatConstants {
  // Message limits
  static const int maxMessageLength = 4096;
  static const int maxFileSize = 50 * 1024 * 1024;
  static const int maxGroupMembers = 500;
  static const int maxPinnedMessages = 5;
  static const int maxMediaAttachments = 10;

  // Timeouts and durations
  static const Duration messageEditTimeout = Duration(minutes: 15);
  static const Duration typingIndicatorTimeout = Duration(seconds: 3);
  static const Duration presenceUpdateInterval = Duration(seconds: 30);
  static const Duration messageReadReceiptDelay = Duration(milliseconds: 500);

  // Default values
  static const String defaultGroupName = 'Nouvelle Conversation';

  // Emojis for reactions
  static const List<String> defaultReactions = ['❤️', '👍', '😂', '😮', '😢', '😡'];
}
