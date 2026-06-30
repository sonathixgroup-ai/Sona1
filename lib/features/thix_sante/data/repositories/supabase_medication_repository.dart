import 'package:thix_id/features/thix_sante/core/thix_sante_exceptions.dart';
import 'package:thix_id/features/thix_sante/core/thix_sante_tables.dart';
import 'package:thix_id/features/thix_sante/domain/models/medication_model.dart';
import 'package:thix_id/features/thix_sante/domain/repositories/medication_repository.dart';
import 'package:thix_id/supabase/supabase_client.dart';

class SupabaseMedicationRepository implements MedicationRepository {
  @override
  Stream<List<MedicationModel>> watchMedications({required String patientId, bool activeOnly = false}) {
    final uid = requireUserId();
    try {
      return supabase
          .from(ThixSanteTables.medications)
          .stream(primaryKey: const ['id'])
          .order('created_at', ascending: false)
          .map((rows) => rows
              .where((e) {
                if (e['user_id'] != uid || e['patient_id'] != patientId) return false;
                if (activeOnly == true && e['is_active'] != true) return false;
                return true;
              })
              .map((e) => MedicationModel.fromJson(Map<String, dynamic>.from(e)))
              .toList(growable: false));
    } catch (e) {
      throw mapSupabaseError(e, context: 'watchMedications');
    }
  }

  @override
  Future<List<MedicationModel>> fetchMedications({required String patientId, bool activeOnly = false, int limit = 50, int offset = 0}) async {
    final uid = requireUserId();
    try {
      dynamic q = supabase
          .from(ThixSanteTables.medications)
          .select('*')
          .eq('user_id', uid)
          .eq('patient_id', patientId);

      if (activeOnly) q = q.eq('is_active', true);

      final res = await q
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (res as List)
          .map((e) => MedicationModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(growable: false);
    } catch (e) {
      throw mapSupabaseError(e, context: 'fetchMedications');
    }
  }
}
