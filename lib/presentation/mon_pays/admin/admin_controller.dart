// lib/presentation/mon_pays/admin/admin_controller.dart

import 'package:get/get.dart';
import 'admin_state.dart';
import '../../services/authority_service.dart';
import '../../services/news_service.dart';
import '../../services/agency_service.dart';
import '../../services/video_service.dart';
import '../../services/documentary_service.dart';
import '../../services/wanted_service.dart';
import '../../services/citizen_service.dart';
import '../../services/law_service.dart';
import '../../services/consultation_service.dart';
import '../../models/authority_model.dart';
import '../../models/historical_figure_model.dart';
import '../../models/news_model.dart';
import '../../models/agency_model.dart';
import '../../models/video_model.dart';
import '../../models/documentary_model.dart';
import '../../models/wanted_person_model.dart';
import '../../models/exemplary_citizen_model.dart';
import '../../models/law_model.dart';
import '../../models/consultation_model.dart';

class AdminController extends GetxController {
  // Injection des services
  final AuthorityService _authorityService;
  final HistoricalFigureService _historicalService;
  final NewsService _newsService;
  final AgencyService _agencyService;
  final VideoService _videoService;
  final DocumentaryService _documentaryService;
  final WantedService _wantedService;
  final CitizenService _citizenService;
  final LawService _lawService;
  final ConsultationService _consultationService;

  AdminController(
    this._authorityService,
    this._historicalService,
    this._newsService,
    this._agencyService,
    this._videoService,
    this._documentaryService,
    this._wantedService,
    this._citizenService,
    this._lawService,
    this._consultationService,
  );

  // État réactif
  final Rx<AdminState> _state = AdminState().obs;
  AdminState get state => _state.value;

  // Getters pour les données de chaque section
  List<Authority> get authorities => state.authorities;
  List<HistoricalFigure> get historicalFigures => state.historicalFigures;
  List<News> get news => state.news;
  List<Agency> get agencies => state.agencies;
  List<Video> get videos => state.videos;
  List<Documentary> get documentaries => state.documentaries;
  List<WantedPerson> get wantedPersons => state.wantedPersons;
  List<ExemplaryCitizen> get exemplaryCitizens => state.exemplaryCitizens;
  List<Law> get laws => state.laws;
  List<Consultation> get consultations => state.consultations;
  AdminSection get activeSection => state.activeSection;
  bool get isLoading => state.isLoading;
  bool get isSaving => state.isSaving;
  String? get errorMessage => state.errorMessage;
  String? get successMessage => state.successMessage;

  @override
  void onInit() {
    super.onInit();
    loadAllData();
  }

