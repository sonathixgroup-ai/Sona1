import 'package:thix_id/features/thix_sante/domain/models/appointment_model.dart';

abstract class AppointmentRepository {
  Stream<List<AppointmentModel>> watchAppointments({required String patientId});
  Future<List<AppointmentModel>> fetchAppointments({required String patientId, int limit = 50, int offset = 0});
  Future<AppointmentModel> createAppointment(AppointmentModel appointment);
  Future<AppointmentModel> updateAppointment(AppointmentModel appointment);
  Future<void> deleteAppointment({required String id});
}
