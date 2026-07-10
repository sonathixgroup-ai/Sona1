// lib/presentation/mon_pays/admin/admin_controller.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import '../models/authority_model.dart';
import '../models/news_model.dart';
import '../models/agency_model.dart';
import '../models/government_model.dart';
import '../models/ministry_model.dart';
import '../models/history_model.dart';
import '../models/law_model.dart';
import '../models/video_model.dart';
import '../models/documentary_model.dart';
import '../models/wanted_person_model.dart';
import '../models/citizen_model.dart';
import '../models/consultation_model.dart';

class AdminController extends StateNotifier<AdminState> {
  final AuthoritiesRepository _authoritiesRepo;
  final GovernmentRepository _governmentRepo;
  final MinistryRepository _ministryRepo;
  final AgenciesRepository _agenciesRepo;
  final HistoryRepository _historyRepo;
  final NewsRepository _newsRepo;
  final LawRepository _lawRepo;
  final VideosRepository _videosRepo;
  final DocumentariesRepository _documentariesRepo;
  final WantedPeopleRepository _wantedRepo;
  final CitizensRepository _citizensRepo;
  final ConsultationsRepository _consultationsRepo;

  AdminController({
    required AuthoritiesRepository authoritiesRepo,
    required GovernmentRepository governmentRepo,
    required MinistryRepository ministryRepo,
    required AgenciesRepository agenciesRepo,
    required HistoryRepository historyRepo,
    required NewsRepository newsRepo,
    required LawRepository lawRepo,
    required VideosRepository videosRepo,
    required DocumentariesRepository documentariesRepo,
    required WantedPeopleRepository wantedRepo,
    required CitizensRepository citizensRepo,
    required ConsultationsRepository consultationsRepo,
  })  : _authoritiesRepo = authoritiesRepo,
        _governmentRepo = governmentRepo,
        _ministryRepo = ministryRepo,
        _agenciesRepo = agenciesRepo,
        _historyRepo = historyRepo,
        _newsRepo = newsRepo,
        _lawRepo = lawRepo,
        _videosRepo = videosRepo,
        _documentariesRepo = documentariesRepo,
        _wantedRepo = wantedRepo,
        _citizensRepo = citizensRepo,
        _consultationsRepo = consultationsRepo,
        super(const AdminState());

  /// Change la section active
  void setActiveSection(AdminSection section) {
    state = state.copyWith(activeSection: section);
  }

  /// Charge toutes les données
  Future<void> loadAllData() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await Future.wait([
        _authoritiesRepo.getAll(),
        _governmentRepo.getAll(),
        _ministryRepo.getAll(),
        _agenciesRepo.getAll(),
        _historyRepo.getAll(),
        _newsRepo.getAll(),
        _lawRepo.getAll(),
        _videosRepo.getAll(),
        _documentariesRepo.getAll(),
        _wantedRepo.getAll(),
        _citizensRepo.getAll(),
        _consultationsRepo.getAll(),
      ]);

