// lib/presentation/thix_reservation/delivery/providers/delivery_client_provider.dart
// 100% ADMIN-DRIVEN - PAS DE MOCK
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/delivery_models.dart';
import '../data/delivery_service.dart';

class DeliveryClientProvider extends ChangeNotifier {
  final _supa = Supabase.instance.client;
  final _service = DeliveryService();

  bool isLoading = true;
  bool isCalculating = false;
  bool isNational = true;

  String userName = "";
  String fromCity = "";
  String toCity = "";
  int weightKg = 1;
  DeliveryMode deliveryMode = DeliveryMode.standard;

  int calculatedPrice = 0;
  List<DeliveryRoute> popularRoutes = [];
  List<DeliveryOffer> offers = [];
  DeliveryRoute? selectedRoute;

  Future<void> init() async {
    isLoading = true;
    notifyListeners();
    try {
      userName = _supa.auth.currentUser?.userMetadata?['full_name']?? "";
      // FORCE REFRESH pour récupérer les routes créées par l'admin
      await Future.wait([
        loadRoutes(),
        loadOffers(),
      ]);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadRoutes() async {
    try {
      // On force le refresh pour ne pas avoir le cache vide
      popularRoutes = await _service.getActiveRoutes(forceRefresh: true);
      // Filtre national / international selon toggle
      _applyNationalFilter();
      _recalculate();
    } catch (e) {
      debugPrint("CLIENT LOAD ROUTES ERROR: $e");
    }
  }

  Future<void> loadOffers() async {
    try {
      final data = await _supa.from('delivery_offers').select().eq('is_active', true);
      offers = (data as List).map((e) => DeliveryOffer.fromJson(e)).toList();
    } catch (e) {
      debugPrint("LOAD OFFERS ERROR: $e");
    }
  }

  void setNational(bool v) {
    isNational = v;
    _applyNationalFilter();
    _recalculate();
    notifyListeners();
  }

  void _applyNationalFilter() {
    // On garde en mémoire toutes les routes, pas de filtre dur ici
    // Le calcul se fera sur la route exacte
  }

  void setFromCity(String v) {
    fromCity = v.trim().toUpperCase();
    _recalculate();
    notifyListeners();
  }

  void setToCity(String v) {
    toCity = v.trim().toUpperCase();
    _recalculate();
    notifyListeners();
  }

  void swapCities() {
    final tmp = fromCity;
    fromCity = toCity;
    toCity = tmp;
    _recalculate();
    notifyListeners();
  }

  void setWeight(int w) {
    weightKg = w;
    _recalculate();
    notifyListeners();
  }

  void setMode(DeliveryMode m) {
    deliveryMode = m;
    _recalculate();
    notifyListeners();
  }

  void _recalculate() {
    calculatedPrice = 0;
    selectedRoute = null;
    if (fromCity.isEmpty || toCity.isEmpty) return;

    // Cherche la route exacte créée par l'admin (insensible à la casse)
    try {
      selectedRoute = popularRoutes.firstWhere(
        (r) => r.fromCity.toUpperCase() == fromCity.toUpperCase() &&
               r.toCity.toUpperCase() == toCity.toUpperCase(),
      );
      calculatedPrice = selectedRoute!.calculatePrice(weightKg: weightKg, mode: deliveryMode);
    } catch (_) {
      // Aucune route admin = prix 0 -> le bouton dira "Trajet non tarifé"
      calculatedPrice = 0;
    }
  }
}
