import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';

class DeliveryProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  // État des adresses
  List<Map<String, dynamic>> _addresses = [];
  Map<String, dynamic>? _selectedAddress;
  bool _isLoadingAddresses = false;

  // État du tracking
  Map<String, dynamic>? _currentTracking;
  bool _isLoadingTracking = false;
  String? _errorTracking;

  // Getters
  List<Map<String, dynamic>> get addresses => _addresses;
  Map<String, dynamic>? get selectedAddress => _selectedAddress;
  bool get isLoadingAddresses => _isLoadingAddresses;
  Map<String, dynamic>? get currentTracking => _currentTracking;
  bool get isLoadingTracking => _isLoadingTracking;
  String? get errorTracking => _errorTracking;

  // --- TRACKING (Version sécurisée) ---
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

  // --- GESTION ADRESSES (Méthodes manquantes nécessaires au build) ---
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

  Future<void> addAddress(Map<String, dynamic> address) async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final res = await _supabase.from('addresses').insert({...address, 'user_id': uid}).select().single();
      _addresses.insert(0, res);
      notifyListeners();
    } catch (e) { debugPrint('Error adding address: $e'); }
  }

  Future<void> deleteAddress(String addressId) async {
    try {
      await _supabase.from('addresses').delete().eq('id', addressId);
      _addresses.removeWhere((a) => a['id'] == addressId);
      notifyListeners();
    } catch (e) { debugPrint('Error deleting address: $e'); }
  }

  Future<void> updateAddress(String id, Map<String, dynamic> data) async {
    try {
      await _supabase.from('addresses').update(data).eq('id', id);
      await loadAddresses();
    } catch (e) { debugPrint('Error updating address: $e'); }
  }

  void selectAddress(Map<String, dynamic> a) { _selectedAddress = a; notifyListeners(); }

  // --- AUTRES HELPERS ---
  Future<void> init() async { await loadAddresses(); }
  void reset() { _selectedAddress = null; _currentTracking = null; notifyListeners(); }
}
