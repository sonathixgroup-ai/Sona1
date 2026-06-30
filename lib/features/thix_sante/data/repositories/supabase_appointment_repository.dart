import 'package:thix_id/features/thix_sante/core/thix_sante_exceptions.dart';
import 'package:thix_id/features/thix_sante/core/thix_sante_tables.dart';
import 'package:thix_id/features/thix_sante/domain/models/appointment_model.dart';
import 'package:thix_id/features/thix_sante/domain/repositories/appointment_repository.dart';
import 'package:thix_id/supabase/supabase_client.dart';

class SupabaseAppointmentRepository implements AppointmentRepository {
  @override
  Stream<List<AppointmentModel>> watchAppointments({required String patientId}) {
    final uid = requireUserId();
    try {
      return supabase
          .from(ThixSanteTables.appointments)
          .stream(primaryKey: const ['id'])
          .order('scheduled_at')
          .map((rows) => rows
              .where((e) => e['user_id'] == uid && e['patient_id'] == patientId)
              .map((e) => AppointmentModel.fromJson(Map<String, dynamic>.from(e)))
              .toList(growable: false));
    } catch (e) {
      // Stream creation can throw synchronously if misconfigured.
      throw mapSupabaseError(e, context: 'watchAppointments');
    }
  }

  @override
  Future<List<AppointmentModel>> fetchAppointments({required String patientId, int limit = 50, int offset = 0}) async {
    final uid = requireUserId();
    try {
      final res = await supabase
          .from(ThixSanteTables.appointments)
          .select('*')
          .eq('user_id', uid)
          .eq('patient_id', patientId)
          .order('scheduled_at')
          .range(offset, offset + limit - 1);

      return (res as List)
          .map((e) => AppointmentModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(growable: false);
    } catch (e) {
      throw mapSupabaseError(e, context: 'fetchAppointments');
    }
  }

  @override
  Future<AppointmentModel> createAppointment(AppointmentModel appointment) async {
    final uid = requireUserId();
    try {
      final payload = appointment.copyWith(userId: uid).toJson();
      final res = await supabase
          .from(ThixSanteTables.appointments)
          .insert(payload)
          .select('*')
          .single();

      return AppointmentModel.fromJson(Map<String, dynamic>.from(res));
    } catch (e) {
      throw mapSupabaseError(e, context: 'createAppointment');
    }
  }

  @override
  Future<AppointmentModel> updateAppointment(AppointmentModel appointment) async {
    final uid = requireUserId();
    try {
      final payload = appointment.copyWith(userId: uid).toJson();
      final res = await supabase
          .from(ThixSanteTables.appointments)
          .update(payload)
          .eq('id', appointment.id)
          .eq('user_id', uid)
          .select('*')
          .single();

      return AppointmentModel.fromJson(Map<String, dynamic>.from(res));
    } catch (e) {
      throw mapSupabaseError(e, context: 'updateAppointment');
    }
  }

  @override
  Future<void> deleteAppointment({required String id}) async {
    final uid = requireUserId();
    try {
      await supabase
          .from(ThixSanteTables.appointments)
          .delete()
          .eq('id', id)
          .eq('user_id', uid);
    } catch (e) {
      throw mapSupabaseError(e, context: 'deleteAppointment');
    }
  }
}
