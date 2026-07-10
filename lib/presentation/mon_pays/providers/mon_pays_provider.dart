// lib/presentation/mon_pays/providers/mon_pays_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/mon_pays_repository.dart';
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
import '../repositories/search_repository.dart';
import '../repositories/values_repository.dart';
import '../services/authorities_service.dart';
import '../services/government_service.dart';
import '../services/ministry_service.dart';
import '../services/agencies_service.dart';
import '../services/history_service.dart';
import '../services/news_service.dart';
import '../services/law_service.dart';
import '../services/videos_service.dart';
import '../services/documentaries_service.dart';
import '../services/wanted_people_service.dart';
import '../services/citizens_service.dart';
import '../services/consultations_service.dart';
import '../services/search_service.dart';
import '../services/values_service.dart';
import '../mon_pays_controller.dart';
import '../mon_pays_state.dart';

// ─── Fournisseur Dio avec Supabase ──────────────────────────────

final dioProvider = Provider<Dio>((ref) {
  final supabase = Supabase.instance.client;

  // ✅ Utilisation de supabase.supabaseUrl (disponible dans toutes les versions)
  final baseUrl = supabase.supabaseUrl;

  final dio = Dio(BaseOptions(
    baseUrl: '$baseUrl/rest/v1', // L'URL REST de Supabase
    headers: {
      'apikey': supabase.auth.currentSession?.accessToken ?? '',
      'Authorization': 'Bearer ${supabase.auth.currentSession?.accessToken}',
      'Content-Type': 'application/json',
      'Prefer': 'return=representation',
    },
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      final session = supabase.auth.currentSession;
      if (session != null) {
        options.headers['Authorization'] = 'Bearer ${session.accessToken}';
        options.headers['apikey'] = session.accessToken;
      }
      return handler.next(options);
    },
  ));

  return dio;
});

// ─── Services ────────────────────────────────────────────────────

final authoritiesServiceProvider = Provider<AuthoritiesService>((ref) => AuthoritiesService(ref.watch(dioProvider)));
final governmentServiceProvider = Provider<GovernmentService>((ref) => GovernmentService(ref.watch(dioProvider)));
final ministryServiceProvider = Provider<MinistryService>((ref) => MinistryService(ref.watch(dioProvider)));
final agenciesServiceProvider = Provider<AgenciesService>((ref) => AgenciesService(ref.watch(dioProvider)));
final historyServiceProvider = Provider<HistoryService>((ref) => HistoryService(ref.watch(dioProvider)));
final newsServiceProvider = Provider<NewsService>((ref) => NewsService(ref.watch(dioProvider)));
final lawServiceProvider = Provider<LawService>((ref) => LawService(ref.watch(dioProvider)));
final valuesServiceProvider = Provider<ValuesService>((ref) => ValuesService(ref.watch(dioProvider)));
final videosServiceProvider = Provider<VideosService>((ref) => VideosService(ref.watch(dioProvider)));
final documentariesServiceProvider = Provider<DocumentariesService>((ref) => DocumentariesService(ref.watch(dioProvider)));
final wantedPeopleServiceProvider = Provider<WantedPeopleService>((ref) => WantedPeopleService(ref.watch(dioProvider)));
final citizensServiceProvider = Provider<CitizensService>((ref) => CitizensService(ref.watch(dioProvider)));
final consultationsServiceProvider = Provider<ConsultationsService>((ref) => ConsultationsService(ref.watch(dioProvider)));
final searchServiceProvider = Provider<SearchService>((ref) => SearchService(ref.watch(dioProvider)));

// ─── Repositories ────────────────────────────────────────────────

final authoritiesRepositoryProvider = Provider<AuthoritiesRepository>((ref) => AuthoritiesRepository(ref.watch(authoritiesServiceProvider)));
final governmentRepositoryProvider = Provider<GovernmentRepository>((ref) => GovernmentRepository(ref.watch(governmentServiceProvider)));
final ministryRepositoryProvider = Provider<MinistryRepository>((ref) => MinistryRepository(ref.watch(ministryServiceProvider)));
final agenciesRepositoryProvider = Provider<AgenciesRepository>((ref) => AgenciesRepository(ref.watch(agenciesServiceProvider)));
final historyRepositoryProvider = Provider<HistoryRepository>((ref) => HistoryRepository(ref.watch(historyServiceProvider)));
final newsRepositoryProvider = Provider<NewsRepository>((ref) => NewsRepository(ref.watch(newsServiceProvider)));
final lawRepositoryProvider = Provider<LawRepository>((ref) => LawRepository(ref.watch(lawServiceProvider)));
final valuesRepositoryProvider = Provider<ValuesRepository>((ref) => ValuesRepository(ref.watch(valuesServiceProvider)));
final videosRepositoryProvider = Provider<VideosRepository>((ref) => VideosRepository(ref.watch(videosServiceProvider)));
final documentariesRepositoryProvider = Provider<DocumentariesRepository>((ref) => DocumentariesRepository(ref.watch(documentariesServiceProvider)));
final wantedPeopleRepositoryProvider = Provider<WantedPeopleRepository>((ref) => WantedPeopleRepository(ref.watch(wantedPeopleServiceProvider)));
final citizensRepositoryProvider = Provider<CitizensRepository>((ref) => CitizensRepository(ref.watch(citizensServiceProvider)));
final consultationsRepositoryProvider = Provider<ConsultationsRepository>((ref) => ConsultationsRepository(ref.watch(consultationsServiceProvider)));
final searchRepositoryProvider = Provider<SearchRepository>((ref) => SearchRepository(ref.watch(searchServiceProvider)));

// ─── MonPaysRepository agrégateur ──────────────────────────────

final monPaysRepositoryProvider = Provider<MonPaysRepository>((ref) {
  return MonPaysRepository(
    authoritiesRepo: ref.watch(authoritiesRepositoryProvider),
    historyRepo: ref.watch(historyRepositoryProvider),
    newsRepo: ref.watch(newsRepositoryProvider),
    agenciesRepo: ref.watch(agenciesRepositoryProvider),
    videosRepo: ref.watch(videosRepositoryProvider),
    documentariesRepo: ref.watch(documentariesRepositoryProvider),
    wantedRepo: ref.watch(wantedPeopleRepositoryProvider),
    citizensRepo: ref.watch(citizensRepositoryProvider),
    valuesRepo: ref.watch(valuesRepositoryProvider),
    consultationsRepo: ref.watch(consultationsRepositoryProvider),
    governmentRepo: ref.watch(governmentRepositoryProvider),
    searchRepo: ref.watch(searchRepositoryProvider),
  );
});

// ─── Contrôleur ─────────────────────────────────────────────────

final monPaysControllerProvider = StateNotifierProvider<MonPaysController, MonPaysState>((ref) {
  final repo = ref.watch(monPaysRepositoryProvider);
  return MonPaysController(repo);
});
