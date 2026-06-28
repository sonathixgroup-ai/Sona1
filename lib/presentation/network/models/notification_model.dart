// lib/presentation/network/models/notification_model.dart

class NotificationModel {
  final String id;
  final String? userId;
  final String? actorId;
  final String? type;
  final Map<String, dynamic>? data;
  final bool read;
  final DateTime createdAt;

  NotificationModel({required this.id, this.userId, this.actorId, this.type, this.data, required this.read, required this.createdAt});

  factory NotificationModel.fromMap(Map<String, dynamic> m) => NotificationModel(
        id: m['id'] as String? ?? '',
        userId: m['user_id'] as String?,
        actorId: m['actor_id'] as String?,
        type: m['type'] as String?,
        data: m['data'] as Map<String, dynamic>?,
        read: (m['read'] as bool?) ?? false,
        createdAt: DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
      );
}
