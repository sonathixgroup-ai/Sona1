import 'package:thix_id/features/thix_sante/core/thix_sante_exceptions.dart';
import 'package:thix_id/features/thix_sante/core/thix_sante_tables.dart';
import 'package:thix_id/features/thix_sante/domain/models/exam_model.dart';
import 'package:thix_id/features/thix_sante/domain/repositories/exam_repository.dart';
import 'package:thix_id/supabase/supabase_client.dart';

class SupabaseExamRepository implements ExamRepository {
  @override
  Stream<List<ExamModel>> watchExams({required String patientId}) {
    final uid = requireUserId();
    try {
      return supabase
          .from(ThixSanteTables.exams)
          .stream(primaryKey: const ['id'])
          .order('occurred_at', ascending: false)
          .map((rows) => rows
              .where((e) => e['user_id'] == uid && e['patient_id'] == patientId)
              .map((e) => ExamModel.fromJson(Map<String, dynamic>.from(e)))
              .toList(growable: false));
    } catch (e) {
      throw mapSupabaseError(e, context: 'watchExams');
    }
  }

  @override
  Future<List<ExamModel>> fetchExams({required String patientId, int limit = 50, int offset = 0}) async {
    final uid = requireUserId();
    try {
      final res = await supabase
          .from(ThixSanteTables.exams)
          .select('*')
          .eq('user_id', uid)
          .eq('patient_id', patientId)
          .order('occurred_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (res as List)
          .map((e) => ExamModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(growable: false);
    } catch (e) {
      throw mapSupabaseError(e, context: 'fetchExams');
    }
  }
}
