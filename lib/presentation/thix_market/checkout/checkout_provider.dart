// lib/presentation/thix_market/checkout/checkout_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CheckoutProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = false;
  String? _errorMessage;
  String _currentStep = 'address';
  
  List<Map<String, dynamic>> _savedAddresses = [];
  Map<String, dynamic>? _selectedAddress;
  Map<String, dynamic>? _selectedShippingMethod;
  Map<String, dynamic>? _selectedPaymentMethod;
  Map<String, dynamic> _userInfo = {};

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get currentStep => _currentStep;
  List<Map<String, dynamic>> get savedAddresses => _savedAddresses;
  Map<String, dynamic>? get selectedAddress => _selectedAddress;
  Map<String, dynamic>? get selectedShippingMethod => _selectedShippingMethod;
  Map<String, dynamic>? get selectedPaymentMethod => _selectedPaymentMethod;

  Future<void> loadCheckoutData() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      _errorMessage = "Utilisateur non connecté.";
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Chargement en parallèle
      final results = await Future.wait([
        _supabase.from('addresses').select().eq('user_id', userId),
        _supabase.from('users').select('id, name, email, phone').eq('id', userId).maybeSingle()
      ]);

      _savedAddresses = List<Map<String, dynamic>>.from(results[0]);
      _userInfo = results[1] ?? {};
      _currentStep = 'address';
    } catch (e) {
      debugPrint('❌ Erreur critique Checkout: $e');
      _errorMessage = "Impossible de charger les données : ${e.toString()}";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectAddress(Map<String, dynamic> address) {
    _selectedAddress = address;
    _currentStep = 'shipping';
    notifyListeners();
  }
  
  // ... (Gardez vos autres méthodes processOrder et _processPayment ici)
}
