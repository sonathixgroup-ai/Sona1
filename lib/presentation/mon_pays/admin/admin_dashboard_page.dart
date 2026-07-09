// lib/presentation/mon_pays/admin/admin_state.dart

import 'package:equatable/equatable.dart';
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

/// État du dashboard d'administration
class AdminState extends Equatable {
  // États de chargement globaux et section-specific
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;

  // Données pour chaque entité (gérées séparément)
  final List<Authority> authorities;
  final List<HistoricalFigure> historicalFigures;
  final List<News> news;
  final List<Agency> agencies;
  final List<Video> videos;
  final List<Documentary> documentaries;
  final List<WantedPerson> wantedPersons;
  final List<ExemplaryCitizen> exemplaryCitizens;
  final List<Law> laws;
  final List<Consultation> consultations;

  // Section active (pour navigation dans le dashboard)
  final AdminSection activeSection;

  const AdminState({
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
    this.authorities = const [],
    this.historicalFigures = const [],
    this.news = const [],
    this.agencies = const [],
    this.videos = const [],
    this.documentaries = const [],
    this.wantedPersons = const [],
    this.exemplaryCitizens = const [],
    this.laws = const [],
    this.consultations = const [],
    this.activeSection = AdminSection.authorities,
  });

  AdminState copyWith({
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
    return AdminState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
      successMessage: successMessage,
      authorities: authorities ?? this.authorities,
      historicalFigures: historicalFigures ?? this.historicalFigures,
      news: news ?? this.news,
      agencies: agencies ?? this.agencies,
      videos: videos ?? this.videos,
      documentaries: documentaries ?? this.documentaries,
      wantedPersons: wantedPersons ?? this.wantedPersons,
      exemplaryCitizens: exemplaryCitizens ?? this.exemplaryCitizens,
      laws: laws ?? this.laws,
      consultations: consultations ?? this.consultations,
      activeSection: activeSection ?? this.activeSection,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isSaving,
        errorMessage,
        successMessage,
        authorities,
        historicalFigures,
        news,
        agencies,
        videos,
        documentaries,
        wantedPersons,
        exemplaryCitizens,
        laws,
        consultations,
        activeSection,
      ];
}

/// Sections disponibles dans le dashboard admin
enum AdminSection {
  authorities('Autorités'),
  historical('Figures Historiques'),
  news('Actualités'),
  agencies('Agences & Institutions'),
  videos('Vidéos Officielles'),
  documentaries('Documentaires'),
  wanted('Personnes Recherchées'),
  citizens('Citoyens Exemplaires'),
  laws('Valeurs & Lois'),
  consultations('Consultations');

  final String label;
  const AdminSection(this.label);
}
