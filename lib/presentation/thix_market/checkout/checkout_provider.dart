import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/market_providers.dart';
import '../cart/cart_provider.dart';
import '../../../services/market_payment_service.dart';

class CheckoutState {
  final bool isLoading;
  final bool isProcessing;
  final String? error;
  final String currentStep;
  final List<Map<String, dynamic>> savedAddresses;
  final Map<String, dynamic>? selectedAddress;
  final Map<String, dynamic>? selectedShipping;
  final Map<String, dynamic>? selectedPayment;
  final Map<String, dynamic> userInfo;
  final Map<String, dynamic>? createdOrder;

  const CheckoutState({
    this.isLoading = false,
    this.isProcessing = false,
    this.error,
    this.currentStep = 'address',
    this.savedAddresses = const [],
    this.selectedAddress,
    this.selectedShipping,
    this.selectedPayment,
    this.userInfo = const {},
    this.createdOrder,
  });

  CheckoutState copyWith({
    bool? isLoading,
    bool? isProcessing,
    String? error,
    String? currentStep,
    List<Map<String, dynamic>>? savedAddresses,
    Map<String, dynamic>? selectedAddress,
    Map<String, dynamic>? selectedShipping,
    Map<String, dynamic>? selectedPayment,
    Map<String, dynamic>? userInfo,
    Map<String, dynamic>? createdOrder,
  }) =>
      CheckoutState(
        isLoading: isLoading ?? this.isLoading,
        isProcessing: isProcessing ?? this.isProcessing,
        error: error,
        currentStep: currentStep ?? this.currentStep,
        savedAddresses: savedAddresses ?? this.savedAddresses,
        selectedAddress: selectedAddress ?? this.selectedAddress,
        selectedShipping: selectedShipping ?? this.selectedShipping,
        selectedPayment: selectedPayment ?? this.selectedPayment,
        userInfo: userInfo ?? this.userInfo,
        createdOrder: createdOrder ?? this.createdOrder,
      );
}

class CheckoutNotifier extends StateNotifier<CheckoutState> {
  CheckoutNotifier(this.ref) : super(const CheckoutState());
  final Ref ref;

  // ========== NAVIGATION ==========
  void goToStep(String step) {
    const validSteps = [
      'address',
      'shipping',
      'summary',
      'payment',
      'waiting_payment',
      'confirmation',
      'success',
      'bon_de_commande',
    ];
    if (validSteps.contains(step)) {
      state = state.copyWith(currentStep: step, error: null);
    }
  }

  void setStep(String step) => goToStep(step);

  void next() {
    switch (state.currentStep) {
      case 'address':
        goToStep('shipping');
        break;
      case 'shipping':
        goToStep('summary');
        break;
      case 'summary':
      case 'confirmation':
        goToStep('payment');
        break;
      case 'payment':
        goToStep('waiting_payment');
        break;
      case 'waiting_payment':
        goToStep('bon_de_commande');
        break;
      default:
        break;
    }
  }

  void previous() {
    switch (state.currentStep) {
      case 'shipping':
        goToStep('address');
        break;
      case 'summary':
      case 'confirmation':
        goToStep('shipping');
        break;
      case 'payment':
        goToStep('summary');
        break;
      case 'waiting_payment':
        goToStep('payment');
        break;
      case 'success':
      case 'bon_de_commande':
        goToStep('payment');
        break;
      default:
        break;
    }
  }

