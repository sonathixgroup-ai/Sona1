import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/market_providers.dart';

class CartState {
  final List<Map<String,dynamic>> items;
  final bool isLoading;
  final bool isSyncing;
  const CartState({this.items = const [], this.isLoading = false, this.isSyncing = false});
  CartState copyWith({List<Map<String,dynamic>>? items, bool? isLoading, bool? isSyncing})=> CartState(items: items?? this.items, isLoading: isLoading?? this.isLoading, isSyncing: isSyncing?? this.isSyncing);
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier(this.ref): super(const CartState()){ _init(); }
  final Ref ref;
  StreamSubscription? _sub;
  StreamSubscription? _authSub;

  double _getRealPrice(Map<String,dynamic> product){
    final raw = (product['price'] as num?)?.toDouble()??0;
    final sale = (product['sale_price'] as num?)?.toDouble()?? (product['discount_price'] as num?)?.toDouble();
    final percent = (product['discount_percent'] as num?)?.toDouble()??0;
    final original = (product['original_price'] as num?)?.toDouble()?? raw;
    if(sale!=null && sale>0 && sale<raw) return sale;
    if(sale!=null && sale>0 && original>0 && sale<original) return sale;
    if(percent>0) return raw * (1 - percent/100);
    return raw;
  }
  double _getOldPrice(Map<String,dynamic> product){
    final raw = (product['price'] as num?)?.toDouble()??0;
    final original = (product['original_price'] as num?)?.toDouble()?? raw;
    final sale = (product['sale_price'] as num?)?.toDouble();
    if(sale!=null && sale<raw) return raw;
    return original;
  }

  // GETTERS calculés
  List<Map<String,dynamic>> get cartItems => state.items;
  bool get isLoading => state.isLoading;
  bool get isSyncing => state.isSyncing;
  int get itemCount => state.items.length;
  int get totalQuantity => state.items.fold<int>(0, (sum, item){ final q = item['quantity']; if(q is num) return sum + q.toInt(); return sum + (int.tryParse(q.toString())??0); });

  String get currency {
    if(state.items.isEmpty) return 'FC';
    final p = state.items.first['product'] as Map?;
    String raw = 'FC';
    if(p!=null && p['currency']!=null) raw = p['currency'].toString().toUpperCase();
    if(raw=='CDF' || raw=='XOF' || raw=='FC') return 'FC';
    if(raw=='USD' || raw=='\$') return 'USD';
    return 'FC';
  }
  String get currencySymbol => currency=='USD'? '\$' : 'FC';
  String currencyForItem(Map<String,dynamic> item){
    final p = item['product'] as Map?;
    String raw = currency;
    if(p!=null && p['currency']!=null) raw = p['currency'].toString().toUpperCase();
    if(raw=='USD' || raw=='\$') return 'USD';
    return 'FC';
  }
  double get subtotal => state.items.fold(0.0, (sum, item){
    Map<String,dynamic> product = {};
    if(item['product'] is Map) product = Map<String,dynamic>.from(item['product'] as Map);
    int qty = 0;
    if(item['quantity'] is num) qty = (item['quantity'] as num).toInt(); else qty = int.tryParse(item['quantity'].toString())??0;
    return sum + (_getRealPrice(product) * qty);
  });
  double get originalSubtotal => state.items.fold(0.0, (sum, item){
    Map<String,dynamic> product = {};
    if(item['product'] is Map) product = Map<String,dynamic>.from(item['product'] as Map);
    int qty = 0;
    if(item['quantity'] is num) qty = (item['quantity'] as num).toInt(); else qty = int.tryParse(item['quantity'].toString())??0;
    return sum + (_getOldPrice(product) * qty);
  });
  double get totalDiscount => originalSubtotal - subtotal;
  double get shippingCost => 0;
  String get shippingSymbol => 'FC';
  double get total => subtotal + shippingCost;
  double getItemRealPrice(Map<String,dynamic> item){
    Map<String,dynamic> product = {};
    if(item['product'] is Map) product = Map<String,dynamic>.from(item['product'] as Map);
    return _getRealPrice(product);
  }
  double getItemOldPrice(Map<String,dynamic> item){
    Map<String,dynamic> product = {};
    if(item['product'] is Map) product = Map<String,dynamic>.from(item['product'] as Map);
    return _getOldPrice(product);
  }
  int getItemDiscountPercent(Map<String,dynamic> item){
    final oldP = getItemOldPrice(item);
    final real = getItemRealPrice(item);
    if(oldP<=0 || real>=oldP) return 0;
    return ((1 - real/oldP)*100).round();
  }

  void _init(){
    final db = ref.read(supabaseClientProvider);
    _authSub = db.auth.onAuthStateChange.listen((data){
      final session = data.session;
      if(session!=null){ _setupRealtime(); loadCart(); } else { _sub?.cancel(); state = const CartState(); }
    });
    if(db.auth.currentUser!=null){ _setupRealtime(); loadCart(); }
  }

