// lib/presentation/mon_pays/providers/mon_pays_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../repositories/mon_pays_repository.dart';
import '../mon_pays_controller.dart';
import '../mon_pays_state.dart';

// Provider pour Dio (défini ailleurs, mais on le récupère)
final dioProvider = Provider<Dio>((ref) {
  // Implémentez selon votre configuration (base URL, interceptors, etc.)
  return Dio(BaseOptions(baseUrl: 'https://api.monpays.cd'));
});

// ------ Services (injection) ------
final authoritiesServiceProvider = Provider<AuthoritiesService>((ref) => AuthoritiesService(ref.watch(dioProvider)));
final governmentServiceProvider = Provider<GovernmentService>((ref) => GovernmentService(ref.watch(dioProvider)));
final agenciesServiceProvider = Provider<AgenciesService>((ref) => AgenciesService(ref.watch(dioProvider)));
final historyServiceProvider = Provider<HistoryService>((ref) => HistoryService(ref.watch(dioProvider)));
final newsServiceProvider = Provider<NewsService>((ref) => NewsService(ref.watch(dioProvider)));
final valuesServiceProvider = Provider<ValuesService>((ref) => ValuesService(ref.watch(dioProvider)));
final videosServiceProvider = Provider<VideosService>((ref) => VideosService(ref.watch(dioProvider)));
final documentariesServiceProvider = Provider<DocumentariesService>((ref) => DocumentariesService(ref.watch(dioProvider)));
final wantedPeopleServiceProvider = Provider<WantedPeopleService>((ref) => WantedPeopleService(ref.watch(dioProvider)));
final citizensServiceProvider = Provider<CitizensService>((ref) => CitizensService(ref.watch(dioProvider)));
final consultationsServiceProvider = Provider<ConsultationsService>((ref) => ConsultationsService(ref.watch(dioProvider)));
final searchServiceProvider = Provider<SearchService>((ref) => SearchService(ref.watch(dioProvider)));

// ------ Repositories (injection) ------
final authoritiesRepositoryProvider = Provider<AuthoritiesRepository>(
    (ref) => AuthoritiesRepository(ref.watch(authoritiesServiceProvider)));
final governmentRepositoryProvider = Provider<GovernmentRepository>(
    (ref) => GovernmentRepository(ref.watch(governmentServiceProvider)));
final agenciesRepositoryProvider = Provider<AgenciesRepository>(
    (ref) => AgenciesRepository(ref.watch(agenciesServiceProvider)));
final historyRepositoryProvider = Provider<HistoryRepository>(
    (ref) => HistoryRepository(ref.watch(historyServiceProvider)));
final newsRepositoryProvider = Provider<NewsRepository>(
    (ref) => NewsRepository(ref.watch(newsServiceProvider)));
final valuesRepositoryProvider = Provider<ValuesRepository>(
    (ref) => ValuesRepository(ref.watch(valuesServiceProvider)));
final videosRepositoryProvider = Provider<VideosRepository>(
    (ref) => VideosRepository(ref.watch(videosServiceProvider)));
final documentariesRepositoryProvider = Provider<DocumentariesRepository>(
    (ref) => DocumentariesRepository(ref.watch(documentariesServiceProvider)));
final wantedPeopleRepositoryProvider = Provider<WantedPeopleRepository>(
    (ref) => WantedPeopleRepository(ref.watch(wantedPeopleServiceProvider)));
final citizensRepositoryProvider = Provider<CitizensRepository>(
    (ref) => CitizensRepository(ref.watch(citizensServiceProvider)));
final consultationsRepositoryProvider = Provider<ConsultationsRepository>(
    (ref) => ConsultationsRepository(ref.watch(consultationsServiceProvider)));
final searchRepositoryProvider = Provider<SearchRepository>(
    (ref) => SearchRepository(ref.watch(searchServiceProvider)));

// ------ MonPaysRepository (agrégateur) ------
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

// ------ Contrôleur StateNotifier ------
final monPaysControllerProvider = StateNotifierProvider<MonPaysController, MonPaysState>((ref) {
  final repo = ref.watch(monPaysRepositoryProvider);
  return MonPaysController(repo);
});
