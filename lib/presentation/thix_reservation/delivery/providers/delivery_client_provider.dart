// ================================================================
// CHEMIN: lib/presentation/thix_reservation/delivery/providers/delivery_client_provider.dart
// ROLE: Provider UNIQUE côté client - Fusion de 4 providers
//       Gère Home + Form + Create + Tracking + History
//       C'est le cerveau de toute la partie CLIENT
// SCALABLE: ChangeNotifier + pagination + cache + debounce
// ================================================================

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/delivery_models.dart';
import '../data/delivery_service.dart';

class DeliveryClientProvider extends ChangeNotifier {
  // --- Dépendances Supabase direct ---
  final _supa = Supabase.instance.client;
  final _service = DeliveryService();

  // --- ETATS HOME ---
  bool isLoading = true;
  String userName = "Michel";
  bool isAdmin = false; // Pour afficher bouton Admin sur Home
  List<DeliveryRoute> popularRoutes = [];
  List<DeliveryOffer> offers = [];
  String? error;

  // --- ETATS FORMULAIRE ENVOI COLIS ---
  // Valeurs du formulaire de ta maquette
  bool isNational = true; // National / International
  String fromCity = "Abidjan, Côte d'Ivoire";
  String toCity = "Yamoussoukro, Côte d'Ivoire";
  ParcelType parcelType = ParcelType.other;
  int weightKg = 3; // 0-5kg par défaut
  DeliveryMode deliveryMode = DeliveryMode.standard;
  int calculatedPrice = 0; // Prix calculé depuis delivery_routes
  bool isCalculating = false;

  // --- ETATS TRACKING ---
  DeliveryShipment? trackedShipment;
  List<TrackingEvent> trackingEvents = [];
  bool isTracking = false;

  // --- ETATS HISTORY (pagination pour 1M users) ---
  List<DeliveryShipment> myShipments = [];
  bool isLoadingHistory = false;
  bool hasMoreHistory = true;
  int _historyPage = 0;
  static const _pageSize = 20;

  // --------------------------------------------------------------
  // INIT - Appelé au lancement de delivery_home_page.dart
  // --------------------------------------------------------------
  Future<void> init() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      // On lance 3 requêtes en parallèle pour gagner du temps
      await Future.wait([
        _loadUserInfo(),
        _loadPopularRoutes(),
        _loadOffers(),
      ]);

