// lib/presentation/mon_pays/repositories/mon_pays_repository.dart

import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import '../services/mon_pays_service.dart';
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

/// Repository responsable de la gestion des données du module Mon Pays
/// avec un cache local pour une expérience hors ligne optimale.
class MonPaysRepository {
  final MonPaysService _service;
  final Box _cacheBox;
  final Duration cacheValidity;

  // Clés pour le cache
  static const String _keyAuthorities = 'authorities';
  static const String _keyHistoricalFigures = 'historical_figures';
  static const String _keyNews = 'news';
  static const String _keyAgencies = 'agencies';
  static const String _keyVideos = 'videos';
  static const String _keyDocumentaries = 'documentaries';
  static const String _keyWantedPersons = 'wanted_persons';
  static const String _keyExemplaryCitizens = 'exemplary_citizens';
  static const String _keyLaws = 'laws';
  static const String _keyConsultations = 'consultations';
  static const String _keyTimestamp = 'timestamp_';

  MonPaysRepository({
    required MonPaysService service,
    required Box cacheBox,
    this.cacheValidity = const Duration(minutes: 15),
  })  : _service = service,
        _cacheBox = cacheBox;

  // ==================== Autorités ====================
  Future<List<Authority>> getAuthorities({bool forceRefresh = false}) async {
    final key = _keyAuthorities;
    if (!forceRefresh && _isCacheValid(key)) {
      final data = _cacheBox.get(key);
      if (data != null) {
        return _deserializeList<Authority>(data, Authority.fromJson);
      }
    }
    final authorities = await _service.authorityService.getAll();
    _saveToCache(key, authorities.map((e) => e.toJson()).toList());
    return authorities;
  }

  // ==================== Figures Historiques ====================
  Future<List<HistoricalFigure>> getHistoricalFigures({bool forceRefresh = false}) async {
    final key = _keyHistoricalFigures;
    if (!forceRefresh && _isCacheValid(key)) {
      final data = _cacheBox.get(key);
      if (data != null) {
        return _deserializeList<HistoricalFigure>(data, HistoricalFigure.fromJson);
      }
    }
    final figures = await _service.historicalService.getAll();
    _saveToCache(key, figures.map((e) => e.toJson()).toList());
    return figures;
  }

  // ==================== Actualités ====================
  Future<List<News>> getNews({bool forceRefresh = false}) async {
    final key = _keyNews;
    if (!forceRefresh && _isCacheValid(key)) {
      final data = _cacheBox.get(key);
      if (data != null) {
        return _deserializeList<News>(data, News.fromJson);
      }
    }
    final news = await _service.newsService.getAll();
    _saveToCache(key, news.map((e) => e.toJson()).toList());
    return news;
  }

  // ==================== Agences ====================
  Future<List<Agency>> getAgencies({bool forceRefresh = false}) async {
    final key = _keyAgencies;
    if (!forceRefresh && _isCacheValid(key)) {
      final data = _cacheBox.get(key);
      if (data != null) {
        return _deserializeList<Agency>(data, Agency.fromJson);
      }
    }
    final agencies = await _service.agencyService.getAll();
    _saveToCache(key, agencies.map((e) => e.toJson()).toList());
    return agencies;
  }

  // ==================== Vidéos ====================
  Future<List<Video>> getVideos({bool forceRefresh = false}) async {
    final key = _keyVideos;
    if (!forceRefresh && _isCacheValid(key)) {
      final data = _cacheBox.get(key);
      if (data != null) {
        return _deserializeList<Video>(data, Video.fromJson);
      }
    }
    final videos = await _service.videoService.getAll();
    _saveToCache(key, videos.map((e) => e.toJson()).toList());
    return videos;
  }

  // ==================== Documentaires ====================
  Future<List<Documentary>> getDocumentaries({bool forceRefresh = false}) async {
    final key = _keyDocumentaries;
    if (!forceRefresh && _isCacheValid(key)) {
      final data = _cacheBox.get(key);
      if (data != null) {
        return _deserializeList<Documentary>(data, Documentary.fromJson);
      }
    }
    final documentaries = await _service.documentaryService.getAll();
    _saveToCache(key, documentaries.map((e) => e.toJson()).toList());
    return documentaries;
  }

