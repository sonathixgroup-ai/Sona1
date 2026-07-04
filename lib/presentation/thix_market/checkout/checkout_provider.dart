import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../cart/cart_provider.dart';

class CheckoutProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // États du checkout
  bool _isLoading = false;
  bool _isProcessing = false;
  String _currentStep = 'address'; // address, shipping, payment, confirmation
  
  // Données utilisateur
  List<Map<String, dynamic>> _savedAddresses = [];
  Map<String, dynamic>? _selectedAddress;
  Map<String, dynamic>? _selectedShippingMethod;
  Map<String, dynamic>? _selectedPaymentMethod;
  
  // Infos utilisateur
  Map<String, dynamic> _userInfo = {};
  
  // Résultat commande
  Map<String, dynamic>? _createdOrder;
  String? _paymentIntentId;
  String? _paymentUrl;

  // Getters
  bool get isLoading => _isLoading;
  bool get isProcessing => _isProcessing;
  String get currentStep => _currentStep;
  List<Map<String, dynamic>> get savedAddresses => _savedAddresses;
  Map<String, dynamic>? get selectedAddress => _selectedAddress;
  Map<String, dynamic>? get selectedShippingMethod => _selectedShippingMethod;
  Map<String, dynamic>? get selectedPaymentMethod => _selectedPaymentMethod;
  Map<String, dynamic> get userInfo => _userInfo;
  Map<String, dynamic>? get createdOrder => _createdOrder;

  // Charger les données initiales
  Future<void> loadCheckoutData() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Utilisateur non connecté');

    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _loadUserInfo(userId),
        _loadSavedAddresses(userId),
      ]);
      _currentStep = 'address';
    } catch (e) {
      rethrow;
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUserInfo(String userId) async {
    final response = await _supabase
        .from('users')
        .select('id, name, email, phone, default_address_id')
        .eq('id', userId)
        .single();
    _userInfo = response;
    
    if (_userInfo['default_address_id'] != null) {
      _selectedAddress = _savedAddresses.firstWhere(
        (a) => a['id'] == _userInfo['default_address_id'],
        orElse: () => {},
      );
    }
    notifyListeners();
  }

  Future<void> _loadSavedAddresses(String userId) async {
    final response = await _supabase
        .from('addresses')
        .select()
        .eq('user_id', userId)
        .order('is_default', ascending: false);
    _savedAddresses = List<Map<String, dynamic>>.from(response);
    notifyListeners();
  }

  // Gestion des adresses
  void selectAddress(Map<String, dynamic> address) {
    _selectedAddress = address;
    _currentStep = 'shipping';
    notifyListeners();
  }

  Future<void> addAddress(Map<String, dynamic> newAddress) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('addresses')
          .insert({
            ...newAddress,
            'user_id': userId,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();
      _savedAddresses.insert(0, response);
      _selectedAddress = response;
      notifyListeners();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Gestion livraison
  void selectShippingMethod(Map<String, dynamic> method) {
    _selectedShippingMethod = method;
    _currentStep = 'payment';
    notifyListeners();
  }

  // Gestion paiement
  void selectPaymentMethod(Map<String, dynamic> method) {
    _selectedPaymentMethod = method;
    _currentStep = 'confirmation';
    notifyListeners();
  }

  // Création de la commande et traitement paiement
  Future<Map<String, dynamic>> processOrder({
    required CartProvider cartProvider,
    required double total,
    required List<Map<String, dynamic>> items,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Non connecté');
    if (_selectedAddress == null) throw Exception('Adresse requise');
    if (_selectedShippingMethod == null) throw Exception('Mode de livraison requis');
    if (_selectedPaymentMethod == null) throw Exception('Moyen de paiement requis');

    setState(() => _isProcessing = true);

    try {
      // 1. Créer la commande
      final orderData = {
        'user_id': userId,
        'address_id': _selectedAddress!['id'],
        'shipping_method': _selectedShippingMethod!['id'],
        'shipping_cost': _selectedShippingMethod!['price'],
        'total': total,
        'status': 'pending',
        'payment_status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      };
      final orderResponse = await _supabase
          .from('orders')
          .insert(orderData)
          .select()
          .single();
      _createdOrder = orderResponse;

      // 2. Ajouter les articles de la commande
      for (var item in items) {
        await _supabase.from('order_items').insert({
          'order_id': _createdOrder!['id'],
          'product_id': item['product_id'],
          'quantity': item['quantity'],
          'price': item['price'],
          'product_name': item['product_name'],
          'product_image': item['image_url'],
        });
      }

      // 3. Traitement du paiement selon méthode
      final paymentResult = await _processPayment(total);

      if (paymentResult['success'] == true) {
        // Mettre à jour statut commande
        await _supabase
            .from('orders')
            .update({
              'payment_status': 'paid',
              'status': 'processing',
              'paid_at': DateTime.now().toIso8601String(),
            })
            .eq('id', _createdOrder!['id']);
        
        // Vider le panier
        await cartProvider.clearCart();
        
        return _createdOrder!;
      } else {
        throw Exception(paymentResult['error'] ?? 'Paiement échoué');
      }
    } catch (e) {
      rethrow;
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<Map<String, dynamic>> _processPayment(double amount) async {
    final method = _selectedPaymentMethod!['id'];
    
    switch (method) {
      case 'card':
        // Appel à Stripe (via Edge Function)
        final response = await _supabase.functions.invoke('create-payment-intent', body: {
          'amount': amount,
          'currency': 'XOF',
          'order_id': _createdOrder!['id'],
        });
        _paymentIntentId = response.data['payment_intent_id'];
        return {'success': true, 'payment_intent_id': _paymentIntentId};
        
      case 'mobile_money':
        // Appel API Mobile Money
        final response = await _supabase.functions.invoke('mobile-money-payment', body: {
          'amount': amount,
          'phone': _userInfo['phone'],
          'order_id': _createdOrder!['id'],
        });
        _paymentUrl = response.data['payment_url'];
        return {'success': true, 'payment_url': _paymentUrl};
        
      case 'thix_money':
        // Paiement via wallet interne
        final response = await _supabase.rpc('deduct_wallet_balance', params: {
          'user_id': _supabase.auth.currentUser!.id,
          'amount': amount,
        });
        if (response == true) {
          return {'success': true};
        } else {
          return {'success': false, 'error': 'Solde insuffisant'};
        }
        
      default:
        return {'success': false, 'error': 'Méthode de paiement inconnue'};
    }
  }

  void reset() {
    _currentStep = 'address';
    _selectedAddress = null;
    _selectedShippingMethod = null;
    _selectedPaymentMethod = null;
    _createdOrder = null;
    notifyListeners();
  }

  void setState(VoidCallback fn) {
    fn();
    notifyListeners();
  }
}
