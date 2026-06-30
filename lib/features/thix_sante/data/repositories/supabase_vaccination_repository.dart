import 'package:thix_id/features/thix_sante/core/thix_sante_exceptions.dart';
import 'package:thix_id/features/thix_sante/core/thix_sante_tables.dart';
import 'package:thix_id/features/thix_sante/domain/models/vaccination_model.dart';
import 'package:thix_id/features/thix_sante/domain/repositories/vaccination_repository.dart';
import 'package:thix_id/supabase/supabase_client.dart';

class SupabaseVaccinationRepository implements VaccinationRepository {
  @override
  Stream<List<VaccinationModel>> watchVaccinations({required String patientId}) {
    final uid = requireUserId();
    try {
      return supabase
          .from(ThixSanteTables.vaccinations)
          .stream(primaryKey: const ['id'])
          .order('administered_at', ascending: false)
          .map((rows) => rows
              .where((e) => e['user_id'] == uid && e['patient_id'] == patientId)
              .map((e) => VaccinationModel.fromJson(Map<String, dynamic>.from(e)))
              .toList(growable: false));
    } catch (e) {
      throw mapSupabaseError(e, context: 'watchVaccinations');
    }
  }

  @override
  Future<List<VaccinationModel>> fetchVaccinations({required String patientId, int limit = 50, int offset = 0}) async {
    final uid = requireUserId();
    try {
      final res = await supabase
          .from(ThixSanteTables.vaccinations)
          .select('*')
          .eq('user_id', uid)
          .eq('patient_id', patientId)
          .order('administered_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (res as List)
          .map((e) => VaccinationModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(growable: false);
    } catch (e) {
      throw mapSupabaseError(e, context: 'fetchVaccinations');
    }
  }
}
