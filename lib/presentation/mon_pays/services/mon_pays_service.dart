
// lib/presentation/mon_pays/services/mon_pays_service.dart

import 'agencies_service.dart';
import 'authorities_service.dart';
import 'citizens_service.dart';
import 'consultations_service.dart';
import 'documentaries_service.dart';
import 'government_service.dart';
import 'history_service.dart';
import 'news_service.dart';
import 'search_service.dart';
import 'values_service.dart';
import 'videos_service.dart';
import 'wanted_people_service.dart';
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

/// Service agrégateur qui combine tous les services du module Mon Pays.
class MonPaysService {
  final AuthoritiesService _authoritiesService;
  final HistoryService _historyService;
  final NewsService _newsService;
  final AgenciesService _agenciesService;
  final VideosService _videosService;
  final DocumentariesService _documentariesService;
  final WantedPeopleService _wantedPeopleService;
  final CitizensService _citizensService;
  final ValuesService _valuesService;
  final ConsultationsService _consultationsService;
  final GovernmentService _governmentService;
  final SearchService _searchService;

  MonPaysService({
    required AuthoritiesService authoritiesService,
    required HistoryService historyService,
    required NewsService newsService,
    required AgenciesService agenciesService,
    required VideosService videosService,
    required DocumentariesService documentariesService,
    required WantedPeopleService wantedPeopleService,
    required CitizensService citizensService,
    required ValuesService valuesService,
    required ConsultationsService consultationsService,
    required GovernmentService governmentService,
    required SearchService searchService,
  }) : _authoritiesService = authoritiesService,
       _historyService = historyService,
       _newsService = newsService,
       _agenciesService = agenciesService,
       _videosService = videosService,
       _documentariesService = documentariesService,
       _wantedPeopleService = wantedPeopleService,
       _citizensService = citizensService,
       _valuesService = valuesService,
       _consultationsService = consultationsService,
       _governmentService = governmentService,
       _searchService = searchService;

  /// Récupère toutes les données en parallèle.
  Future<Map<String, dynamic>> getAllData() async {
    try {
      final results = await Future.wait([
        _authoritiesService.getAll(),
        _historyService.getAll(),
        _newsService.getAll(),
        _agenciesService.getAll(),
        _videosService.getAll(),
        _documentariesService.getAll(),
        _wantedPeopleService.getAll(),
        _citizensService.getAll(),
        _valuesService.getAll(),
        _consultationsService.getAll(),
        _governmentService.getAll(),
      ]);

      return {
        'authorities': results[0] as List<Authority>? ?? [],
        'historicalFigures': results[1] as List<HistoricalFigure>? ?? [],
        'news': results[2] as List<News>? ?? [],
        'agencies': results[3] as List<Agency>? ?? [],
        'videos': results[4] as List<Video>? ?? [],
        'documentaries': results[5] as List<Documentary>? ?? [],
        'wantedPersons': results[6] as List<WantedPerson>? ?? [],
        'exemplaryCitizens': results[7] as List<ExemplaryCitizen>? ?? [],
        'values': results[8] as List<Value>? ?? [],
        'consultations': results[9] as List<Consultation>? ?? [],
        'governments': results[10] as List<Government>? ?? [],
      };
    } catch (e) {
      // En cas d'erreur, retourner des listes vides
      return {
        'authorities': [],
        'historicalFigures': [],
        'news': [],
        'agencies': [],
        'videos': [],
        'documentaries': [],
        'wantedPersons': [],
        'exemplaryCitizens': [],
        'values': [],
        'consultations': [],
        'governments': [],
      };
    }
  }

  // Getters pour les services individuels (si nécessaire)
  AuthoritiesService get authorities => _authoritiesService;
  HistoryService get history => _historyService;
  NewsService get news => _newsService;
  AgenciesService get agencies => _agenciesService;
  VideosService get videos => _videosService;
  DocumentariesService get documentaries => _documentariesService;
  WantedPeopleService get wantedPeople => _wantedPeopleService;
  CitizensService get citizens => _citizensService;
  ValuesService get values => _valuesService;
  ConsultationsService get consultations => _consultationsService;
  GovernmentService get government => _governmentService;
  SearchService get search => _searchService;
}
