import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';

class DeliveryProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _addresses = [];
  Map<String, dynamic>? _selectedAddress;
  bool _isLoadingAddresses = false;

  List<Map<String, dynamic>> _pickupPoints = [];
  Map<String, dynamic>? _selectedPickupPoint;
  bool _isLoadingPickupPoints = false;

  List<Map<String, dynamic>> _availableSlots = [];
  Map<String, dynamic>? _selectedSlot;
  bool _isLoadingSlots = false;

  Map<String, dynamic>? _currentTracking;
  bool _isLoadingTracking = false;
  String? _errorTracking;

  Position? _currentPosition;
  bool _hasLocationPermission = false;

  List<Map<String, dynamic>> get addresses => _addresses;
  Map<String, dynamic>? get selectedAddress => _selectedAddress;
  bool get isLoadingAddresses => _isLoadingAddresses;
  List<Map<String, dynamic>> get pickupPoints => _pickupPoints;
  Map<String, dynamic>? get selectedPickupPoint => _selectedPickupPoint;
  bool get isLoadingPickupPoints => _isLoadingPickupPoints;
  List<Map<String, dynamic>> get availableSlots => _availableSlots;
  Map<String, dynamic>? get selectedSlot => _selectedSlot;
  bool get isLoadingSlots => _isLoadingSlots;
  Map<String, dynamic>? get currentTracking => _currentTracking;
  bool get isLoadingTracking => _isLoadingTracking;
  String? get errorTracking => _errorTracking;

  // --- CETTE METHODE EST LA SEULE QUI COMPTE POUR TON BUG ---
  Future<void> trackDelivery(String orderId) async {
    _isLoadingTracking = true;
    _errorTracking = null;
    notifyListeners();
    try {
      final tracking = await _supabase
          .from('delivery_tracking')
          .select()
          .eq('order_id', orderId)
          .maybeSingle();

      if (tracking == null) {
        _currentTracking = null;
      } else {
        _currentTracking = {
          ...tracking,
          'driver': {
            'name': tracking['driver_name'] ?? 'Livreur THIX',
            'phone': tracking['driver_phone'] ?? '',
            'vehicle': tracking['vehicle'] ?? 'Moto',
            'current_lat': tracking['current_lat'],
            'current_lng': tracking['current_lng'],
          }
        };
      }
    } catch (e) {
      _errorTracking = e.toString();
      _currentTracking = null;
    } finally {
      _isLoadingTracking = false;
      notifyListeners();
    }
  }

  // --- LE RESTE NE CHANGE PAS ---
  Future<void> _requestLocationPermission() async {
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
    _hasLocationPermission = p == LocationPermission.always || p == LocationPermission.whileInUse;
  }

  Future<void> getCurrentLocation() async {
    if (!_hasLocationPermission) await _requestLocationPermission();
    try {
      _currentPosition = await Geolocator.getCurrentPosition();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadAddresses() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;
    _isLoadingAddresses = true; notifyListeners();
    try {
      final res = await _supabase.from('addresses').select().eq('user_id', uid);
      _addresses = List<Map<String, dynamic>>.from(res);
    } finally {
      _isLoadingAddresses = false; notifyListeners();
    }
  }
  void selectAddress(Map<String, dynamic> a){ _selectedAddress=a; notifyListeners(); }
  Future<void> loadNearbyPickupPoints({double radiusKm=10}) async {}
  void selectPickupPoint(Map<String, dynamic> p){ _selectedPickupPoint=p; notifyListeners(); }
  Future<void> loadAvailableSlots({DateTime? date}) async {}
  void selectSlot(Map<String, dynamic> s){ _selectedSlot=s; notifyListeners(); }
  Future<double> estimateShippingCost({required double addressLat, required double addressLng, required String method}) async => 2500;
  void reset(){ _selectedAddress=null; _selectedPickupPoint=null; _selectedSlot=null; _currentTracking=null; notifyListeners(); }
}
