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

  // ✅ Noms des tables Supabase – corrigés pour correspondre aux migrations
  static const String tableMessages = 'thix_chat_messages';
  static const String tableConversations = 'thix_chat_chats';
  static const String tableParticipants = 'thix_chat_participants';
  static const String tableReadReceipts = 'thix_chat_reads';
  static const String tableEphemeralMessages = 'thix_chat_ephemeral';
  static const String tableConfidentialMessages = 'thix_chat_confidential';
  static const String tablePolls = 'thix_chat_polls';
  static const String tablePollVotes = 'thix_chat_poll_votes';
  static const String tableScheduledMessages = 'thix_chat_scheduled';
  static const String tableMessageReactions = 'thix_chat_reactions';
  static const String tableDeletedMessages = 'thix_chat_deletions';

  // Clés pour les métadonnées
  static const String metadataKeyDuration = 'duration';
  static const String metadataKeyCodeHash = 'code_hash';
  static const String metadataKeyIsBiometric = 'is_biometric';
}
