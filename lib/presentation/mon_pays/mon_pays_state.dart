// lib/presentation/mon_pays/mon_pays_state.dart

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

/// État global du module Mon Pays
class MonPaysState extends Equatable {
  final bool isLoading;
  final String? errorMessage;

  // Données principales
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

  // Filtres / recherche
  final String searchQuery;
  final String? selectedProvince;
  final String? selectedCategory;

  const MonPaysState({
    this.isLoading = false,
    this.errorMessage,
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
    this.searchQuery = '',
    this.selectedProvince,
    this.selectedCategory,
  });

  MonPaysState copyWith({
    bool? isLoading,
    String? errorMessage,
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
    String? searchQuery,
    String? selectedProvince,
    String? selectedCategory,
  }) {
    return MonPaysState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
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
      searchQuery: searchQuery ?? this.searchQuery,
      selectedProvince: selectedProvince ?? this.selectedProvince,
      selectedCategory: selectedCategory ?? this.selectedCategory,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        errorMessage,
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
        searchQuery,
        selectedProvince,
        selectedCategory,
      ];
}
