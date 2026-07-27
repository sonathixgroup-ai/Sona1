import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/market_providers.dart';
import '../cart/cart_provider.dart';

class CheckoutState {
  final bool isLoading;
  final bool isProcessing;
  final String? error;
  final String currentStep;
  final List<Map<String,dynamic>> savedAddresses;
  final Map<String,dynamic>? selectedAddress;
  final Map<String,dynamic>? selectedShipping;
  final Map<String,dynamic>? selectedPayment;
  final Map<String,dynamic> userInfo;
  final Map<String,dynamic>? createdOrder;
  const CheckoutState({this.isLoading=false, this.isProcessing=false, this.error, this.currentStep='address', this.savedAddresses=const [], this.selectedAddress, this.selectedShipping, this.selectedPayment, this.userInfo=const {}, this.createdOrder});
  CheckoutState copyWith({bool? isLoading, bool? isProcessing, String? error, String? currentStep, List<Map<String,dynamic>>? savedAddresses, Map<String,dynamic>? selectedAddress, Map<String,dynamic>? selectedShipping, Map<String,dynamic>? selectedPayment, Map<String,dynamic>? userInfo, Map<String,dynamic>? createdOrder})=> CheckoutState(isLoading: isLoading??this.isLoading, isProcessing: isProcessing??this.isProcessing, error: error, currentStep: currentStep??this.currentStep, savedAddresses: savedAddresses??this.savedAddresses, selectedAddress: selectedAddress??this.selectedAddress, selectedShipping: selectedShipping??this.selectedShipping, selectedPayment: selectedPayment??this.selectedPayment, userInfo: userInfo??this.userInfo, createdOrder: createdOrder??this.createdOrder);
}

class CheckoutNotifier extends StateNotifier<CheckoutState> {
  CheckoutNotifier(this.ref): super(const CheckoutState());
  final Ref ref;
  String? _paymentIntentId;
  String? _paymentUrl;

  Future<void> loadCheckoutData() async {
    final db = ref.read(supabaseClientProvider);
    final userId = db.auth.currentUser?.id;
    if(userId==null){ state = state.copyWith(error: 'Non connecté'); return; }
    state = state.copyWith(isLoading: true, error: null);
    try{
      final results = await Future.wait([_loadAddresses(userId), _loadUserInfo(userId)]);
      List<Map<String,dynamic>> addresses = results[0] as List<Map<String,dynamic>>;
      Map<String,dynamic> userInfo = results[1] as Map<String,dynamic>;
      Map<String,dynamic>? selAddr = state.selectedAddress;
      if(selAddr==null && addresses.isNotEmpty) selAddr = addresses.first;
      if(userInfo['default_address_id']!=null){
        try{ selAddr = addresses.firstWhere((a)=> a['id'].toString()==userInfo['default_address_id'].toString()); }catch(_){}
      }
      state = state.copyWith(isLoading: false, savedAddresses: addresses, userInfo: userInfo, selectedAddress: selAddr, currentStep: 'address');
    }catch(e){ debugPrint('checkout load $e'); state = state.copyWith(isLoading: false, error: 'Erreur chargement'); }
  }

  Future<List<Map<String,dynamic>>> _loadAddresses(String userId) async {
    try{ final db = ref.read(supabaseClientProvider); final res = await db.from('addresses').select().eq('user_id', userId).order('is_default', ascending: false); return List<Map<String,dynamic>>.from(res); }catch(_){ return []; }
  }
  Future<Map<String,dynamic>> _loadUserInfo(String userId) async {
    final db = ref.read(supabaseClientProvider);
    try{
      final r = await db.from('users').select('id, full_name, email, phone, default_address_id').eq('id', userId).maybeSingle();
      if(r!=null) return r;
    }catch(_){}
    try{
      final r = await db.from('users').select('id, name, email, phone, default_address_id').eq('id', userId).maybeSingle();
      if(r!=null){ if(r['name']!=null && r['full_name']==null) r['full_name']=r['name']; return r; }
    }catch(_){}
    try{
      final r = await db.from('users').select('id, email, phone, default_address_id').eq('id', userId).maybeSingle();
      if(r!=null){ r['full_name']='Utilisateur'; return r; }
    }catch(_){}
    return {'id': userId, 'full_name': 'Utilisateur'};
  }

  void selectAddress(Map<String,dynamic> address){ state = state.copyWith(selectedAddress: address, currentStep: 'shipping'); }
  Future<void> addAddress(Map<String,dynamic> newAddress) async {
    final db = ref.read(supabaseClientProvider);
    final uid = db.auth.currentUser?.id;
    if(uid==null) return;
    state = state.copyWith(isLoading: true);
    try{
      final res = await db.from('addresses').insert({...newAddress, 'user_id': uid}).select().single();
      state = state.copyWith(savedAddresses: [res,...state.savedAddresses], selectedAddress: res, isLoading: false);
    }catch(_){ state = state.copyWith(isLoading: false); }
  }
  void selectShippingMethod(Map<String,dynamic> method){ state = state.copyWith(selectedShipping: method, currentStep: 'payment'); }
  void selectPaymentMethod(Map<String,dynamic> method){ state = state.copyWith(selectedPayment: method, currentStep: 'confirmation'); }

