// lib/models/chat/chat_message.dart - FIX 3465 SENTIMENT CLASS
import 'sentiment.dart'; 

class MessageReaction {
  final String reaction;
  final String userId;
  const MessageReaction({required this.reaction, required this.userId});
  factory MessageReaction.fromJson(Map<String, dynamic> json) {
    return MessageReaction(reaction: (json['reaction'] ?? '').toString(), userId: (json['user_id'] ?? '').toString());
  }
  Map<String, dynamic> toJson() => {'reaction': reaction, 'user_id': userId};
}

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;  
  final String? senderAvatar;  
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? mediaUrl;
  final String? mediaType;
  final String? mediaName;
  final int? mediaSize;
  final String? mimeType;
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
  final bool isInternalNote; 
  final SentimentResult? sentiment; 

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,  
    this.senderAvatar,  
    required this.content,
    required this.createdAt,
    this.updatedAt,
    this.mediaUrl,
    this.mediaType,
    this.mediaName,
    this.mediaSize,
    this.mimeType,
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
    this.isInternalNote = false, 
    this.sentiment, 
  });

  static DateTime? _parseDate(dynamic v) {
    if(v==null) return null;
    if(v is DateTime) return v;
    if(v is String && v.isNotEmpty) return DateTime.tryParse(v);
    return null;
  }

  // FIX 3465: SentimentResult est une CLASS pas un ENUM
  static SentimentResult? _parseSentiment(dynamic value) {
    if(value==null) return null;
    if(value is SentimentResult) return value;
    if(value is Map<String,dynamic>) {
      try { return SentimentResult.fromJson(value); } catch(_) { return null; }
    }
    if(value is String) {
      try { return SentimentResult.fromJson({'label': value}); } catch(_) { return null; }
    }
    return null;
  }

  static List<MessageReaction> _parseReactions(dynamic value) {
    if(value==null || value is! List) return [];
    return value.whereType<Map<String,dynamic>>().map((e){ try{ return MessageReaction.fromJson(e); }catch(_){ return null; } }).whereType<MessageReaction>().toList();
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>? ?? json['sender'] as Map<String, dynamic>?;
    return ChatMessage(
      id: (json['id'] ?? '').toString(),
      conversationId: (json['conversation_id'] ?? '').toString(),
      senderId: (json['sender_id'] ?? '').toString(),
      senderName: (profile?['display_name'] ?? profile?['full_name'] ?? profile?['username'] ?? 'Utilisateur inconnu').toString(),  
      senderAvatar: (profile?['avatar_url'])?.toString(),  
      content: (json['content'] ?? '').toString(),
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updated_at']),
      mediaUrl: (json['media_url'] ?? json['file_url'] ?? json['attachment_url'] ?? json['url'])?.toString(),
      mediaType: (json['media_type'] ?? json['type'])?.toString(),
      mediaName: (json['media_name'] ?? json['file_name'] ?? json['name'])?.toString(),
      mediaSize: json['media_size'] is int ? json['media_size'] : int.tryParse('${json['media_size']?? json['file_size']??''}'),
      mimeType: (json['mime_type'])?.toString(),
      isRead: json['is_read'] == true,
      isDelivered: json['is_delivered'] == true,
      replyToId: (json['reply_to_id'])?.toString(),
      isDeleted: json['is_deleted'] == true,
      isEphemeral: json['is_ephemeral'] == true,
      ephemeralDuration: json['ephemeral_duration'] is int ? json['ephemeral_duration'] : int.tryParse('${json['ephemeral_duration']??''}'),
      deleteAt: _parseDate(json['delete_at']),
      isCodeSnippet: json['is_code_snippet'] == true,
      codeLanguage: json['code_language']?.toString(),
      codeContent: json['code_content']?.toString(),
      reactions: _parseReactions(json['reactions']),
      isInternalNote: json['is_internal_note'] == true, 
      sentiment: _parseSentiment(json['sentiment']),
    );
  }

  Map<String, dynamic> toJson() {
    dynamic sentimentJson;
    if(sentiment != null) {
      try {
        // Si ta classe a toJson, on l'utilise
        sentimentJson = (sentiment as dynamic).toJson();
      } catch(_) {
        sentimentJson = sentiment.toString();
      }
    }
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'media_url': mediaUrl,
      'media_type': mediaType,
      'media_name': mediaName,
      'media_size': mediaSize,
      'mime_type': mimeType,
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
      'is_internal_note': isInternalNote, 
      'sentiment': sentimentJson, 
    };
  }

  ChatMessage copyWith({
    String? id, String? conversationId, String? senderId, String? senderName, String? senderAvatar, String? content,
    DateTime? createdAt, DateTime? updatedAt, String? mediaUrl, String? mediaType, String? mediaName, int? mediaSize, String? mimeType,
    bool? isRead, bool? isDelivered, String? replyToId, bool? isDeleted, bool? isEphemeral, int? ephemeralDuration, DateTime? deleteAt,
    bool? isCodeSnippet, String? codeLanguage, String? codeContent, List<MessageReaction>? reactions, bool? isInternalNote, SentimentResult? sentiment, bool clearSentiment = false, bool clearMedia = false,
  }) {
    return ChatMessage(
      id: id ?? this.id, conversationId: conversationId ?? this.conversationId, senderId: senderId ?? this.senderId, senderName: senderName ?? this.senderName, senderAvatar: senderAvatar ?? this.senderAvatar, content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt,
      mediaUrl: clearMedia? null : mediaUrl ?? this.mediaUrl, mediaType: clearMedia? null : mediaType ?? this.mediaType, mediaName: clearMedia? null : mediaName ?? this.mediaName, mediaSize: clearMedia? null : mediaSize ?? this.mediaSize, mimeType: clearMedia? null : mimeType ?? this.mimeType,
      isRead: isRead ?? this.isRead, isDelivered: isDelivered ?? this.isDelivered, replyToId: replyToId ?? this.replyToId, isDeleted: isDeleted ?? this.isDeleted, isEphemeral: isEphemeral ?? this.isEphemeral, ephemeralDuration: ephemeralDuration ?? this.ephemeralDuration, deleteAt: deleteAt ?? this.deleteAt,
      isCodeSnippet: isCodeSnippet ?? this.isCodeSnippet, codeLanguage: codeLanguage ?? this.codeLanguage, codeContent: codeContent ?? this.codeContent,
      reactions: reactions ?? this.reactions, isInternalNote: isInternalNote ?? this.isInternalNote, sentiment: clearSentiment? null : sentiment ?? this.sentiment,
    );
  }

  bool get isActive => !isDeleted && (deleteAt == null || deleteAt!.isAfter(DateTime.now()));
}
