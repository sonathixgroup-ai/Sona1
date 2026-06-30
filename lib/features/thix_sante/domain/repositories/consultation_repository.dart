import 'package:thix_id/features/thix_sante/domain/models/consultation_model.dart';

abstract class ConsultationRepository {
  Stream<List<ConsultationModel>> watchConsultations({required String patientId});
  Future<List<ConsultationModel>> fetchConsultations({required String patientId, int limit = 50, int offset = 0});
}
