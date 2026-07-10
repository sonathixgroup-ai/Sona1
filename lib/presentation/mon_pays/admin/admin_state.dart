// lib/presentation/mon_pays/admin/admin_state.dart

import 'package:equatable/equatable.dart';
import '../models/authority_model.dart';
import '../models/news_model.dart';
import '../models/agency_model.dart';
import '../models/history_model.dart';
import '../models/video_model.dart';
import '../models/documentary_model.dart';
import '../models/wanted_person_model.dart';
import '../models/citizen_model.dart';
import '../models/law_model.dart';
import '../models/consultation_model.dart';
import '../models/government_model.dart';
import '../models/ministry_model.dart';

/// Section de gestion active
enum AdminSection {
  authorities,
  government,
  ministries,
  agencies,
  history,
  news,
  laws,
  videos,
  documentaries,
  wanted,
  citizens,
  consultations,
}

/// État du dashboard d'administration
class AdminState extends Equatable {
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final String? successMessage;
  final AdminSection activeSection;

  // Données
  final List<Authority> authorities;
  final List<Government> governments;
  final List<Ministry> ministries;
  final List<Agency> agencies;
  final List<HistoricalFigure> historicalFigures;
  final List<News> news;
  final List<Law> laws;
  final List<Video> videos;
  final List<Documentary> documentaries;
  final List<WantedPerson> wantedPersons;
  final List<ExemplaryCitizen> exemplaryCitizens;
  final List<Consultation> consultations;

  const AdminState({
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.successMessage,
    this.activeSection = AdminSection.authorities,
    this.authorities = const [],
    this.governments = const [],
    this.ministries = const [],
    this.agencies = const [],
    this.historicalFigures = const [],
    this.news = const [],
    this.laws = const [],
    this.videos = const [],
    this.documentaries = const [],
    this.wantedPersons = const [],
    this.exemplaryCitizens = const [],
    this.consultations = const [],
  });

  AdminState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? error,
    String? successMessage,
    AdminSection? activeSection,
    List<Authority>? authorities,
    List<Government>? governments,
    List<Ministry>? ministries,
    List<Agency>? agencies,
    List<HistoricalFigure>? historicalFigures,
    List<News>? news,
    List<Law>? laws,
    List<Video>? videos,
    List<Documentary>? documentaries,
    List<WantedPerson>? wantedPersons,
    List<ExemplaryCitizen>? exemplaryCitizens,
    List<Consultation>? consultations,
  }) {
    return AdminState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error ?? this.error,
      successMessage: successMessage ?? this.successMessage,
      activeSection: activeSection ?? this.activeSection,
      authorities: authorities ?? this.authorities,
      governments: governments ?? this.governments,
      ministries: ministries ?? this.ministries,
      agencies: agencies ?? this.agencies,
      historicalFigures: historicalFigures ?? this.historicalFigures,
      news: news ?? this.news,
      laws: laws ?? this.laws,
      videos: videos ?? this.videos,
      documentaries: documentaries ?? this.documentaries,
      wantedPersons: wantedPersons ?? this.wantedPersons,
      exemplaryCitizens: exemplaryCitizens ?? this.exemplaryCitizens,
      consultations: consultations ?? this.consultations,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isSaving,
        error,
        successMessage,
        activeSection,
        authorities,
        governments,
        ministries,
        agencies,
        historicalFigures,
        news,
        laws,
        videos,
        documentaries,
        wantedPersons,
        exemplaryCitizens,
        consultations,
      ];
}
