// lib/presentation/thix_reservation/delivery/providers/delivery_client_provider.dart
// FULL - ADMIN DRIVEN - COMPAT HISTORY + TRACKING
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/delivery_models.dart';
import '../data/delivery_service.dart';

class DeliveryClientProvider extends ChangeNotifier {
  final _supa = Supabase.instance.client;
  final _service = DeliveryService();

  bool isLoading = true;
  bool isCalculating = false;
  bool isLoadingHistory = false;
  bool hasMoreHistory = false;
  bool isNational = true;

  String userName = "";
  String fromCity = "";
  String toCity = "";
  int weightKg = 1;
  DeliveryMode deliveryMode = DeliveryMode.standard;

  int calculatedPrice = 0;
  List<DeliveryRoute> popularRoutes = [];
  List<DeliveryOffer> offers = [];
  List<DeliveryShipment> myShipments = [];
  
  DeliveryShipment? trackedShipment;
  List<DeliveryTrackingEvent> trackingEvents = [];

  DeliveryRoute? selectedRoute;

  Future<void> init() async {
    isLoading = true;
    notifyListeners();
    try {
      userName = _supa.auth.currentUser?.userMetadata?['full_name']?? "";
      await Future.wait([
        loadRoutes(),
        loadOffers(),
        loadMyShipments(),
      ]);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadRoutes({bool force = true}) async {
    try {
      popularRoutes = await _service.getActiveRoutes(forceRefresh: force);
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

  Future<void> loadMyShipments({bool refresh = false}) async {
    isLoadingHistory = true;
    if(refresh) myShipments = [];
    notifyListeners();
    try {
      final user = _supa.auth.currentUser;
      if (user == null) return;
      final data = await _supa.from('delivery_shipments').select().eq('sender_id', user.id).order('created_at', ascending: false).limit(50);
      myShipments = (data as List).map((e) => DeliveryShipment.fromJson(e)).toList();
      hasMoreHistory = false;
    } catch (e) {
      debugPrint("LOAD MY SHIPMENTS ERROR: $e");
    } finally {
      isLoadingHistory = false;
      notifyListeners();
    }
  }

  Future<void> trackShipment(String shipmentId) async {
    try {
      final shipData = await _supa.from('delivery_shipments').select().eq('id', shipmentId).single();
      trackedShipment = DeliveryShipment.fromJson(shipData);
      
      final eventsData = await _supa.from('delivery_tracking_events').select().eq('shipment_id', shipmentId).order('created_at', ascending: true);
      trackingEvents = (eventsData as List).map((e) => DeliveryTrackingEvent.fromJson(e)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint("TRACK ERROR: $e");
    }
  }

  void setNational(bool v) { isNational = v; _recalculate(); notifyListeners(); }
  void setFromCity(String v) { fromCity = v.trim().toUpperCase(); _recalculate(); notifyListeners(); }
  void setToCity(String v) { toCity = v.trim().toUpperCase(); _recalculate(); notifyListeners(); }
  void swapCities() { final tmp = fromCity; fromCity = toCity; toCity = tmp; _recalculate(); notifyListeners(); }
  void setWeight(int w) { weightKg = w; _recalculate(); notifyListeners(); }
  void setMode(DeliveryMode m) { deliveryMode = m; _recalculate(); notifyListeners(); }

  void _recalculate() {
    calculatedPrice = 0;
    selectedRoute = null;
    if (fromCity.isEmpty || toCity.isEmpty) return;
    try {
      selectedRoute = popularRoutes.firstWhere(
        (r) => r.fromCity.toUpperCase() == fromCity.toUpperCase() &&
               r.toCity.toUpperCase() == toCity.toUpperCase(),
      );
      calculatedPrice = selectedRoute!.calculatePrice(weightKg: weightKg, mode: deliveryMode);
    } catch (_) {
      calculatedPrice = 0;
    }
  }
}

// Petit model si pas dans delivery_models.dart
class DeliveryTrackingEvent {
  final String status;
  final String location;
  final String description;
  final DateTime date;
  DeliveryTrackingEvent({required this.status, required this.location, required this.description, required this.date});
  factory DeliveryTrackingEvent.fromJson(Map<String,dynamic> j) => DeliveryTrackingEvent(
    status: j['status']??'',
    location: j['location']??'',
    description: j['description']??'',
    date: DateTime.tryParse(j['created_at']??'')??DateTime.now(),
  );
}
