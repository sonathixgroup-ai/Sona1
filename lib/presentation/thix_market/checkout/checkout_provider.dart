// lib/presentation/thix_market/checkout/checkout_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/presentation/thix_market/cart/cart_provider.dart';

class CheckoutProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = false;
  bool _isProcessing = false;
  String? _errorMessage;
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
  String? get errorMessage => _errorMessage;
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
      _errorMessage = "Utilisateur non connecté.";
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.wait([
        _loadSavedAddresses(userId),
        _loadUserInfo(userId),
      ]);
      if (_selectedAddress == null && _savedAddresses.isNotEmpty) {
        _selectedAddress = _savedAddresses.first;
      }
      _currentStep = 'address';
    } catch (e) {
      debugPrint('❌ Erreur chargement checkout: $e');
      _errorMessage = "Erreur de chargement des données. Veuillez réessayer.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadUserInfo(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select('id, full_name, email, phone, default_address_id')
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        _userInfo = response;
      } else {
        try {
          final fallbackResponse = await _supabase
              .from('users')
              .select('id, name, email, phone, default_address_id')
              .eq('id', userId)
              .maybeSingle();
          if (fallbackResponse != null) {
            _userInfo = fallbackResponse;
            if (_userInfo['name'] != null && _userInfo['full_name'] == null) {
              _userInfo['full_name'] = _userInfo['name'];
            }
          }
        } catch (_) {
          final minimalResponse = await _supabase
              .from('users')
              .select('id, email, phone, default_address_id')
              .eq('id', userId)
              .maybeSingle();
          if (minimalResponse != null) {
            _userInfo = minimalResponse;
            _userInfo['full_name'] = 'Utilisateur';
          }
        }
      }

      if (_userInfo['default_address_id'] != null) {
        _selectedAddress = _savedAddresses.firstWhere(
          (a) => a['id'] == _userInfo['default_address_id'],
          orElse: () => <String, dynamic>{},
        );
      }
    } catch (e) {
      debugPrint('⚠️ Erreur chargement user info: $e');
      _userInfo = {
        'id': userId,
        'full_name': 'Utilisateur',
        'email': '',
        'phone': '',
      };
    }
  }

  Future<void> _loadSavedAddresses(String userId) async {
    try {
      final response = await _supabase
          .from('addresses')
          .select()
          .eq('user_id', userId)
          .order('is_default', ascending: false);
      _savedAddresses = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('⚠️ Erreur chargement adresses: $e');
      _savedAddresses = [];
    }
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

  // ─── TRAITEMENT DE LA COMMANDE (Corrigé avec shop_id) ───
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
    if (items.isEmpty) throw Exception('Le panier est vide');

    _isProcessing = true;
    notifyListeners();

    try {
      // 🌟 ÉTAPE CLÉ : Récupération dynamique du shop_id depuis les articles du panier
      final String? shopId = items.first['product']?['shop_id'] ?? items.first['shop_id']?.toString();

      // 1. Création de la commande mère avec shop_id connecté
      final orderData = {
        'user_id': userId,
        'shop_id': shopId, // 👈 Lien direct avec la boutique du vendeur !
        'address_id': _selectedAddress!['id'],
        'shipping_method': _selectedShippingMethod!['id'],
        'shipping_cost': _selectedShippingMethod!['price'] ?? 0.0,
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

      // 2. Insertion des articles de la commande (Items)
      for (var item in items) {
        final productTitle = item['product_name'] ?? item['product']?['title'] ?? 'Produit inconnu';
        
        await _supabase.from('order_items').insert({
          'order_id': _createdOrder!['id'],
          'product_id': item['product_id'] ?? item['product']?['id'],
          'quantity': item['quantity'],
          'price': item['price'] ?? item['product']?['price'] ?? 0.0,
          'product_name': productTitle,
          'product_image': item['image_url'] ?? item['product']?['image_url'],
          'title_snapshot': productTitle,
        });
      }

      // 3. Processus de Paiement
      final paymentResult = await _processPayment(total);

      if (paymentResult['success'] == true) {
        final isCash = _selectedPaymentMethod!['id'] == 'cash';
        
        await _supabase
            .from('orders')
            .update({
              'payment_status': isCash ? 'pending_delivery' : 'paid',
              'status': 'processing',
              'paid_at': isCash ? null : DateTime.now().toIso8601String(),
            })
            .eq('id', _createdOrder!['id']);

        // 4. Nettoyage du panier après succès
        await cartProvider.clearCart();

        // 5. Récupération de la commande à jour pour l'affichage final
        final updatedOrder = await _supabase
            .from('orders')
            .select()
            .eq('id', _createdOrder!['id'])
            .single();
        _createdOrder = updatedOrder;
        
        return _createdOrder!;
      } else {
        throw Exception(paymentResult['error'] ?? 'Paiement échoué');
      }
    } catch (e) {
      debugPrint('❌ Checkout error: $e');
      // Rollback en cas d'échec
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
      case 'cash':
        return {'success': true, 'message': 'Paiement à la livraison enregistré.'};

      case 'card':
        try {
          final response = await _supabase.functions.invoke(
            'create-payment-intent',
            body: {
              'amount': amount,
              'currency': 'CDF',
              'order_id': _createdOrder!['id'],
            },
          );
          _paymentIntentId = response.data['payment_intent_id'];
          return {'success': true, 'payment_intent_id': _paymentIntentId};
        } catch (e) {
          return {'success': false, 'error': 'Erreur serveur carte: ${e.toString()}'};
        }

      case 'mobile_money':
        try {
          final response = await _supabase.functions.invoke(
            'mobile-money-payment',
            body: {
              'amount': amount,
              'phone': _userInfo['phone'] ?? '',
              'order_id': _createdOrder!['id'],
            },
          );
          _paymentUrl = response.data['payment_url'];
          return {'success': true, 'payment_url': _paymentUrl};
        } catch (e) {
          return {'success': false, 'error': 'Erreur serveur Mobile Money: ${e.toString()}'};
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
            return {'success': false, 'error': 'Solde THIX Money insuffisant.'};
          }
        } catch (e) {
          return {'success': false, 'error': 'Erreur THIX Money: ${e.toString()}'};
        }

      default:
        return {'success': false, 'error': 'Méthode de paiement non supportée.'};
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
    _errorMessage = null;
    notifyListeners();
  }

  void setState(VoidCallback fn) {
    fn();
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
