import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';

class DeliveryProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Adresses
  List<Map<String, dynamic>> _addresses = [];
  Map<String, dynamic>? _selectedAddress;
  bool _isLoadingAddresses = false;
  
  // Points relais
  List<Map<String, dynamic>> _pickupPoints = [];
  Map<String, dynamic>? _selectedPickupPoint;
  bool _isLoadingPickupPoints = false;
  
  // Créneaux
  List<Map<String, dynamic>> _availableSlots = [];
  Map<String, dynamic>? _selectedSlot;
  bool _isLoadingSlots = false;
  
  // Suivi
  Map<String, dynamic>? _currentTracking;
  bool _isLoadingTracking = false;
  
  // Position utilisateur
  Position? _currentPosition;
  bool _hasLocationPermission = false;

  // Getters
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
  
  Position? get currentPosition => _currentPosition;

  // Initialisation
  Future<void> init() async {
    await _requestLocationPermission();
    await getCurrentLocation();
    await loadAddresses();
  }

  Future<void> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    _hasLocationPermission = permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
    notifyListeners();
  }

  Future<void> getCurrentLocation() async {
    if (!_hasLocationPermission) return;
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  // Gestion des adresses
  Future<void> loadAddresses() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isLoadingAddresses = true);
    try {
      final response = await _supabase
          .from('addresses')
          .select()
          .eq('user_id', userId)
          .order('is_default', ascending: false);
      _addresses = List<Map<String, dynamic>>.from(response);
      
      // Sélectionner l'adresse par défaut si disponible
      if (_selectedAddress == null) {
        final defaultAddr = _addresses.firstWhere(
          (a) => a['is_default'] == true,
          orElse: () => {},
        );
        if (defaultAddr.isNotEmpty) _selectedAddress = defaultAddr;
      }
    } catch (e) {
      debugPrint('Error loading addresses: $e');
    } finally {
      setState(() => _isLoadingAddresses = false);
    }
  }

  Future<void> addAddress(Map<String, dynamic> address) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isLoadingAddresses = true);
    try {
      final response = await _supabase
          .from('addresses')
          .insert({
            ...address,
            'user_id': userId,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();
      _addresses.insert(0, response);
      _selectedAddress = response;
      notifyListeners();
    } catch (e) {
      rethrow;
    } finally {
      setState(() => _isLoadingAddresses = false);
    }
  }

  Future<void> updateAddress(String addressId, Map<String, dynamic> updates) async {
    setState(() => _isLoadingAddresses = true);
    try {
      final response = await _supabase
          .from('addresses')
          .update(updates)
          .eq('id', addressId)
          .select()
          .single();
      final index = _addresses.indexWhere((a) => a['id'] == addressId);
      if (index != -1) _addresses[index] = response;
      if (_selectedAddress?['id'] == addressId) _selectedAddress = response;
      notifyListeners();
    } finally {
      setState(() => _isLoadingAddresses = false);
    }
  }

  Future<void> deleteAddress(String addressId) async {
    setState(() => _isLoadingAddresses = true);
    try {
      await _supabase.from('addresses').delete().eq('id', addressId);
      _addresses.removeWhere((a) => a['id'] == addressId);
      if (_selectedAddress?['id'] == addressId) {
        _selectedAddress = _addresses.isNotEmpty ? _addresses.first : null;
      }
      notifyListeners();
    } finally {
      setState(() => _isLoadingAddresses = false);
    }
  }

  void selectAddress(Map<String, dynamic> address) {
    _selectedAddress = address;
    notifyListeners();
  }

  // Points relais
  Future<void> loadNearbyPickupPoints({double radiusKm = 10}) async {
    if (_currentPosition == null) {
      await getCurrentLocation();
    }
    if (_currentPosition == null) return;

    setState(() => _isLoadingPickupPoints = true);
    try {
      final response = await _supabase.rpc('nearby_pickup_points', params: {
        'lat': _currentPosition!.latitude,
        'lng': _currentPosition!.longitude,
        'radius_km': radiusKm,
      });
      _pickupPoints = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error loading pickup points: $e');
    } finally {
      setState(() => _isLoadingPickupPoints = false);
    }
  }

  void selectPickupPoint(Map<String, dynamic> point) {
    _selectedPickupPoint = point;
    notifyListeners();
  }

  // Créneaux de livraison
  Future<void> loadAvailableSlots({DateTime? date}) async {
    setState(() => _isLoadingSlots = true);
    try {
      final targetDate = date ?? DateTime.now().add(const Duration(days: 1));
      final response = await _supabase.rpc('get_available_delivery_slots', params: {
        'date': targetDate.toIso8601String(),
      });
      _availableSlots = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error loading slots: $e');
    } finally {
      setState(() => _isLoadingSlots = false);
    }
  }

  void selectSlot(Map<String, dynamic> slot) {
    _selectedSlot = slot;
    notifyListeners();
  }

  // Suivi de livraison
  Future<void> trackDelivery(String orderId) async {
    setState(() => _isLoadingTracking = true);
    try {
      final response = await _supabase
          .from('delivery_tracking')
          .select('''
            *,
            driver:drivers(name, phone, vehicle, current_lat, current_lng)
          ''')
          .eq('order_id', orderId)
          .single();
      _currentTracking = response;
    } catch (e) {
      debugPrint('Error tracking delivery: $e');
      _currentTracking = null;
    } finally {
      setState(() => _isLoadingTracking = false);
    }
  }

  // Estimation des frais de livraison
  Future<double> estimateShippingCost({
    required double addressLat,
    required double addressLng,
    required String method,
  }) async {
    if (_currentPosition == null) return 2500;
    try {
      final response = await _supabase.rpc('estimate_shipping_cost', params: {
        'origin_lat': _currentPosition!.latitude,
        'origin_lng': _currentPosition!.longitude,
        'dest_lat': addressLat,
        'dest_lng': addressLng,
        'method': method,
      });
      return (response as num?)?.toDouble() ?? 2500;
    } catch (e) {
      return 2500;
    }
  }

  void reset() {
    _selectedAddress = null;
    _selectedPickupPoint = null;
    _selectedSlot = null;
    _currentTracking = null;
    notifyListeners();
  }

  void setState(VoidCallback fn) {
    fn();
    notifyListeners();
  }
}
