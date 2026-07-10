// lib/presentation/mon_pays/mon_pays_controller.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'mon_pays_state.dart';
import 'repositories/mon_pays_repository.dart';
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

class MonPaysController extends StateNotifier<MonPaysState> {
  final MonPaysRepository _repository;

  MonPaysController(this._repository) : super(const MonPaysState());

  /// Charge toutes les données du module
  Future<void> loadAllData() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _repository.getAllData();
      state = state.copyWith(
        isLoading: false,
        authorities: data['authorities'] as List<Authority>,
        historicalFigures: data['historicalFigures'] as List<HistoricalFigure>,
        news: data['news'] as List<News>,
        agencies: data['agencies'] as List<Agency>,
        videos: data['videos'] as List<Video>,
        documentaries: data['documentaries'] as List<Documentary>,
        wantedPersons: data['wantedPersons'] as List<WantedPerson>,
        exemplaryCitizens: data['exemplaryCitizens'] as List<ExemplaryCitizen>,
        values: data['values'] as List<Value>,
        consultations: data['consultations'] as List<Consultation>,
        governments: data['governments'] as List<Government>,
        ministries: data['ministries'] as List<Ministry>,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur de chargement: $e',
      );
    }
  }

  /// Rafraîchit les données (force le rechargement)
  Future<void> refreshData() => loadAllData();

  /// Met à jour la requête de recherche
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Efface la recherche
  void clearSearch() {
    state = state.copyWith(searchQuery: '');
  }
}
