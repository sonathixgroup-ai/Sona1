// lib/presentation/thix_market/supermarket/providers/supermarket_provider.dart
// PROVIDER UNIQUE SUPERMARKET - Réutilise ShopService / ProductService / OrderService existants
// Pas de duplication de Model, on travaille avec Map<String,dynamic> venant de Supabase

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupermarketProvider extends ChangeNotifier {
  // --- DEPENDANCES ---
  final _supa = Supabase.instance.client;

  // --- ETAT CLIENT ---
  List<Map<String, dynamic>> shops = []; // liste Freshia, MegaStore...
  List<Map<String, dynamic>> aisles = []; // rayons du shop ouvert
  List<Map<String, dynamic>> products = []; // produits du shop ouvert
  Map<String, int> cartQty = {}; // productId -> quantité (panier rapide)

  String? currentShopId;
  String selectedAisle = 'Tous';
  bool loading = true;

  // --- REALTIME ---
  RealtimeChannel? _stockChannel;

  // ===========================================================
  // LOAD SUPERMARCHES (HOME)
  // ===========================================================
  Future<void> loadSupermarkets() async {
    // Charge uniquement les boutiques vérifiées de type supermarket
    loading = true;
    notifyListeners();

    final res = await _supa
       .from('shops')
       .select('*')
       .eq('vendor_type', 'supermarket')
       .eq('is_verified', true)
       .order('created_at');

    shops = List<Map<String, dynamic>>.from(res);
    loading = false;
    notifyListeners();
  }

  // ===========================================================
  // LOAD DETAIL D'UN SUPERMARCHE
  // ===========================================================
  Future<void> loadShopDetail(String shopId) async {
    currentShopId = shopId;
    loading = true;
    notifyListeners();

    // On charge en parallèle: rayons + produits
    final results = await Future.wait([
      _supa.from('supermarket_aisles').select('*').eq('shop_id', shopId).order('sort'),
      _supa.from('products').select('*').eq('shop_id', shopId).eq('is_active', true).order('created_at', ascending: false).limit(100),
    ]);

    // On ajoute manuellement "Tous" en première position
    aisles = [
      {'id': 'all', 'name': 'Tous', 'icon': 'apps'},
     ...List<Map<String, dynamic>>.from(results[0] as List)
    ];
    products = List<Map<String, dynamic>>.from(results[1] as List);
    selectedAisle = 'Tous';

    loading = false;
    notifyListeners();

    // Ecoute stock en live pour ne pas vendre en rupture
    _listenStock(shopId);
  }

  // ===========================================================
  // FILTRES & PANIER RAPIDE
  // ===========================================================
  List<Map<String, dynamic>> get filteredProducts {
    // Si "Tous" on retourne tout, sinon filtre par aisle_id ou nom aisle
    if (selectedAisle == 'Tous') return products;
    final aisleObj = aisles.firstWhere((a) => a['name'] == selectedAisle, orElse: () => {'id': ''});
    return products.where((p) => p['aisle_id'] == aisleObj['id'] || (p['aisle']?? '') == selectedAisle).toList();
  }

  void setAisle(String name) {
    selectedAisle = name;
    notifyListeners();
  }

  void add(String productId, int delta) {
    // Gestion quantité panier sans aller en négatif
    final current = cartQty[productId]?? 0;
    final next = current + delta;
    if (next <= 0) {
      cartQty.remove(productId);
    } else {
      cartQty[productId] = next;
    }
    notifyListeners();
  }

  int get totalItems => cartQty.values.fold(0, (a, b) => a + b);

  int get totalPrice {
    int sum = 0;
    cartQty.forEach((id, qty) {
      final p = products.firstWhere((e) => e['id'] == id, orElse: () => {'price': 0});
      sum += ((p['price']?? 0) as int) * qty;
    });
    return sum;
  }

  // ===========================================================
  // REALTIME STOCK
  // ===========================================================
  void _listenStock(String shopId) {
    _stockChannel?.unsubscribe();
    _stockChannel = _supa
       .channel('sm-stock-$shopId')
       .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'products',
          filter: PostgresChangeFilter(column: 'shop_id', value: shopId),
          callback: (payload) {
            // Mise à jour locale du stock sans recharger toute la liste
            final idx = products.indexWhere((e) => e['id'] == payload.newRecord['id']);
            if (idx!= -1) {
              products[idx]['stock'] = payload.newRecord['stock'];
              notifyListeners();
            }
          },
        )
       .subscribe();
  }

  @override
  void dispose() {
    _stockChannel?.unsubscribe();
    super.dispose();
  }
}