      // Calcul initial du prix pour Abidjan -> Yakro
      await calculatePrice();
    } catch (e) {
      error = e.toString();
      debugPrint("DELIVERY INIT ERROR: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // --------------------------------------------------------------
  // 1. USER + CHECK ADMIN
  // --------------------------------------------------------------
  Future<void> _loadUserInfo() async {
    try {
      final user = _supa.auth.currentUser;
      if (user == null) return;

      // On récupère le profil + on check si admin en même temps
      final results = await Future.wait([
        _supa.from('profiles').select('full_name').eq('id', user.id).maybeSingle(),
        _service.isUserAdmin(),
      ]);

      final profile = results[0] as Map<String, dynamic>?;
      isAdmin = results[1] as bool;

      // On extrait juste le prénom pour "Bonjour, Michel"
      if (profile != null && profile['full_name'] != null) {
        final fullName = profile['full_name'] as String;
        userName = fullName.split(' ').first;
      }
    } catch (e) {
      debugPrint("LOAD USER ERROR: $e");
      // On ne bloque pas si ça échoue
    }
  }

  // --------------------------------------------------------------
  // 2. POPULAR ROUTES - Pour pré-remplir les villes
  // --------------------------------------------------------------
  Future<void> _loadPopularRoutes() async {
    try {
      popularRoutes = await _service.getActiveRoutes();
    } catch (e) {
      debugPrint("LOAD ROUTES ERROR: $e");
    }
  }

  // --------------------------------------------------------------
  // 3. OFFRES DU MOMENT - Section -20% -15%
  // --------------------------------------------------------------
  Future<void> _loadOffers() async {
    try {
      offers = await _service.getOffers();
    } catch (e) {
      debugPrint("LOAD OFFERS ERROR: $e");
    }
  }

  // --------------------------------------------------------------
  // 4. CALCUL PRIX - Le coeur de ta maquette
  //    Bouton "Calculer le prix et continuer"
  // --------------------------------------------------------------
  Future<void> calculatePrice() async {
    isCalculating = true;
    notifyListeners();

    try {
      // Nettoyage des villes pour recherche (enlève ", Côte d'Ivoire")
      final from = fromCity.split(',').first.trim();
      final to = toCity.split(',').first.trim();

      // Recherche du trajet dans cache ou Supabase
      final route = await _service.findRoute(from, to);

      if (route != null) {
        // --- Calcul réel depuis table delivery_routes ---
        // Ex: Abidjan->Yakro base 3000 + si 8kg => 3000 + 3*500 = 4500
        calculatedPrice = route.calculatePrice(weightKg: weightKg, mode: deliveryMode);
      } else {
        // Fallback si trajet pas trouvé (pas d'offre)
        calculatedPrice = 0;
      }
    } catch (e) {
      calculatedPrice = 0;
      debugPrint("CALC PRICE ERROR: $e");
    } finally {
      isCalculating = false;
      notifyListeners();
    }
  }

  // Setters du formulaire qui recalculent auto le prix
  void setFromCity(String city) {
    fromCity = city;
    calculatePrice(); // Recalcul auto
  }

  void setToCity(String city) {
    toCity = city;
    calculatePrice();
  }

  void setWeight(int kg) {
    weightKg = kg;
    calculatePrice();
  }

  void setMode(DeliveryMode mode) {
    deliveryMode = mode;
    calculatePrice();
  }

  void setType(ParcelType type) {
    parcelType = type;
    notifyListeners();
  }

  void setNational(bool value) {
    isNational = value;
    notifyListeners();
  }

  void swapCities() {
    // Bouton swap de ta maquette
    final tmp = fromCity;
    fromCity = toCity;
    toCity = tmp;
    calculatePrice();
  }

  // --------------------------------------------------------------
  // 5. CREATION COLIS - Après paiement
  // --------------------------------------------------------------
  Future<String> createShipment({
    required String receiverName,
    required String receiverPhone,
    required String receiverAddress,
    required String senderAddress,
  }) async {
    final user = _supa.auth.currentUser;
    if (user == null) throw Exception("Non connecté");

    // Génération code tracking unique THX-XXXXXX
    final trackingCode = "THX-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}";

    final data = await _supa.from('delivery_shipments').insert({
      'tracking_code': trackingCode,
      'sender_id': user.id,
      'from_city': fromCity.split(',').first.trim(),
      'to_city': toCity.split(',').first.trim(),
      'sender_address': senderAddress,
      'receiver_name': receiverName,
      'receiver_phone': receiverPhone,
      'receiver_address': receiverAddress,
      'parcel_type': parcelType.name,
      'weight_kg': weightKg,
      'delivery_mode': deliveryMode.name,
      'price': calculatedPrice,
      'status': 'pending',
    }).select('id').single();

    // On crée premier event tracking
    await _supa.from('delivery_tracking_events').insert({
      'shipment_id': data['id'],
      'status': 'pending',
      'location': fromCity,
      'description': 'Colis enregistré, en attente de ramassage',
    });

    // Reset pagination history
    _historyPage = 0;
    myShipments.clear();

    return trackingCode;
  }

  // --------------------------------------------------------------
  // 6. TRACKING par code THX-XXXXXX
  // --------------------------------------------------------------
  Future<void> trackByCode(String code) async {
    isTracking = true;
    trackedShipment = null;
    trackingEvents.clear();
    notifyListeners();

    try {
      final shipmentData = await _supa.from('delivery_shipments').select().eq('tracking_code', code.trim().toUpperCase()).maybeSingle();
      
      if (shipmentData == null) throw Exception("Code introuvable");

      trackedShipment = DeliveryShipment.fromJson(shipmentData);

      final eventsData = await _supa.from('delivery_tracking_events').select().eq('shipment_id', trackedShipment!.id).order('created_at', ascending: false);
      trackingEvents = (eventsData as List).map((e) => TrackingEvent.fromJson(e)).toList();
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isTracking = false;
      notifyListeners();
    }
  }

  // --------------------------------------------------------------
  // 7. HISTORY avec pagination (CRITIQUE pour 1M users)
  // --------------------------------------------------------------
  Future<void> loadMyShipments({bool refresh = false}) async {
    if (refresh) {
      _historyPage = 0;
      myShipments.clear();
      hasMoreHistory = true;
    }

    if (isLoadingHistory || !hasMoreHistory) return;

    isLoadingHistory = true;
    notifyListeners();

    try {
      final user = _supa.auth.currentUser;
      if (user == null) return;

      final from = _historyPage * _pageSize;
      final to = from + _pageSize - 1;

      final data = await _supa.from('delivery_shipments').select().eq('sender_id', user.id).order('created_at', ascending: false).range(from, to);

      final list = (data as List).map((e) => DeliveryShipment.fromJson(e)).toList();

      if (refresh) myShipments = list;
      else myShipments.addAll(list);

      hasMoreHistory = list.length == _pageSize;
      _historyPage++;
    } catch (e) {
      debugPrint("HISTORY ERROR: $e");
    } finally {
      isLoadingHistory = false;
      notifyListeners();
    }
  }
}
