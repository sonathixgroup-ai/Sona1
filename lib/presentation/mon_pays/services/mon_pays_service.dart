// lib/presentation/mon_pays/services/mon_pays_service.dart

import 'package:dio/dio.dart';
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

class MonPaysService {
  final Dio _dio;
  late final AgenciesService _agenciesService;
  late final AuthoritiesService _authoritiesService;
  late final CitizensService _citizensService;
  late final ConsultationsService _consultationsService;
  late final DocumentariesService _documentariesService;
  late final GovernmentService _governmentService;
  late final HistoryService _historyService;
  late final NewsService _newsService;
  late final SearchService _searchService;
  late final ValuesService _valuesService;
  late final VideosService _videosService;
  late final WantedPeopleService _wantedPeopleService;

  MonPaysService(this._dio) {
    _agenciesService = AgenciesService(_dio);
    _authoritiesService = AuthoritiesService(_dio);
    _citizensService = CitizensService(_dio);
    _consultationsService = ConsultationsService(_dio);
    _documentariesService = DocumentariesService(_dio);
    _governmentService = GovernmentService(_dio);
    _historyService = HistoryService(_dio);
    _newsService = NewsService(_dio);
    _searchService = SearchService(_dio);
    _valuesService = ValuesService(_dio);
    _videosService = VideosService(_dio);
    _wantedPeopleService = WantedPeopleService(_dio);
  }

  Future<Map<String, dynamic>> getAllData() async {
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

  // Getters pour les services individuels (si nécessaire)
  AuthoritiesService get authorities => _authoritiesService;
  AgenciesService get agencies => _agenciesService;
  CitizensService get citizens => _citizensService;
  ConsultationsService get consultations => _consultationsService;
  DocumentariesService get documentaries => _documentariesService;
  GovernmentService get government => _governmentService;
  HistoryService get history => _historyService;
  NewsService get news => _newsService;
  SearchService get search => _searchService;
  ValuesService get values => _valuesService;
  VideosService get videos => _videosService;
  WantedPeopleService get wantedPeople => _wantedPeopleService;
}
