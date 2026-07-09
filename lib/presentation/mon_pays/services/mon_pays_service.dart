// lib/presentation/mon_pays/services/mon_pays_service.dart

import 'package:dio/dio.dart';
import 'authority_service.dart';
import 'news_service.dart';
import 'agency_service.dart';
import 'wanted_service.dart';
import 'citizen_service.dart';
import 'consultation_service.dart';
import '../models/authority_model.dart';
import '../models/historical_figure_model.dart';
import '../models/news_model.dart';
import '../models/agency_model.dart';
import '../models/video_model.dart';
import '../models/documentary_model.dart';
import '../models/wanted_person_model.dart';
import '../models/exemplary_citizen_model.dart';
import '../models/law_model.dart';
import '../models/consultation_model.dart';

/// Service principal qui agrège tous les appels du module Mon Pays
class MonPaysService {
  final Dio dio;
  late final AuthorityService _authorityService;
  late final HistoricalFigureService _historicalService;
  late final NewsService _newsService;
  late final AgencyService _agencyService;
  late final VideoService _videoService;
  late final DocumentaryService _documentaryService;
  late final WantedService _wantedService;
  late final CitizenService _citizenService;
  late final LawService _lawService;
  late final ConsultationService _consultationService;

  MonPaysService({required this.dio}) {
    _authorityService = AuthorityService(dio: dio);
    _historicalService = HistoricalFigureService(dio: dio);
    _newsService = NewsService(dio: dio);
    _agencyService = AgencyService(dio: dio);
    _videoService = VideoService(dio: dio);
    _documentaryService = DocumentaryService(dio: dio);
    _wantedService = WantedService(dio: dio);
    _citizenService = CitizenService(dio: dio);
    _lawService = LawService(dio: dio);
    _consultationService = ConsultationService(dio: dio);
  }

  /// Récupère toutes les données du module en parallèle
  Future<Map<String, dynamic>> getAllData() async {
    try {
      final results = await Future.wait([
        _authorityService.getAll(),
        _historicalService.getAll(),
        _newsService.getAll(),
        _agencyService.getAll(),
        _videoService.getAll(),
        _documentaryService.getAll(),
        _wantedService.getAll(),
        _citizenService.getAll(),
        _lawService.getAll(),
        _consultationService.getAll(),
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
        'laws': results[8] as List<Law>,
        'consultations': results[9] as List<Consultation>,
      };
    } catch (e) {
      throw Exception('Erreur lors du chargement des données: $e');
    }
  }

  // Getters pour accéder aux services individuels si besoin
  AuthorityService get authorityService => _authorityService;
  HistoricalFigureService get historicalService => _historicalService;
  NewsService get newsService => _newsService;
  AgencyService get agencyService => _agencyService;
  VideoService get videoService => _videoService;
  DocumentaryService get documentaryService => _documentaryService;
  WantedService get wantedService => _wantedService;
  CitizenService get citizenService => _citizenService;
  LawService get lawService => _lawService;
  ConsultationService get consultationService => _consultationService;
}