  // ========== CHARGEMENT ==========
  Future<void> loadCheckoutData() async {
    final db = ref.read(supabaseClientProvider);
    final userId = db.auth.currentUser?.id;
    if (userId == null) {
      state = state.copyWith(error: 'Non connecté');
      return;
    }
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await Future.wait([_loadAddresses(userId), _loadUserInfo(userId)]);
      List<Map<String, dynamic>> addresses = results[0] as List<Map<String, dynamic>>;
      Map<String, dynamic> userInfo = results[1] as Map<String, dynamic>;
      Map<String, dynamic>? selAddr = state.selectedAddress;
      if (selAddr == null && addresses.isNotEmpty) selAddr = addresses.first;
      if (userInfo['default_address_id'] != null) {
        try {
          selAddr = addresses.firstWhere(
              (a) => a['id'].toString() == userInfo['default_address_id'].toString());
        } catch (_) {}
      }
      state = state.copyWith(
        isLoading: false,
        savedAddresses: addresses,
        userInfo: userInfo,
        selectedAddress: selAddr,
        currentStep: 'address',
      );
    } catch (e) {
      debugPrint('checkout load $e');
      state = state.copyWith(isLoading: false, error: 'Erreur chargement');
    }
  }

  Future<List<Map<String, dynamic>>> _loadAddresses(String userId) async {
    try {
      final db = ref.read(supabaseClientProvider);
      final res = await db
          .from('addresses')
          .select()
          .eq('user_id', userId)
          .order('is_default', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> _loadUserInfo(String userId) async {
    final db = ref.read(supabaseClientProvider);
    try {
      final r = await db
          .from('users')
          .select('id, full_name, email, phone, default_address_id')
          .eq('id', userId)
          .maybeSingle();
      if (r != null) return r;
    } catch (_) {}
    try {
      final r = await db
          .from('users')
          .select('id, name, email, phone, default_address_id')
          .eq('id', userId)
          .maybeSingle();
      if (r != null) {
        if (r['name'] != null && r['full_name'] == null) r['full_name'] = r['name'];
        return r;
      }
    } catch (_) {}
    return {'id': userId, 'full_name': 'Utilisateur'};
  }

  // ========== SÉLECTIONS ==========
  void selectAddress(Map<String, dynamic> address) {
    state = state.copyWith(selectedAddress: address);
  }

  Future<void> addAddress(Map<String, dynamic> newAddress) async {
    final db = ref.read(supabaseClientProvider);
    final uid = db.auth.currentUser?.id;
    if (uid == null) return;
    state = state.copyWith(isLoading: true);
    try {
      final res = await db
          .from('addresses')
          .insert({...newAddress, 'user_id': uid})
          .select()
          .single();
      state = state.copyWith(
        savedAddresses: [res, ...state.savedAddresses],
        selectedAddress: res,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  void selectShippingMethod(Map<String, dynamic> method) {
    state = state.copyWith(selectedShipping: method);
  }

  void selectPaymentMethod(Map<String, dynamic> method) {
    state = state.copyWith(selectedPayment: method);
  }

  // ========== CRÉATION COMMANDE (sans paiement) ==========
  Future<Map<String, dynamic>> createOrderOnly({
    required double total,
    required List<Map<String, dynamic>> items,
  }) async {
    final db = ref.read(supabaseClientProvider);
    final userId = db.auth.currentUser?.id;
    if (userId == null) throw Exception('Non connecté');
    if (state.selectedAddress == null) throw Exception('Adresse requise');
    if (state.selectedShipping == null) throw Exception('Mode livraison requis');
    if (state.selectedPayment == null) throw Exception('Paiement requis');
    if (items.isEmpty) throw Exception('Panier vide');

    state = state.copyWith(isProcessing: true);

    try {
      String? shopId;
      if (items.isNotEmpty) {
        final first = items.first;
        if (first['product'] is Map && (first['product'] as Map)['shop_id'] != null) {
          shopId = (first['product'] as Map)['shop_id'].toString();
        } else if (first['shop_id'] != null) {
          shopId = first['shop_id'].toString();
        }
      }

      final orderData = {
        'user_id': userId,
        'shop_id': shopId,
        'address_id': state.selectedAddress!['id'],
        'shipping_method': state.selectedShipping!['id'],
        'shipping_cost': state.selectedShipping!['price'] ?? 0.0,
        'total': total,
        'status': 'pending',
        'payment_status': 'awaiting_payment',
        'created_at': DateTime.now().toIso8601String(),
      };

      final orderRes = await db.from('orders').insert(orderData).select().single();

      for (var item in items) {
        String prodTitle = item['product_name']?.toString() ?? 'Produit';
        if (item['product'] is Map && (item['product'] as Map)['title'] != null) {
          prodTitle = (item['product'] as Map)['title'].toString();
        }

        await db.from('order_items').insert({
          'order_id': orderRes['id'],
          'product_id': item['product_id'] ??
              (item['product'] is Map ? (item['product'] as Map)['id'] : null),
          'quantity': item['quantity'],
          'price': item['price'] ?? 0,
          'product_name': prodTitle,
          'product_image': item['image_url'],
          'title_snapshot': prodTitle,
        });
      }

      state = state.copyWith(createdOrder: orderRes, isProcessing: false);
      return orderRes;
    } catch (e) {
      state = state.copyWith(isProcessing: false);
      rethrow;
    }
  }

  // ========== PROCESS ORDER + PAIEMENT (utilisé par payment_method_selector) ==========
  Future<Map<String, dynamic>> processOrder({
    required double total,
    required List<Map<String, dynamic>> items,
    String? phoneNumber,
  }) async {
    // 1. Créer la commande
    final order = await createOrderOnly(total: total, items: items);
    final orderId = order['id'].toString();

    // 2. Initier le paiement
    final paymentService = MarketPaymentService(ref.read(supabaseClientProvider));
    final method = state.selectedPayment!['id'] as String;

    final result = await paymentService.initiatePayment(
      orderId: orderId,
      amount: total,
      currency: 'CDF',
      paymentMethod: method,
      phoneNumber: phoneNumber ?? state.userInfo['phone']?.toString(),
    );

    if (result['success'] != true) {
      // Annuler la commande si le paiement échoue immédiatement
      try {
        await ref.read(supabaseClientProvider).from('orders').delete().eq('id', orderId);
      } catch (_) {}
      throw Exception(result['error'] ?? 'Paiement échoué');
    }

    // 3. Mettre à jour le status selon le type de paiement
    final paymentStatus = result['payment_status'] ?? 'awaiting_payment';
    await ref.read(supabaseClientProvider).from('orders').update({
      'payment_status': paymentStatus,
      if (paymentStatus == 'paid' || paymentStatus == 'pending_delivery') 'status': 'processing',
    }).eq('id', orderId);

    // 4. Si paiement immédiat (cash / thix), vider le panier
    if (result['needs_waiting'] != true) {
      await ref.read(cartProvider.notifier).clearCart();
      final updated = await ref.read(supabaseClientProvider).from('orders').select().eq('id', orderId).single();
      state = state.copyWith(createdOrder: updated);
    }

    return {
      ...result,
      'order': order,
      'order_id': orderId,
    };
  }

  void reset() {
    state = const CheckoutState();
  }
}

final checkoutProvider =
    StateNotifierProvider<CheckoutNotifier, CheckoutState>((ref) => CheckoutNotifier(ref));
