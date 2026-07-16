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
  Position? get currentPosition => _currentPosition;

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

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

  Future<void> loadAddresses() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    _isLoadingAddresses = true;
    notifyListeners();
    try {
      final response = await _supabase.from('addresses').select().eq('user_id', userId).order('is_default', ascending: false);
      _addresses = List<Map<String, dynamic>>.from(response);
      if (_selectedAddress == null && _addresses.isNotEmpty) {
        final def = _addresses.where((a) => a['is_default'] == true);
        _selectedAddress = def.isNotEmpty? def.first : _addresses.first;
      }
    } catch (e) {
      debugPrint('Error loading addresses: $e');
    } finally {
      _isLoadingAddresses = false;
      notifyListeners();
    }
  }

  // Ajoute ceci à l'intérieur de ta classe DeliveryProvider
  
  // Méthode pour supprimer une adresse
  Future<void> deleteAddress(String addressId) async {
    try {
      await Supabase.instance.client
          .from('addresses')
          .delete()
          .eq('id', addressId);
      
      // Recharge la liste après suppression
      await loadAddresses(); 
    } catch (e) {
      debugPrint('Erreur suppression adresse : $e');
      rethrow;
    }
  }

  // Méthode pour mettre à jour une adresse
  Future<void> updateAddress(String addressId, Map<String, dynamic> data) async {
    try {
      await Supabase.instance.client
          .from('addresses')
          .update(data)
          .eq('id', addressId);
      
      // Recharge la liste après mise à jour
      await loadAddresses();
    } catch (e) {
      debugPrint('Erreur mise à jour adresse : $e');
      rethrow;
    }
  }

  Future<void> addAddress(Map<String, dynamic> address) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    _isLoadingAddresses = true; notifyListeners();
    try {
      final response = await _supabase.from('addresses').insert({...address, 'user_id': userId, 'created_at': DateTime.now().toIso8601String()}).select().single();
      _addresses.insert(0, response);
      _selectedAddress = response;
    } finally {
      _isLoadingAddresses = false; notifyListeners();
    }
  }

  void selectAddress(Map<String, dynamic> address) {
    _selectedAddress = address; notifyListeners();
  }

  Future<void> loadNearbyPickupPoints({double radiusKm = 10}) async {
    if (_currentPosition == null) await getCurrentLocation();
    if (_currentPosition == null) return;
    _isLoadingPickupPoints = true; notifyListeners();
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
      _isLoadingPickupPoints = false; notifyListeners();
    }
  }

  void selectPickupPoint(Map<String, dynamic> point) { _selectedPickupPoint = point; notifyListeners(); }

  Future<void> loadAvailableSlots({DateTime? date}) async {
    _isLoadingSlots = true; notifyListeners();
    try {
      final targetDate = date?? DateTime.now().add(const Duration(days: 1));
      final response = await _supabase.rpc('get_available_delivery_slots', params: {'date': targetDate.toIso8601String()});
      _availableSlots = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error loading slots: $e');
    } finally {
      _isLoadingSlots = false; notifyListeners();
    }
  }

  void selectSlot(Map<String, dynamic> slot) { _selectedSlot = slot; notifyListeners(); }

  Future<void> trackDelivery(String orderId) async {
    _isLoadingTracking = true;
    _errorTracking = null;
    notifyListeners();
    try {
      final response = await _supabase
         .from('delivery_tracking')
         .select('*, driver:drivers(name, phone, vehicle, current_lat, current_lng)')
         .eq('order_id', orderId)
         .maybeSingle(); // FIX: ne throw plus si pas trouvé
      _currentTracking = response;
    } catch (e, s) {
      debugPrint('Error tracking delivery: $e\n$s');
      _errorTracking = e.toString();
      _currentTracking = null;
    } finally {
      _isLoadingTracking = false;
      notifyListeners();
    }
  }

  Future<double> estimateShippingCost({required double addressLat, required double addressLng, required String method}) async {
    if (_currentPosition == null) return 2500;
    try {
      final response = await _supabase.rpc('estimate_shipping_cost', params: {
        'origin_lat': _currentPosition!.latitude,
        'origin_lng': _currentPosition!.longitude,
        'dest_lat': addressLat, 'dest_lng': addressLng, 'method': method,
      });
      return (response as num?)?.toDouble()?? 2500;
    } catch (e) { return 2500; }
  }

  void reset() {
    _selectedAddress = null; _selectedPickupPoint = null; _selectedSlot = null; _currentTracking = null; _errorTracking = null;
    notifyListeners();
  }
}