  Future<Map<String,dynamic>> processOrder({required double total, required List<Map<String,dynamic>> items}) async {
    final db = ref.read(supabaseClientProvider);
    final userId = db.auth.currentUser?.id;
    if(userId==null) throw Exception('Non connecté');
    if(state.selectedAddress==null) throw Exception('Adresse requise');
    if(state.selectedShipping==null) throw Exception('Mode livraison requis');
    if(state.selectedPayment==null) throw Exception('Paiement requis');
    if(items.isEmpty) throw Exception('Panier vide');
    state = state.copyWith(isProcessing: true);
    Map<String,dynamic>? createdOrder;
    try{
      String? shopId;
      if(items.isNotEmpty){
        final first = items.first;
        if(first['product'] is Map && (first['product'] as Map)['shop_id']!=null) shopId = (first['product'] as Map)['shop_id'].toString();
        else if(first['shop_id']!=null) shopId = first['shop_id'].toString();
      }
      final orderData = {
        'user_id': userId,
        'shop_id': shopId,
        'address_id': state.selectedAddress!['id'],
        'shipping_method': state.selectedShipping!['id'],
        'shipping_cost': state.selectedShipping!['price']??0.0,
        'total': total,
        'status': 'pending',
        'payment_status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      };
      final orderRes = await db.from('orders').insert(orderData).select().single();
      createdOrder = orderRes;
      for(var item in items){
        String prodTitle = 'Produit';
        if(item['product_name']!=null) prodTitle = item['product_name'].toString();
        else if(item['product'] is Map && (item['product'] as Map)['title']!=null) prodTitle = (item['product'] as Map)['title'].toString();
        await db.from('order_items').insert({
          'order_id': createdOrder['id'],
          'product_id': item['product_id']?? (item['product'] is Map? (item['product'] as Map)['id'] : null),
          'quantity': item['quantity'],
          'price': item['price']?? (item['product'] is Map? (item['product'] as Map)['price'] : 0),
          'product_name': prodTitle,
          'product_image': item['image_url']?? (item['product'] is Map? (item['product'] as Map)['image_url'] : null),
          'title_snapshot': prodTitle,
        });
      }
      final payResult = await _processPayment(total, createdOrder['id'].toString());
      if(payResult['success']==true){
        bool isCash = state.selectedPayment!['id']=='cash';
        await db.from('orders').update({'payment_status': isCash? 'pending_delivery' : 'paid', 'status': 'processing', 'paid_at': isCash? null : DateTime.now().toIso8601String()}).eq('id', createdOrder['id']);
        await ref.read(cartProvider.notifier).clearCart();
        final updated = await db.from('orders').select().eq('id', createdOrder['id']).single();
        state = state.copyWith(createdOrder: updated, isProcessing: false);
        return updated;
      } else { throw Exception(payResult['error']??'Paiement échoué'); }
    }catch(e){
      debugPrint('checkout error $e');
      if(createdOrder!=null){ try{ final db = ref.read(supabaseClientProvider); await db.from('orders').delete().eq('id', createdOrder['id']); }catch(_){} }
      state = state.copyWith(isProcessing: false);
      rethrow;
    }
  }

  Future<Map<String,dynamic>> _processPayment(double amount, String orderId) async {
    final db = ref.read(supabaseClientProvider);
    final method = state.selectedPayment!['id'];
    switch(method){
      case 'cash': return {'success': true};
      case 'card':
        try{
          final res = await db.functions.invoke('create-payment-intent', body: {'amount': amount, 'currency': 'CDF', 'order_id': orderId});
          _paymentIntentId = res.data['payment_intent_id'];
          return {'success': true, 'payment_intent_id': _paymentIntentId};
        }catch(e){ return {'success': false, 'error': 'Erreur carte: $e'}; }
      case 'mobile_money':
        try{
          final res = await db.functions.invoke('mobile-money-payment', body: {'amount': amount, 'phone': state.userInfo['phone']??'', 'order_id': orderId});
          _paymentUrl = res.data['payment_url'];
          return {'success': true, 'payment_url': _paymentUrl};
        }catch(e){ return {'success': false, 'error': 'Erreur Mobile Money: $e'}; }
      case 'thix_money':
        try{
          final result = await db.rpc('deduct_wallet_balance', params: {'user_id': db.auth.currentUser!.id, 'amount': amount});
          if(result==true) return {'success': true};
          return {'success': false, 'error': 'Solde insuffisant'};
        }catch(e){ return {'success': false, 'error': 'Erreur THIX Money: $e'}; }
      default: return {'success': false, 'error': 'Méthode non supportée'};
    }
  }

  void reset(){ state = const CheckoutState(); }
}

final checkoutProvider = StateNotifierProvider<CheckoutNotifier, CheckoutState>((ref)=> CheckoutNotifier(ref));