  void _setupRealtime(){
    _sub?.cancel();
    final db = ref.read(supabaseClientProvider);
    final uid = db.auth.currentUser?.id;
    if(uid==null) return;
    final stream = db.from('cart').stream(primaryKey: ['id']).eq('user_id', uid).order('created_at', ascending: false);
    _sub = stream.listen((updated) async { await _syncCartWithProducts(List<Map<String,dynamic>>.from(updated)); });
  }

  Future<void> _syncCartWithProducts(List<Map<String,dynamic>> cartRecords) async {
    if(cartRecords.isEmpty){ state = state.copyWith(items: [], isSyncing: false); return; }
    state = state.copyWith(isSyncing: true);
    try{
      final db = ref.read(supabaseClientProvider);
      List<Map<String,dynamic>> enriched = [];
      for(var cartItem in cartRecords){
        final pid = cartItem['product_id'];
        if(pid!=null){
          final product = await db.from('products').select('*, shop:shops(name, logo_url)').eq('id', pid).maybeSingle();
          if(product!=null){ enriched.add({...cartItem, 'product': product}); } else { await db.from('cart').delete().eq('id', cartItem['id']); }
        }
      }
      state = state.copyWith(items: enriched);
    }catch(e){ debugPrint('sync cart $e'); }
    finally{ state = state.copyWith(isSyncing: false); }
  }

  Future<void> loadCart() async {
    final db = ref.read(supabaseClientProvider);
    final uid = db.auth.currentUser?.id;
    if(uid==null){ state = const CartState(); return; }
    state = state.copyWith(isLoading: true);
    try{
      final res = await db.from('cart').select().eq('user_id', uid).order('created_at', ascending: false);
      await _syncCartWithProducts(List<Map<String,dynamic>>.from(res));
    }catch(e){ debugPrint('loadCart $e'); }
    finally{ state = state.copyWith(isLoading: false); }
  }

  Future<void> addToCart({required String productId, int quantity=1, String? variant, String? color}) async {
    final db = ref.read(supabaseClientProvider);
    final uid = db.auth.currentUser?.id;
    if(uid==null) throw Exception('Veuillez vous connecter');
    try{
      Map<String,dynamic>? existing;
      for(final i in state.items){ if(i['product_id']==productId && i['variant']==variant && i['color']==color){ existing=i; break; } }
      if(existing!=null){
        int cur = 0;
        if(existing['quantity'] is num) cur = (existing['quantity'] as num).toInt(); else cur = int.tryParse(existing['quantity'].toString())??0;
        await updateQuantity(existing['id'].toString(), cur + quantity);
      } else {
        await db.from('cart').insert({'user_id': uid, 'product_id': productId, 'quantity': quantity, 'variant': variant, 'color': color});
      }
      await loadCart();
    }catch(e){ debugPrint('addToCart $e'); rethrow; }
  }

  Future<void> updateQuantity(String cartItemId, int newQuantity) async {
    if(newQuantity<=0){ await removeFromCart(cartItemId); return; }
    try{
      final db = ref.read(supabaseClientProvider);
      await db.from('cart').update({'quantity': newQuantity}).eq('id', cartItemId);
      List<Map<String,dynamic>> newItems = [...state.items];
      int idx = newItems.indexWhere((i)=> i['id'].toString()==cartItemId);
      if(idx!=-1){ newItems[idx] = {...newItems[idx], 'quantity': newQuantity}; state = state.copyWith(items: newItems); }
    }catch(e){ debugPrint('updateQty $e'); rethrow; }
  }

  Future<void> removeFromCart(String cartItemId) async {
    try{
      final db = ref.read(supabaseClientProvider);
      await db.from('cart').delete().eq('id', cartItemId);
      state = state.copyWith(items: state.items.where((i)=> i['id'].toString()!=cartItemId).toList());
    }catch(e){ debugPrint('remove $e'); rethrow; }
  }

  Future<void> clearCart() async {
    final db = ref.read(supabaseClientProvider);
    final uid = db.auth.currentUser?.id;
    if(uid==null) return;
    try{ await db.from('cart').delete().eq('user_id', uid); state = const CartState(); }catch(e){ debugPrint('clear $e'); rethrow; }
  }

  @override void dispose(){ _sub?.cancel(); _authSub?.cancel(); super.dispose(); }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref)=> CartNotifier(ref));
// Compat providers pour UI existante
final cartItemsProvider = Provider<List<Map<String,dynamic>>>((ref)=> ref.watch(cartProvider).items);
final cartTotalProvider = Provider<double>((ref){ final n = ref.read(cartProvider.notifier); return n.total; });
final cartCountProvider = Provider<int>((ref){ final n = ref.read(cartProvider.notifier); return n.itemCount; });
