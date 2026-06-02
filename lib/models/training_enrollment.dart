import 'dart:convert';

/// Represents a user's enrollment in a training course.
class TrainingEnrollment {
  final String id;
  final String userId;
  final String trainingId;
  final String status; // active | completed | cancelled
  final double progressPercent; // 0-100
  final int learningMinutes;
  final DateTime enrolledAt;
  final DateTime? completedAt;
  final DateTime lastActivityAt;
  final DateTime updatedAt;

  const TrainingEnrollment({
    required this.id,
    required this.userId,
    required this.trainingId,
    required this.status,
    required this.progressPercent,
    required this.learningMinutes,
    required this.enrolledAt,
    required this.completedAt,
    required this.lastActivityAt,
    required this.updatedAt,
  });

  factory TrainingEnrollment.fromJson(Map<String, dynamic> json) {
    return TrainingEnrollment(
      id: (json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      trainingId: (json['training_id'] ?? '').toString(),
      status: (json['status'] ?? 'active').toString(),
      progressPercent: ((json['progress_percent'] as num?)?.toDouble() ?? 0.0).clamp(0.0, 100.0),
      learningMinutes: (json['learning_minutes'] as num?)?.toInt() ?? 0,
      enrolledAt: DateTime.tryParse((json['enrolled_at'] ?? '').toString()) ?? DateTime.now(),
      completedAt: DateTime.tryParse((json['completed_at'] ?? '').toString()),
      lastActivityAt: DateTime.tryParse((json['last_activity_at'] ?? '').toString()) ?? DateTime.now(),
      updatedAt: DateTime.tryParse((json['updated_at'] ?? '').toString()) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'training_id': trainingId,
      'status': status,
      'progress_percent': progressPercent,
      'learning_minutes': learningMinutes,
      'enrolled_at': enrolledAt.toUtc().toIso8601String(),
      'completed_at': completedAt?.toUtc().toIso8601String(),
      'last_activity_at': lastActivityAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }
}