  // ==================== Personnes Recherchées ====================
  Future<List<WantedPerson>> getWantedPersons({bool forceRefresh = false}) async {
    final key = _keyWantedPersons;
    if (!forceRefresh && _isCacheValid(key)) {
      final data = _cacheBox.get(key);
      if (data != null) {
        return _deserializeList<WantedPerson>(data, WantedPerson.fromJson);
      }
    }
    final persons = await _service.wantedService.getAll();
    _saveToCache(key, persons.map((e) => e.toJson()).toList());
    return persons;
  }

  // ==================== Citoyens Exemplaires ====================
  Future<List<ExemplaryCitizen>> getExemplaryCitizens({bool forceRefresh = false}) async {
    final key = _keyExemplaryCitizens;
    if (!forceRefresh && _isCacheValid(key)) {
      final data = _cacheBox.get(key);
      if (data != null) {
        return _deserializeList<ExemplaryCitizen>(data, ExemplaryCitizen.fromJson);
      }
    }
    final citizens = await _service.citizenService.getAll();
    _saveToCache(key, citizens.map((e) => e.toJson()).toList());
    return citizens;
  }

  // ==================== Lois ====================
  Future<List<Law>> getLaws({bool forceRefresh = false}) async {
    final key = _keyLaws;
    if (!forceRefresh && _isCacheValid(key)) {
      final data = _cacheBox.get(key);
      if (data != null) {
        return _deserializeList<Law>(data, Law.fromJson);
      }
    }
    final laws = await _service.lawService.getAll();
    _saveToCache(key, laws.map((e) => e.toJson()).toList());
    return laws;
  }

  // ==================== Consultations ====================
  Future<List<Consultation>> getConsultations({bool forceRefresh = false}) async {
    final key = _keyConsultations;
    if (!forceRefresh && _isCacheValid(key)) {
      final data = _cacheBox.get(key);
      if (data != null) {
        return _deserializeList<Consultation>(data, Consultation.fromJson);
      }
    }
    final consultations = await _service.consultationService.getAll();
    _saveToCache(key, consultations.map((e) => e.toJson()).toList());
    return consultations;
  }

  // ==================== Chargement global avec cache ====================
  Future<Map<String, dynamic>> getAllData({bool forceRefresh = false}) async {
    final futures = [
      getAuthorities(forceRefresh: forceRefresh),
      getHistoricalFigures(forceRefresh: forceRefresh),
      getNews(forceRefresh: forceRefresh),
      getAgencies(forceRefresh: forceRefresh),
      getVideos(forceRefresh: forceRefresh),
      getDocumentaries(forceRefresh: forceRefresh),
      getWantedPersons(forceRefresh: forceRefresh),
      getExemplaryCitizens(forceRefresh: forceRefresh),
      getLaws(forceRefresh: forceRefresh),
      getConsultations(forceRefresh: forceRefresh),
    ];

    final results = await Future.wait(futures);

    return {
      'authorities': results[0],
      'historicalFigures': results[1],
      'news': results[2],
      'agencies': results[3],
      'videos': results[4],
      'documentaries': results[5],
      'wantedPersons': results[6],
      'exemplaryCitizens': results[7],
      'laws': results[8],
      'consultations': results[9],
    };
  }

  // ==================== Cache management ====================
  void _saveToCache(String key, List data) {
    _cacheBox.put(key, data);
    _cacheBox.put(_keyTimestamp + key, DateTime.now().toIso8601String());
  }

  bool _isCacheValid(String key) {
    final timestampStr = _cacheBox.get(_keyTimestamp + key);
    if (timestampStr == null) return false;
    try {
      final timestamp = DateTime.parse(timestampStr);
      final now = DateTime.now();
      return now.difference(timestamp) <= cacheValidity;
    } catch (_) {
      return false;
    }
  }

  List<T> _deserializeList<T>(List data, T Function(Map<String, dynamic>) fromJson) {
    return data.map((item) => fromJson(item as Map<String, dynamic>)).toList();
  }

  /// Vide tout le cache du module Mon Pays
  Future<void> clearCache() async {
    final keys = _cacheBox.keys.where((k) => k is String && k.startsWith('_key'));
    for (var key in keys) {
      await _cacheBox.delete(key);
    }
    // Supprimer aussi les timestamps
    final timestampKeys = _cacheBox.keys.where((k) => k is String && k.startsWith(_keyTimestamp));
    for (var key in timestampKeys) {
      await _cacheBox.delete(key);
    }
  }
}
