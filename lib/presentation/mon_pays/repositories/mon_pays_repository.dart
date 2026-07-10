// lib/presentation/mon_pays/repositories/mon_pays_repository.dart

import 'agencies_repository.dart';
import 'authorities_repository.dart';
import 'citizens_repository.dart';
import 'consultations_repository.dart';
import 'documentaries_repository.dart';
import 'government_repository.dart';
import 'history_repository.dart';
import 'news_repository.dart';
import 'search_repository.dart';
import 'values_repository.dart';
import 'videos_repository.dart';
import 'wanted_people_repository.dart';
import '../models/agency_model.dart';
import '../models/authority_model.dart';
import '../models/citizen_model.dart';
import '../models/consultation_model.dart';
import '../models/documentary_model.dart';
import '../models/government_model.dart';
import '../models/history_model.dart';
import '../models/news_model.dart';
import '../models/value_model.dart';
import '../models/video_model.dart';
import '../models/wanted_person_model.dart';
import '../services/mon_pays_service.dart';

class MonPaysRepository {
  final AuthoritiesRepository _authoritiesRepo;
  final HistoryRepository _historyRepo;
  final NewsRepository _newsRepo;
  final AgenciesRepository _agenciesRepo;
  final VideosRepository _videosRepo;
  final DocumentariesRepository _documentariesRepo;
  final WantedPeopleRepository _wantedRepo;
  final CitizensRepository _citizensRepo;
  final ValuesRepository _valuesRepo;
  final ConsultationsRepository _consultationsRepo;
  final GovernmentRepository _governmentRepo;
  final SearchRepository _searchRepo;

  MonPaysRepository({
    required AuthoritiesRepository authoritiesRepo,
    required HistoryRepository historyRepo,
    required NewsRepository newsRepo,
    required AgenciesRepository agenciesRepo,
    required VideosRepository videosRepo,
    required DocumentariesRepository documentariesRepo,
    required WantedPeopleRepository wantedRepo,
    required CitizensRepository citizensRepo,
    required ValuesRepository valuesRepo,
    required ConsultationsRepository consultationsRepo,
    required GovernmentRepository governmentRepo,
    required SearchRepository searchRepo,
  }) : _authoritiesRepo = authoritiesRepo,
       _historyRepo = historyRepo,
       _newsRepo = newsRepo,
       _agenciesRepo = agenciesRepo,
       _videosRepo = videosRepo,
       _documentariesRepo = documentariesRepo,
       _wantedRepo = wantedRepo,
       _citizensRepo = citizensRepo,
       _valuesRepo = valuesRepo,
       _consultationsRepo = consultationsRepo,
       _governmentRepo = governmentRepo,
       _searchRepo = searchRepo;

  /// Crée un MonPaysRepository à partir d'un MonPaysService.
  factory MonPaysRepository.fromService(MonPaysService service) {
    return MonPaysRepository(
      authoritiesRepo: AuthoritiesRepository(service.authorities),
      historyRepo: HistoryRepository(service.history),
      newsRepo: NewsRepository(service.news),
      agenciesRepo: AgenciesRepository(service.agencies),
      videosRepo: VideosRepository(service.videos),
      documentariesRepo: DocumentariesRepository(service.documentaries),
      wantedRepo: WantedPeopleRepository(service.wantedPeople),
      citizensRepo: CitizensRepository(service.citizens),
      valuesRepo: ValuesRepository(service.values),
      consultationsRepo: ConsultationsRepository(service.consultations),
      governmentRepo: GovernmentRepository(service.government),
      searchRepo: SearchRepository(service.search),
    );
  }

  Future<Map<String, dynamic>> getAllData() async {
    final results = await Future.wait([
      _authoritiesRepo.getAll(),
      _historyRepo.getAll(),
      _newsRepo.getAll(),
      _agenciesRepo.getAll(),
      _videosRepo.getAll(),
      _documentariesRepo.getAll(),
      _wantedRepo.getAll(),
      _citizensRepo.getAll(),
      _valuesRepo.getAll(),
      _consultationsRepo.getAll(),
      _governmentRepo.getAll(),
    ]);

    return {
      'authorities': results[0] as List<Authority>,
      'historicalFigures': results[1] as List<HistoricalFigure>,
      'news': results[2] as List<News>,
      'agencies': results[3] as List<Agency>,
      'videos': results[4] as List<Video>,
      'documentaries': results[5] as List<Documentary>,
      'wantedPersons': results[6] as List<WantedPerson>,
      'exemplaryCitizens': results[7] as List<ExemplaryCitizen>,
      'values': results[8] as List<Value>,
      'consultations': results[9] as List<Consultation>,
      'governments': results[10] as List<Government>,
    };
  }

  // Getters pour les repositories individuels
  AuthoritiesRepository get authorities => _authoritiesRepo;
  HistoryRepository get history => _historyRepo;
  NewsRepository get news => _newsRepo;
  AgenciesRepository get agencies => _agenciesRepo;
  VideosRepository get videos => _videosRepo;
  DocumentariesRepository get documentaries => _documentariesRepo;
  WantedPeopleRepository get wanted => _wantedRepo;
  CitizensRepository get citizens => _citizensRepo;
  ValuesRepository get values => _valuesRepo;
  ConsultationsRepository get consultations => _consultationsRepo;
  GovernmentRepository get government => _governmentRepo;
  SearchRepository get search => _searchRepo;
}
