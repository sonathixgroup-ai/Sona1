import 'package:thix_id/features/thix_sante/core/thix_sante_exceptions.dart';
import 'package:thix_id/features/thix_sante/core/thix_sante_tables.dart';
import 'package:thix_id/features/thix_sante/domain/models/notification_model.dart';
import 'package:thix_id/features/thix_sante/domain/repositories/notification_repository.dart';
import 'package:thix_id/supabase/supabase_client.dart';

class SupabaseNotificationRepository implements NotificationRepository {
  @override
  Stream<List<NotificationModel>> watchNotifications({required String patientId}) {
    final uid = requireUserId();
    try {
      return supabase
          .from(ThixSanteTables.notifications)
          .stream(primaryKey: const ['id'])
          .order('created_at', ascending: false)
          .map((rows) => rows
              .where((e) => e['user_id'] == uid && e['patient_id'] == patientId)
              .map((e) => NotificationModel.fromJson(Map<String, dynamic>.from(e)))
              .toList(growable: false));
    } catch (e) {
      throw mapSupabaseError(e, context: 'watchNotifications');
    }
  }

  @override
  Future<List<NotificationModel>> fetchNotifications({required String patientId, int limit = 50, int offset = 0}) async {
    final uid = requireUserId();
    try {
      final res = await supabase
          .from(ThixSanteTables.notifications)
          .select('*')
          .eq('user_id', uid)
          .eq('patient_id', patientId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (res as List)
          .map((e) => NotificationModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(growable: false);
    } catch (e) {
      throw mapSupabaseError(e, context: 'fetchNotifications');
    }
  }

  @override
  Future<void> markRead({required String id, required bool isRead}) async {
    final uid = requireUserId();
    try {
      await supabase
          .from(ThixSanteTables.notifications)
          .update({'is_read': isRead, 'updated_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', id)
          .eq('user_id', uid);
    } catch (e) {
      throw mapSupabaseError(e, context: 'markRead');
    }
  }

  @override
  Future<void> deleteNotification({required String id}) async {
    final uid = requireUserId();
    try {
      await supabase
          .from(ThixSanteTables.notifications)
          .delete()
          .eq('id', id)
          .eq('user_id', uid);
    } catch (e) {
      throw mapSupabaseError(e, context: 'deleteNotification');
    }
  }
}
