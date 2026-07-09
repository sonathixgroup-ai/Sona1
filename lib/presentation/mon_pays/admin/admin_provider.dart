// lib/presentation/mon_pays/admin/admin_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'admin_controller.dart';
import 'admin_state.dart';
import '../repositories/authorities_repository.dart';
import '../repositories/government_repository.dart';
import '../repositories/ministry_repository.dart';
import '../repositories/agencies_repository.dart';
import '../repositories/history_repository.dart';
import '../repositories/news_repository.dart';
import '../repositories/law_repository.dart';
import '../repositories/videos_repository.dart';
import '../repositories/documentaries_repository.dart';
import '../repositories/wanted_people_repository.dart';
import '../repositories/citizens_repository.dart';
import '../repositories/consultations_repository.dart';
import '../providers/mon_pays_provider.dart'; // pour les repositories déjà définis

// On réutilise les repositories déjà définis dans mon_pays_provider
final adminControllerProvider = StateNotifierProvider<AdminController, AdminState>((ref) {
  final authoritiesRepo = ref.watch(authoritiesRepositoryProvider);
  final governmentRepo = ref.watch(governmentRepositoryProvider);
  final ministryRepo = ref.watch(ministryRepositoryProvider);
  final agenciesRepo = ref.watch(agenciesRepositoryProvider);
  final historyRepo = ref.watch(historyRepositoryProvider);
  final newsRepo = ref.watch(newsRepositoryProvider);
  final lawRepo = ref.watch(lawRepositoryProvider);
  final videosRepo = ref.watch(videosRepositoryProvider);
  final documentariesRepo = ref.watch(documentariesRepositoryProvider);
  final wantedRepo = ref.watch(wantedPeopleRepositoryProvider);
  final citizensRepo = ref.watch(citizensRepositoryProvider);
  final consultationsRepo = ref.watch(consultationsRepositoryProvider);

  return AdminController(
    authoritiesRepo: authoritiesRepo,
    governmentRepo: governmentRepo,
    ministryRepo: ministryRepo,
    agenciesRepo: agenciesRepo,
    historyRepo: historyRepo,
    newsRepo: newsRepo,
    lawRepo: lawRepo,
    videosRepo: videosRepo,
    documentariesRepo: documentariesRepo,
    wantedRepo: wantedRepo,
    citizensRepo: citizensRepo,
    consultationsRepo: consultationsRepo,
  );
});
