// ------------------------------------------------------------------
// Fichier : models/forum_reply.dart
// Rôle : Réponse à un sujet de forum.
// ------------------------------------------------------------------

class ForumReply {
  final String id;
  final String topicId;
  final String userId;
  final String body;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Relations
  String? authorName; // affichage

  ForumReply({
    required this.id,
    required this.topicId,
    required this.userId,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
    this.authorName,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'topic_id': topicId,
        'user_id': userId,
        'body': body,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory ForumReply.fromJson(Map<String, dynamic> json) => ForumReply(
        id: json['id'],
        topicId: json['topic_id'],
        userId: json['user_id'],
        body: json['body'],
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: DateTime.parse(json['updated_at']),
      );

  ForumReply copyWith({
    String? body,
  }) =>
      ForumReply(
        id: id,
        topicId: topicId,
        userId: userId,
        body: body ?? this.body,
        createdAt: createdAt,
        updatedAt: updatedAt,
        authorName: authorName,
      );
}
