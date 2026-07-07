// ------------------------------------------------------------------
// Fichier : models/forum_topic.dart
// Rôle : Sujet de forum associé à une formation. Les utilisateurs
// peuvent ouvrir des sujets pour poser des questions ou discuter.
// ------------------------------------------------------------------

class ForumTopic {
  final String id;
  final String formationId;
  final String userId;
  final String title;
  final String body;
  final String status; // 'open', 'closed'
  final DateTime createdAt;
  final DateTime updatedAt;

  // Relations
  List<ForumReply>? replies;
  String? authorName; // affichage

  ForumTopic({
    required this.id,
    required this.formationId,
    required this.userId,
    required this.title,
    required this.body,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.replies,
    this.authorName,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'formation_id': formationId,
        'user_id': userId,
        'title': title,
        'body': body,
        'status': status,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory ForumTopic.fromJson(Map<String, dynamic> json) => ForumTopic(
        id: json['id'],
        formationId: json['formation_id'],
        userId: json['user_id'],
        title: json['title'],
        body: json['body'],
        status: json['status'],
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: DateTime.parse(json['updated_at']),
      );

  ForumTopic copyWith({
    String? status,
    List<ForumReply>? replies,
  }) =>
      ForumTopic(
        id: id,
        formationId: formationId,
        userId: userId,
        title: title,
        body: body,
        status: status ?? this.status,
        createdAt: createdAt,
        updatedAt: updatedAt,
        replies: replies ?? this.replies,
        authorName: authorName,
      );
}