  /// Charge toutes les données au démarrage
  Future<void> loadAllData() async {
    _updateState(isLoading: true, errorMessage: null, successMessage: null);
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

      _updateState(
        isLoading: false,
        authorities: results[0] as List<Authority>,
        historicalFigures: results[1] as List<HistoricalFigure>,
        news: results[2] as List<News>,
        agencies: results[3] as List<Agency>,
        videos: results[4] as List<Video>,
        documentaries: results[5] as List<Documentary>,
        wantedPersons: results[6] as List<WantedPerson>,
        exemplaryCitizens: results[7] as List<ExemplaryCitizen>,
        laws: results[8] as List<Law>,
        consultations: results[9] as List<Consultation>,
      );
    } catch (e) {
      _updateState(isLoading: false, errorMessage: 'Erreur de chargement: $e');
    }
  }

  /// Change la section active
  void setActiveSection(AdminSection section) {
    _updateState(activeSection: section);
  }

  // ==================== CRUD pour Autorités ====================
  Future<void> addAuthority(Authority authority) async {
    await _performSave(() => _authorityService.add(authority));
    await refreshSection(AdminSection.authorities);
  }

  Future<void> updateAuthority(Authority authority) async {
    await _performSave(() => _authorityService.update(authority));
    await refreshSection(AdminSection.authorities);
  }

  Future<void> deleteAuthority(String id) async {
    await _performDelete(() => _authorityService.delete(id));
    await refreshSection(AdminSection.authorities);
  }

  // ==================== CRUD pour Figures Historiques ====================
  Future<void> addHistoricalFigure(HistoricalFigure figure) async {
    await _performSave(() => _historicalService.add(figure));
    await refreshSection(AdminSection.historical);
  }

  Future<void> updateHistoricalFigure(HistoricalFigure figure) async {
    await _performSave(() => _historicalService.update(figure));
    await refreshSection(AdminSection.historical);
  }

  Future<void> deleteHistoricalFigure(String id) async {
    await _performDelete(() => _historicalService.delete(id));
    await refreshSection(AdminSection.historical);
  }

  // ==================== CRUD pour Actualités ====================
  Future<void> addNews(News newsItem) async {
    await _performSave(() => _newsService.add(newsItem));
    await refreshSection(AdminSection.news);
  }

  Future<void> updateNews(News newsItem) async {
    await _performSave(() => _newsService.update(newsItem));
    await refreshSection(AdminSection.news);
  }

  Future<void> deleteNews(String id) async {
    await _performDelete(() => _newsService.delete(id));
    await refreshSection(AdminSection.news);
  }

  // ==================== CRUD pour Agences ====================
  Future<void> addAgency(Agency agency) async {
    await _performSave(() => _agencyService.add(agency));
    await refreshSection(AdminSection.agencies);
  }

  Future<void> updateAgency(Agency agency) async {
    await _performSave(() => _agencyService.update(agency));
    await refreshSection(AdminSection.agencies);
  }

  Future<void> deleteAgency(String id) async {
    await _performDelete(() => _agencyService.delete(id));
    await refreshSection(AdminSection.agencies);
  }

  // ==================== CRUD pour Vidéos ====================
  Future<void> addVideo(Video video) async {
    await _performSave(() => _videoService.add(video));
    await refreshSection(AdminSection.videos);
  }

  Future<void> updateVideo(Video video) async {
    await _performSave(() => _videoService.update(video));
    await refreshSection(AdminSection.videos);
  }

  Future<void> deleteVideo(String id) async {
    await _performDelete(() => _videoService.delete(id));
    await refreshSection(AdminSection.videos);
  }

  // ==================== CRUD pour Documentaires ====================
  Future<void> addDocumentary(Documentary documentary) async {
    await _performSave(() => _documentaryService.add(documentary));
    await refreshSection(AdminSection.documentaries);
  }

  Future<void> updateDocumentary(Documentary documentary) async {
    await _performSave(() => _documentaryService.update(documentary));
    await refreshSection(AdminSection.documentaries);
  }

  Future<void> deleteDocumentary(String id) async {
    await _performDelete(() => _documentaryService.delete(id));
    await refreshSection(AdminSection.documentaries);
  }

  // ==================== CRUD pour Personnes Recherchées ====================
  Future<void> addWantedPerson(WantedPerson person) async {
    await _performSave(() => _wantedService.add(person));
    await refreshSection(AdminSection.wanted);
  }

  Future<void> updateWantedPerson(WantedPerson person) async {
    await _performSave(() => _wantedService.update(person));
    await refreshSection(AdminSection.wanted);
  }

  Future<void> deleteWantedPerson(String id) async {
    await _performDelete(() => _wantedService.delete(id));
    await refreshSection(AdminSection.wanted);
  }

  // ==================== CRUD pour Citoyens Exemplaires ====================
  Future<void> addExemplaryCitizen(ExemplaryCitizen citizen) async {
    await _performSave(() => _citizenService.add(citizen));
    await refreshSection(AdminSection.citizens);
  }

  Future<void> updateExemplaryCitizen(ExemplaryCitizen citizen) async {
    await _performSave(() => _citizenService.update(citizen));
    await refreshSection(AdminSection.citizens);
  }

  Future<void> deleteExemplaryCitizen(String id) async {
    await _performDelete(() => _citizenService.delete(id));
    await refreshSection(AdminSection.citizens);
  }

  // ==================== CRUD pour Valeurs & Lois ====================
  Future<void> addLaw(Law law) async {
    await _performSave(() => _lawService.add(law));
    await refreshSection(AdminSection.laws);
  }

  Future<void> updateLaw(Law law) async {
    await _performSave(() => _lawService.update(law));
    await refreshSection(AdminSection.laws);
  }

  Future<void> deleteLaw(String id) async {
    await _performDelete(() => _lawService.delete(id));
    await refreshSection(AdminSection.laws);
  }

  // ==================== CRUD pour Consultations ====================
  Future<void> addConsultation(Consultation consultation) async {
    await _performSave(() => _consultationService.add(consultation));
    await refreshSection(AdminSection.consultations);
  }

  Future<void> updateConsultation(Consultation consultation) async {
    await _performSave(() => _consultationService.update(consultation));
    await refreshSection(AdminSection.consultations);
  }

  Future<void> deleteConsultation(String id) async {
    await _performDelete(() => _consultationService.delete(id));
    await refreshSection(AdminSection.consultations);
  }

  // ==================== Méthodes utilitaires ====================
  Future<void> _performSave(Future<void> Function() operation) async {
    _updateState(isSaving: true, errorMessage: null, successMessage: null);
    try {
      await operation();
      _updateState(isSaving: false, successMessage: 'Opération réussie !');
    } catch (e) {
      _updateState(isSaving: false, errorMessage: 'Erreur: $e');
    }
  }

  Future<void> _performDelete(Future<void> Function() operation) async {
    _updateState(isSaving: true, errorMessage: null, successMessage: null);
    try {
      await operation();
      _updateState(isSaving: false, successMessage: 'Suppression réussie !');
    } catch (e) {
      _updateState(isSaving: false, errorMessage: 'Erreur: $e');
    }
  }

  /// Rafraîchit une section spécifique
  Future<void> refreshSection(AdminSection section) async {
    _updateState(isLoading: true);
    try {
      switch (section) {
        case AdminSection.authorities:
          final data = await _authorityService.getAll();
          _updateState(authorities: data);
          break;
        case AdminSection.historical:
          final data = await _historicalService.getAll();
          _updateState(historicalFigures: data);
          break;
        case AdminSection.news:
          final data = await _newsService.getAll();
          _updateState(news: data);
          break;
        case AdminSection.agencies:
          final data = await _agencyService.getAll();
          _updateState(agencies: data);
          break;
        case AdminSection.videos:
          final data = await _videoService.getAll();
          _updateState(videos: data);
          break;
        case AdminSection.documentaries:
          final data = await _documentaryService.getAll();
          _updateState(documentaries: data);
          break;
        case AdminSection.wanted:
          final data = await _wantedService.getAll();
          _updateState(wantedPersons: data);
          break;
        case AdminSection.citizens:
          final data = await _citizenService.getAll();
          _updateState(exemplaryCitizens: data);
          break;
        case AdminSection.laws:
          final data = await _lawService.getAll();
          _updateState(laws: data);
          break;
        case AdminSection.consultations:
          final data = await _consultationService.getAll();
          _updateState(consultations: data);
          break;
      }
      _updateState(isLoading: false);
    } catch (e) {
      _updateState(isLoading: false, errorMessage: 'Erreur de rafraîchissement: $e');
    }
  }

  void _updateState({
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
    List<Authority>? authorities,
    List<HistoricalFigure>? historicalFigures,
    List<News>? news,
    List<Agency>? agencies,
    List<Video>? videos,
    List<Documentary>? documentaries,
    List<WantedPerson>? wantedPersons,
    List<ExemplaryCitizen>? exemplaryCitizens,
    List<Law>? laws,
    List<Consultation>? consultations,
    AdminSection? activeSection,
  }) {
    _state.value = _state.value.copyWith(
      isLoading: isLoading,
      isSaving: isSaving,
      errorMessage: errorMessage,
      successMessage: successMessage,
      authorities: authorities,
      historicalFigures: historicalFigures,
      news: news,
      agencies: agencies,
      videos: videos,
      documentaries: documentaries,
      wantedPersons: wantedPersons,
      exemplaryCitizens: exemplaryCitizens,
      laws: laws,
      consultations: consultations,
      activeSection: activeSection,
    );
  }
}
