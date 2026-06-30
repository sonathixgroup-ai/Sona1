import 'package:thix_id/features/thix_sante/domain/models/vaccination_model.dart';

abstract class VaccinationRepository {
  Stream<List<VaccinationModel>> watchVaccinations({required String patientId});
  Future<List<VaccinationModel>> fetchVaccinations({required String patientId, int limit = 50, int offset = 0});
}
