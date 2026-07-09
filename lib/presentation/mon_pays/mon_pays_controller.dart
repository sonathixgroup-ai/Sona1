// lib/presentation/mon_pays/mon_pays_controller.dart

import 'package:get/get.dart';
import 'mon_pays_state.dart';
import '../../services/mon_pays_service.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';

class MonPaysController extends GetxController {
  final MonPaysService _service;
  final AuthService _authService;

  // État réactif
  final Rx<MonPaysState> _state = MonPaysState().obs;
  MonPaysState get state => _state.value;

  // Getters pour faciliter l'accès dans les vues
  bool get isLoading => state.isLoading;
  String? get errorMessage => state.errorMessage;
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
  String get searchQuery => state.searchQuery;
  String? get selectedProvince => state.selectedProvince;
  String? get selectedCategory => state.selectedCategory;

  // Utilisateur courant pour le rôle
  User? get currentUser => _authService.currentUser;
  bool get isAdminOrModerator =>
      currentUser?.role == 'admin' || currentUser?.role == 'moderateur';

  MonPaysController(this._service, this._authService);

  @override
  void onInit() {
    super.onInit();
    loadAllData();
  }

  /// Charge toutes les données du module
  Future<void> loadAllData() async {
    _updateState(isLoading: true, errorMessage: null);
    try {
      final results = await Future.wait([
        _service.getAuthorities(),
        _service.getHistoricalFigures(),
        _service.getNews(),
        _service.getAgencies(),
        _service.getVideos(),
        _service.getDocumentaries(),
        _service.getWantedPersons(),
        _service.getExemplaryCitizens(),
        _service.getLaws(),
        _service.getConsultations(),
      ]);

      _updateState(
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
        isLoading: false,
      );
    } catch (e) {
      _updateState(
        isLoading: false,
        errorMessage: 'Erreur lors du chargement des données: $e',
      );
    }
  }

  /// Recherche globale (filtrage côté client ou appel API)
  void search(String query) {
    _updateState(searchQuery: query);
    // Ici on peut soit filtrer localement, soit relancer une requête API
    // Pour l'exemple, on garde les données et on filtre dans les sections
    // avec GetX .where dans les vues
  }

  /// Applique un filtre par province
  void filterByProvince(String? province) {
    _updateState(selectedProvince: province);
  }

  /// Applique un filtre par catégorie (ex: actualités)
  void filterByCategory(String? category) {
    _updateState(selectedCategory: category);
  }

  /// Rafraîchit les données
  Future<void> refreshData() => loadAllData();

  // Méthode utilitaire pour mettre à jour l'état
  void _updateState({
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
    _state.value = _state.value.copyWith(
      isLoading: isLoading,
      errorMessage: errorMessage,
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
      searchQuery: searchQuery,
      selectedProvince: selectedProvince,
      selectedCategory: selectedCategory,
    );
  }
}
