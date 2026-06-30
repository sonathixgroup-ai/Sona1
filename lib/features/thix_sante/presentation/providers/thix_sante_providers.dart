import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/features/thix_sante/data/repositories/supabase_appointment_repository.dart';
import 'package:thix_id/features/thix_sante/data/repositories/supabase_article_repository.dart';
import 'package:thix_id/features/thix_sante/data/repositories/supabase_consultation_repository.dart';
import 'package:thix_id/features/thix_sante/data/repositories/supabase_exam_repository.dart';
import 'package:thix_id/features/thix_sante/data/repositories/supabase_medication_repository.dart';
import 'package:thix_id/features/thix_sante/data/repositories/supabase_notification_repository.dart';
import 'package:thix_id/features/thix_sante/data/repositories/supabase_profile_repository.dart';
import 'package:thix_id/features/thix_sante/data/repositories/supabase_vaccination_repository.dart';
import 'package:thix_id/features/thix_sante/domain/models/appointment_model.dart';
import 'package:thix_id/features/thix_sante/domain/models/article_model.dart';
import 'package:thix_id/features/thix_sante/domain/models/consultation_model.dart';
import 'package:thix_id/features/thix_sante/domain/models/exam_model.dart';
import 'package:thix_id/features/thix_sante/domain/models/medication_model.dart';
import 'package:thix_id/features/thix_sante/domain/models/notification_model.dart';
import 'package:thix_id/features/thix_sante/domain/models/profile_model.dart';
import 'package:thix_id/features/thix_sante/domain/models/vaccination_model.dart';
import 'package:thix_id/features/thix_sante/domain/repositories/appointment_repository.dart';
import 'package:thix_id/features/thix_sante/domain/repositories/article_repository.dart';
import 'package:thix_id/features/thix_sante/domain/repositories/consultation_repository.dart';
import 'package:thix_id/features/thix_sante/domain/repositories/exam_repository.dart';
import 'package:thix_id/features/thix_sante/domain/repositories/medication_repository.dart';
import 'package:thix_id/features/thix_sante/domain/repositories/notification_repository.dart';
import 'package:thix_id/features/thix_sante/domain/repositories/profile_repository.dart';
import 'package:thix_id/features/thix_sante/domain/repositories/vaccination_repository.dart';
import 'package:thix_id/supabase/supabase_client.dart';

/// Auth provider (required): always uses `Supabase.instance.client`.
final authProvider = StreamProvider<AuthState>((ref) => supabase.auth.onAuthStateChange);

final profileRepositoryProvider = Provider<ProfileRepository>((ref) => SupabaseProfileRepository());
final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) => SupabaseAppointmentRepository());
final consultationRepositoryProvider = Provider<ConsultationRepository>((ref) => SupabaseConsultationRepository());
final examRepositoryProvider = Provider<ExamRepository>((ref) => SupabaseExamRepository());
final medicationRepositoryProvider = Provider<MedicationRepository>((ref) => SupabaseMedicationRepository());
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) => SupabaseNotificationRepository());
final vaccinationRepositoryProvider = Provider<VaccinationRepository>((ref) => SupabaseVaccinationRepository());
final articleRepositoryProvider = Provider<ArticleRepository>((ref) => SupabaseArticleRepository());

final profileProvider = FutureProvider<ProfileModel?>((ref) async {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.fetchMyProfile();
});

final appointmentsProvider = StreamProvider.family<List<AppointmentModel>, String>((ref, patientId) {
  final repo = ref.watch(appointmentRepositoryProvider);
  return repo.watchAppointments(patientId: patientId);
});

final consultationsProvider = StreamProvider.family<List<ConsultationModel>, String>((ref, patientId) {
  final repo = ref.watch(consultationRepositoryProvider);
  return repo.watchConsultations(patientId: patientId);
});

final medicationsProvider = StreamProvider.family<List<MedicationModel>, ({String patientId, bool activeOnly})>((ref, args) {
  final repo = ref.watch(medicationRepositoryProvider);
  return repo.watchMedications(patientId: args.patientId, activeOnly: args.activeOnly);
});

final examsProvider = StreamProvider.family<List<ExamModel>, String>((ref, patientId) {
  final repo = ref.watch(examRepositoryProvider);
  return repo.watchExams(patientId: patientId);
});

final notificationsProvider = StreamProvider.family<List<NotificationModel>, String>((ref, patientId) {
  final repo = ref.watch(notificationRepositoryProvider);
  return repo.watchNotifications(patientId: patientId);
});

final vaccinationsProvider = StreamProvider.family<List<VaccinationModel>, String>((ref, patientId) {
  final repo = ref.watch(vaccinationRepositoryProvider);
  return repo.watchVaccinations(patientId: patientId);
});

final articlesProvider = StreamProvider.family<List<ArticleModel>, String?>((ref, category) {
  final repo = ref.watch(articleRepositoryProvider);
  return repo.watchArticles(category: category);
});
