// lib/presentation/mon_pays/mon_pays_state.dart

import 'package:equatable/equatable.dart';
import 'models/authority_model.dart';
import 'models/history_model.dart';
import 'models/news_model.dart';
import 'models/agency_model.dart';
import 'models/video_model.dart';
import 'models/documentary_model.dart';
import 'models/wanted_person_model.dart';
import 'models/citizen_model.dart';
import 'models/value_model.dart';
import 'models/consultation_model.dart';
import 'models/government_model.dart';
import 'models/ministry_model.dart';

/// État global du module Mon Pays
class MonPaysState extends Equatable {
  final bool isLoading;
  final String? error;
  final String searchQuery;

  // Données principales
  final List<Authority> authorities;
  final List<HistoricalFigure> historicalFigures;
  final List<News> news;
  final List<Agency> agencies;
  final List<Video> videos;
  final List<Documentary> documentaries;
  final List<WantedPerson> wantedPersons;
  final List<ExemplaryCitizen> exemplaryCitizens;
  final List<Value> values;
  final List<Consultation> consultations;
  final List<Government> governments;
  final List<Ministry> ministries;

  const MonPaysState({
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.authorities = const [],
    this.historicalFigures = const [],
    this.news = const [],
    this.agencies = const [],
    this.videos = const [],
    this.documentaries = const [],
    this.wantedPersons = const [],
    this.exemplaryCitizens = const [],
    this.values = const [],
    this.consultations = const [],
    this.governments = const [],
    this.ministries = const [],
  });

  MonPaysState copyWith({
    bool? isLoading,
    String? error,
    String? searchQuery,
    List<Authority>? authorities,
    List<HistoricalFigure>? historicalFigures,
    List<News>? news,
    List<Agency>? agencies,
    List<Video>? videos,
    List<Documentary>? documentaries,
    List<WantedPerson>? wantedPersons,
    List<ExemplaryCitizen>? exemplaryCitizens,
    List<Value>? values,
    List<Consultation>? consultations,
    List<Government>? governments,
    List<Ministry>? ministries,
  }) {
    return MonPaysState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      searchQuery: searchQuery ?? this.searchQuery,
      authorities: authorities ?? this.authorities,
      historicalFigures: historicalFigures ?? this.historicalFigures,
      news: news ?? this.news,
      agencies: agencies ?? this.agencies,
      videos: videos ?? this.videos,
      documentaries: documentaries ?? this.documentaries,
      wantedPersons: wantedPersons ?? this.wantedPersons,
      exemplaryCitizens: exemplaryCitizens ?? this.exemplaryCitizens,
      values: values ?? this.values,
      consultations: consultations ?? this.consultations,
      governments: governments ?? this.governments,
      ministries: ministries ?? this.ministries,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        error,
        searchQuery,
        authorities,
        historicalFigures,
        news,
        agencies,
        videos,
        documentaries,
        wantedPersons,
        exemplaryCitizens,
        values,
        consultations,
        governments,
        ministries,
      ];
}
