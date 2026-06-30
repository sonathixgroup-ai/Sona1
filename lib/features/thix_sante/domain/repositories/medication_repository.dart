import 'package:thix_id/features/thix_sante/domain/models/medication_model.dart';

abstract class MedicationRepository {
  Stream<List<MedicationModel>> watchMedications({required String patientId, bool activeOnly = false});
  Future<List<MedicationModel>> fetchMedications({required String patientId, bool activeOnly = false, int limit = 50, int offset = 0});
}
