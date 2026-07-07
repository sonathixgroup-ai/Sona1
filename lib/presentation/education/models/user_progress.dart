// ------------------------------------------------------------------
// Fichier : models/user_progress.dart
// Rôle : Progression d'un utilisateur pour chaque leçon d'une formation.
// Permet de suivre le détail de l'avancement.
// ------------------------------------------------------------------

class UserProgress {
  final String id;
  final String userId;
  final String lessonId;
  final String status; // 'not_started', 'in_progress', 'completed'
  final double progress; // 0.0 à 1.0 (pourcentage de la leçon)
  final DateTime lastAccessedAt;
  final DateTime? completedAt;

  // Relations
  Lesson? lesson;

  UserProgress({
    required this.id,
    required this.userId,
    required this.lessonId,
    required this.status,
    required this.progress,
    required this.lastAccessedAt,
    this.completedAt,
    this.lesson,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'lesson_id': lessonId,
        'status': status,
        'progress': progress,
        'last_accessed_at': lastAccessedAt.toIso8601String(),
        'completed_at': completedAt?.toIso8601String(),
      };

  factory UserProgress.fromJson(Map<String, dynamic> json) => UserProgress(
        id: json['id'],
        userId: json['user_id'],
        lessonId: json['lesson_id'],
        status: json['status'],
        progress: (json['progress'] as num).toDouble(),
        lastAccessedAt: DateTime.parse(json['last_accessed_at']),
        completedAt: json['completed_at'] != null
            ? DateTime.parse(json['completed_at'])
            : null,
      );

  UserProgress copyWith({
    String? status,
    double? progress,
    DateTime? lastAccessedAt,
    DateTime? completedAt,
    Lesson? lesson,
  }) =>
      UserProgress(
        id: id,
        userId: userId,
        lessonId: lessonId,
        status: status ?? this.status,
        progress: progress ?? this.progress,
        lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
        completedAt: completedAt ?? this.completedAt,
        lesson: lesson ?? this.lesson,
      );
}