      state = state.copyWith(
        isLoading: false,
        authorities: results[0] as List<Authority>,
        governments: results[1] as List<Government>,
        ministries: results[2] as List<Ministry>,
        agencies: results[3] as List<Agency>,
        historicalFigures: results[4] as List<HistoricalFigure>,
        news: results[5] as List<News>,
        laws: results[6] as List<Law>,
        videos: results[7] as List<Video>,
        documentaries: results[8] as List<Documentary>,
        wantedPersons: results[9] as List<WantedPerson>,
        exemplaryCitizens: results[10] as List<ExemplaryCitizen>,
        consultations: results[11] as List<Consultation>,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur de chargement: $e',
      );
    }
  }

  /// Rafraîchit une section spécifique
  Future<void> refreshSection(AdminSection section) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      switch (section) {
        case AdminSection.authorities:
          final data = await _authoritiesRepo.getAll();
          state = state.copyWith(authorities: data);
          break;
        case AdminSection.government:
          final data = await _governmentRepo.getAll();
          state = state.copyWith(governments: data);
          break;
        case AdminSection.ministries:
          final data = await _ministryRepo.getAll();
          state = state.copyWith(ministries: data);
          break;
        case AdminSection.agencies:
          final data = await _agenciesRepo.getAll();
          state = state.copyWith(agencies: data);
          break;
        case AdminSection.history:
          final data = await _historyRepo.getAll();
          state = state.copyWith(historicalFigures: data);
          break;
        case AdminSection.news:
          final data = await _newsRepo.getAll();
          state = state.copyWith(news: data);
          break;
        case AdminSection.laws:
          final data = await _lawRepo.getAll();
          state = state.copyWith(laws: data);
          break;
        case AdminSection.videos:
          final data = await _videosRepo.getAll();
          state = state.copyWith(videos: data);
          break;
        case AdminSection.documentaries:
          final data = await _documentariesRepo.getAll();
          state = state.copyWith(documentaries: data);
          break;
        case AdminSection.wanted:
          final data = await _wantedRepo.getAll();
          state = state.copyWith(wantedPersons: data);
          break;
        case AdminSection.citizens:
          final data = await _citizensRepo.getAll();
          state = state.copyWith(exemplaryCitizens: data);
          break;
        case AdminSection.consultations:
          final data = await _consultationsRepo.getAll();
          state = state.copyWith(consultations: data);
          break;
      }
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur de rafraîchissement: $e',
      );
    }
  }

  // ==================== CRUD pour Autorités ====================
  Future<void> addAuthority(Authority authority) async {
    await _performSave(() => _authoritiesRepo.create(authority));
    await refreshSection(AdminSection.authorities);
  }

  Future<void> updateAuthority(Authority authority) async {
    await _performSave(() => _authoritiesRepo.update(authority));
    await refreshSection(AdminSection.authorities);
  }

  Future<void> deleteAuthority(String id) async {
    await _performDelete(() => _authoritiesRepo.delete(id));
    await refreshSection(AdminSection.authorities);
  }

  // ==================== CRUD pour Actualités ====================
  Future<void> addNews(News news) async {
    await _performSave(() => _newsRepo.create(news));
    await refreshSection(AdminSection.news);
  }

  Future<void> updateNews(News news) async {
    await _performSave(() => _newsRepo.update(news));
    await refreshSection(AdminSection.news);
  }

  Future<void> deleteNews(String id) async {
    await _performDelete(() => _newsRepo.delete(id));
    await refreshSection(AdminSection.news);
  }

  // ==================== CRUD pour Agences ====================
  Future<void> addAgency(Agency agency) async {
    await _performSave(() => _agenciesRepo.create(agency));
    await refreshSection(AdminSection.agencies);
  }

  Future<void> updateAgency(Agency agency) async {
    await _performSave(() => _agenciesRepo.update(agency));
    await refreshSection(AdminSection.agencies);
  }

  Future<void> deleteAgency(String id) async {
    await _performDelete(() => _agenciesRepo.delete(id));
    await refreshSection(AdminSection.agencies);
  }

  // ==================== CRUD pour Figures historiques ====================
  Future<void> addHistoricalFigure(HistoricalFigure figure) async {
    await _performSave(() => _historyRepo.create(figure));
    await refreshSection(AdminSection.history);
  }

  Future<void> updateHistoricalFigure(HistoricalFigure figure) async {
    await _performSave(() => _historyRepo.update(figure));
    await refreshSection(AdminSection.history);
  }

  Future<void> deleteHistoricalFigure(String id) async {
    await _performDelete(() => _historyRepo.delete(id));
    await refreshSection(AdminSection.history);
  }

  // ==================== CRUD pour Vidéos ====================
  Future<void> addVideo(Video video) async {
    await _performSave(() => _videosRepo.create(video));
    await refreshSection(AdminSection.videos);
  }

  Future<void> updateVideo(Video video) async {
    await _performSave(() => _videosRepo.update(video));
    await refreshSection(AdminSection.videos);
  }

  Future<void> deleteVideo(String id) async {
    await _performDelete(() => _videosRepo.delete(id));
    await refreshSection(AdminSection.videos);
  }

  // ==================== CRUD pour Documentaires ====================
  Future<void> addDocumentary(Documentary doc) async {
    await _performSave(() => _documentariesRepo.create(doc));
    await refreshSection(AdminSection.documentaries);
  }

  Future<void> updateDocumentary(Documentary doc) async {
    await _performSave(() => _documentariesRepo.update(doc));
    await refreshSection(AdminSection.documentaries);
  }

  Future<void> deleteDocumentary(String id) async {
    await _performDelete(() => _documentariesRepo.delete(id));
    await refreshSection(AdminSection.documentaries);
  }

  // ==================== CRUD pour Personnes recherchées ====================
  Future<void> addWantedPerson(WantedPerson person) async {
    await _performSave(() => _wantedRepo.create(person));
    await refreshSection(AdminSection.wanted);
  }

  Future<void> updateWantedPerson(WantedPerson person) async {
    await _performSave(() => _wantedRepo.update(person));
    await refreshSection(AdminSection.wanted);
  }

  Future<void> deleteWantedPerson(String id) async {
    await _performDelete(() => _wantedRepo.delete(id));
    await refreshSection(AdminSection.wanted);
  }

  // ==================== CRUD pour Citoyens exemplaires ====================
  Future<void> addExemplaryCitizen(ExemplaryCitizen citizen) async {
    await _performSave(() => _citizensRepo.create(citizen));
    await refreshSection(AdminSection.citizens);
  }

  Future<void> updateExemplaryCitizen(ExemplaryCitizen citizen) async {
    await _performSave(() => _citizensRepo.update(citizen));
    await refreshSection(AdminSection.citizens);
  }

  Future<void> deleteExemplaryCitizen(String id) async {
    await _performDelete(() => _citizensRepo.delete(id));
    await refreshSection(AdminSection.citizens);
  }

  // ==================== CRUD pour Lois ====================
  Future<void> addLaw(Law law) async {
    await _performSave(() => _lawRepo.create(law));
    await refreshSection(AdminSection.laws);
  }

  Future<void> updateLaw(Law law) async {
    await _performSave(() => _lawRepo.update(law));
    await refreshSection(AdminSection.laws);
  }

  Future<void> deleteLaw(String id) async {
    await _performDelete(() => _lawRepo.delete(id));
    await refreshSection(AdminSection.laws);
  }

  // ==================== CRUD pour Consultations ====================
  Future<void> addConsultation(Consultation consultation) async {
    await _performSave(() => _consultationsRepo.create(consultation));
    await refreshSection(AdminSection.consultations);
  }

  Future<void> updateConsultation(Consultation consultation) async {
    await _performSave(() => _consultationsRepo.update(consultation));
    await refreshSection(AdminSection.consultations);
  }

  Future<void> deleteConsultation(String id) async {
    await _performDelete(() => _consultationsRepo.delete(id));
    await refreshSection(AdminSection.consultations);
  }

  // ==================== Méthodes utilitaires ====================
  Future<void> _performSave(Future<void> Function() operation) async {
    state = state.copyWith(isSaving: true, error: null, successMessage: null);
    try {
      await operation();
      state = state.copyWith(
        isSaving: false,
        successMessage: 'Opération réussie !',
      );
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: 'Erreur: $e',
      );
    }
  }

  Future<void> _performDelete(Future<void> Function() operation) async {
    state = state.copyWith(isSaving: true, error: null, successMessage: null);
    try {
      await operation();
      state = state.copyWith(
        isSaving: false,
        successMessage: 'Suppression réussie !',
      );
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: 'Erreur: $e',
      );
    }
  }
}
