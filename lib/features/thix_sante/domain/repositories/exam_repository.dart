import 'package:thix_id/features/thix_sante/domain/models/exam_model.dart';

abstract class ExamRepository {
  Stream<List<ExamModel>> watchExams({required String patientId});
  Future<List<ExamModel>> fetchExams({required String patientId, int limit = 50, int offset = 0});
}
