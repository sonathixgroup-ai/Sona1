// lib/presentation/thix_market/checkout/checkout_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/presentation/thix_market/cart/cart_provider.dart';

class CheckoutProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = false;
  bool _isProcessing = false;
  String _currentStep = 'address';
  List<Map<String, dynamic>> _savedAddresses = [];
  Map<String, dynamic>? _selectedAddress;
  Map<String, dynamic>? _selectedShippingMethod;
  Map<String, dynamic>? _selectedPaymentMethod;
  Map<String, dynamic> _userInfo = {};
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

  // ─── CHARGEMENT DES DONNÉES ───
  Future<void> loadCheckoutData() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      // Si l'utilisateur n'est pas connecté, on peut soit lever une exception,
      // soit initialiser avec des données vides. Ici on lève une exception explicite.
      throw Exception('Utilisateur non connecté');
    }

    _isLoading = true;
    notifyListeners();

    try {
      await Future.wait([
        _loadSavedAddresses(userId),
        _loadUserInfo(userId),
      ]);
      // Si aucune adresse n'est sélectionnée, on prend la première par défaut
      if (_selectedAddress == null && _savedAddresses.isNotEmpty) {
        _selectedAddress = _savedAddresses.first;
      }
      _currentStep = 'address';
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
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
    // Pas de notify ici car on est dans un Future.wait global
  }

  Future<void> _loadSavedAddresses(String userId) async {
    final response = await _supabase
        .from('addresses')
        .select()
        .eq('user_id', userId)
        .order('is_default', ascending: false); // true en premier
    _savedAddresses = List<Map<String, dynamic>>.from(response);
    // Pas de notify ici
  }

  // ─── SÉLECTION D'ADRESSE ───
  void selectAddress(Map<String, dynamic> address) {
    _selectedAddress = address;
    _currentStep = 'shipping';
    notifyListeners();
  }

  // ─── AJOUT D'ADRESSE ───
  Future<void> addAddress(Map<String, dynamic> newAddress) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    _isLoading = true;
    notifyListeners();
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
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── SÉLECTION DU MODE DE LIVRAISON ───
  void selectShippingMethod(Map<String, dynamic> method) {
    _selectedShippingMethod = method;
    _currentStep = 'payment';
    notifyListeners();
  }

  // ─── SÉLECTION DU MOYEN DE PAIEMENT ───
  void selectPaymentMethod(Map<String, dynamic> method) {
    _selectedPaymentMethod = method;
    _currentStep = 'confirmation';
    notifyListeners();
  }

  // ─── TRAITEMENT DE LA COMMANDE ───
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

    _isProcessing = true;
    notifyListeners();

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

      // 3. Traiter le paiement
      final paymentResult = await _processPayment(total);

      if (paymentResult['success'] == true) {
        // 4. Mettre à jour la commande
        await _supabase
            .from('orders')
            .update({
              'payment_status': 'paid',
              'status': 'processing',
              'paid_at': DateTime.now().toIso8601String(),
            })
            .eq('id', _createdOrder!['id']);

        // 5. Vider le panier
        await cartProvider.clearCart();

        // 6. Retourner la commande mise à jour
        final updatedOrder = await _supabase
            .from('orders')
            .select()
            .eq('id', _createdOrder!['id'])
            .single();
        _createdOrder = updatedOrder;
        return _createdOrder!;
      } else {
        // Paiement échoué : on peut annuler la commande ou la laisser en pending
        // Ici on laisse en pending, mais on pourrait la supprimer.
        throw Exception(paymentResult['error'] ?? 'Paiement échoué');
      }
    } catch (e) {
      debugPrint('❌ Checkout error: $e');
      // En cas d'erreur, on peut supprimer la commande pour éviter les orphelins
      if (_createdOrder != null) {
        try {
          await _supabase
              .from('orders')
              .delete()
              .eq('id', _createdOrder!['id']);
        } catch (_) {}
        _createdOrder = null;
      }
      rethrow;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  // ─── TRAITEMENT DU PAIEMENT ───
  Future<Map<String, dynamic>> _processPayment(double amount) async {
    final method = _selectedPaymentMethod!['id'];

    switch (method) {
      case 'card':
        try {
          final response = await _supabase.functions.invoke(
            'create-payment-intent',
            body: {
              'amount': amount,
              'currency': 'XOF',
              'order_id': _createdOrder!['id'],
            },
          );
          _paymentIntentId = response.data['payment_intent_id'];
          return {'success': true, 'payment_intent_id': _paymentIntentId};
        } catch (e) {
          return {'success': false, 'error': e.toString()};
        }

      case 'mobile_money':
        try {
          final response = await _supabase.functions.invoke(
            'mobile-money-payment',
            body: {
              'amount': amount,
              'phone': _userInfo['phone'],
              'order_id': _createdOrder!['id'],
            },
          );
          _paymentUrl = response.data['payment_url'];
          return {'success': true, 'payment_url': _paymentUrl};
        } catch (e) {
          return {'success': false, 'error': e.toString()};
        }

      case 'thix_money':
        try {
          final result = await _supabase.rpc(
            'deduct_wallet_balance',
            params: {
              'user_id': _supabase.auth.currentUser!.id,
              'amount': amount,
            },
          );
          if (result == true) {
            return {'success': true};
          } else {
            return {'success': false, 'error': 'Solde insuffisant'};
          }
        } catch (e) {
          return {'success': false, 'error': e.toString()};
        }

      default:
        return {'success': false, 'error': 'Méthode de paiement inconnue'};
    }
  }

  // ─── RÉINITIALISATION ───
  void reset() {
    _currentStep = 'address';
    _selectedAddress = null;
    _selectedShippingMethod = null;
    _selectedPaymentMethod = null;
    _createdOrder = null;
    _paymentIntentId = null;
    _paymentUrl = null;
    _savedAddresses = [];
    _userInfo = {};
    notifyListeners();
  }

  // ─── MÉTHODE UTILE POUR METTRE À JOUR L'ÉTAT ───
  void setState(VoidCallback fn) {
    fn();
    notifyListeners();
  }

  @override
  void dispose() {
    // Pas de streams à fermer, mais on peut nettoyer si besoin
    super.dispose();
  }
}
