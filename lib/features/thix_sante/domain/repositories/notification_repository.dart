import 'package:thix_id/features/thix_sante/domain/models/notification_model.dart';

abstract class NotificationRepository {
  Stream<List<NotificationModel>> watchNotifications({required String patientId});
  Future<List<NotificationModel>> fetchNotifications({required String patientId, int limit = 50, int offset = 0});
  Future<void> markRead({required String id, required bool isRead});
  Future<void> deleteNotification({required String id});
}
