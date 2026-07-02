// lib/presentation/chat/core/chat_constants.dart
// [PARTIE] Constantes globales du chat

class ChatConstants {
  // Limites des messages
  static const int maxMessageLength = 5000;
  static const int maxCaptionLength = 1000;
  static const int maxRecentConversations = 20;

  // Durées par défaut (secondes)
  static const int ephemeralDefaultSeconds = 30;
  static const int ephemeralMaxSeconds = 86400; // 24h
  static const int typingTimeoutSeconds = 3;

  // Tailles maximales des fichiers (Mo)
  static const int maxImageSizeMB = 10;
  static const int maxVideoSizeMB = 50;
  static const int maxFileSizeMB = 100;

  // Réactions prédéfinies
  static const List<String> defaultReactions = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

  // Statuts de présence
  static const String statusOnline = 'online';
  static const String statusOffline = 'offline';
  static const String statusAway = 'away';

  // Types de messages
  static const String messageTypeText = 'text';
  static const String messageTypeImage = 'image';
  static const String messageTypeVideo = 'video';
  static const String messageTypeAudio = 'audio';
  static const String messageTypeFile = 'file';
  static const String messageTypePoll = 'poll';
  static const String messageTypeEphemeral = 'ephemeral';
  static const String messageTypeConfidential = 'confidential';
  static const String messageTypeVoice = 'voice';
  static const String messageTypeContact = 'contact';

  // Noms des tables Supabase
  static const String tableMessages = 'messages';
  static const String tableConversations = 'conversations';
  static const String tableParticipants = 'participants';
  static const String tableReadReceipts = 'read_receipts';
  static const String tableEphemeralMessages = 'ephemeral_messages';
  static const String tableConfidentialMessages = 'confidential_messages';
  static const String tablePolls = 'polls';
  static const String tablePollVotes = 'poll_votes';
  static const String tableScheduledMessages = 'scheduled_messages';
  static const String tableMessageReactions = 'message_reactions';
  static const String tableDeletedMessages = 'deleted_messages_for_user';

  // Clés pour les métadonnées
  static const String metadataKeyDuration = 'duration';
  static const String metadataKeyCodeHash = 'code_hash';
  static const String metadataKeyIsBiometric = 'is_biometric';
}
