import 'package:equatable/equatable.dart';
import 'package:thix_id/features/thix_sante/domain/models/thix_datetime.dart';

class NotificationModel extends Equatable {
  final String id;
  final String userId;
  final String patientId;
  final String title;
  final String body;
  final bool isRead;
  final String? deepLink;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.patientId,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    required this.updatedAt,
    this.deepLink,
  });

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? patientId,
    String? title,
    String? body,
    bool? isRead,
    String? deepLink,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      patientId: patientId ?? this.patientId,
      title: title ?? this.title,
      body: body ?? this.body,
      isRead: isRead ?? this.isRead,
      deepLink: deepLink ?? this.deepLink,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: (json['id'] ?? '') as String,
      userId: (json['user_id'] ?? '') as String,
      patientId: (json['patient_id'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      body: (json['body'] ?? '') as String,
      isRead: (json['is_read'] ?? false) as bool,
      deepLink: json['deep_link'] as String?,
      createdAt: parseDateTime(json['created_at']) ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      updatedAt: parseDateTime(json['updated_at']) ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'patient_id': patientId,
      'title': title,
      'body': body,
      'is_read': isRead,
      'deep_link': deepLink,
      'created_at': toIsoString(createdAt),
      'updated_at': toIsoString(updatedAt),
    };
  }

  @override
  List<Object?> get props => [id, userId, patientId, title, body, isRead, deepLink, createdAt, updatedAt];
}
