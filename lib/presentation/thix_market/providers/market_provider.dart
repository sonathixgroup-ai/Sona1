// lib/presentation/thix_market/providers/market_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MarketProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  List<Map<String, dynamic>> _liveSessions = [];
  List<Map<String, dynamic>> _flashSales = [];
  List<Map<String, dynamic>> _promoBanners = [];
  List<Map<String, dynamic>> _recommendedProducts = [];
  List<Map<String, dynamic>> _featuredShops = [];
  List<Map<String, dynamic>> _forYouProducts = [];
  int _unreadNotifications = 3;
  bool _isLoading = false;

  // Getters
  List<Map<String, dynamic>> get liveSessions => _liveSessions;
  List<Map<String, dynamic>> get flashSales => _flashSales;
  List<Map<String, dynamic>> get promoBanners => _promoBanners;
  List<Map<String, dynamic>> get recommendedProducts => _recommendedProducts;
  List<Map<String, dynamic>> get featuredShops => _featuredShops;
  List<Map<String, dynamic>> get forYouProducts => _forYouProducts;
  int get unreadNotifications => _unreadNotifications;
  bool get isLoading => _isLoading;

  // ============================================================
  // GÉNÉRATION DES DONNÉES MOCKÉES (ULTRA RÉALISTES)
  // ============================================================
  
  List<Map<String, dynamic>> _generateMockLives() {
    return [
      {
        'title': 'Vente Flash Mode Été',
        'shop_name': 'Mode Élégance',
        'thumbnail': 'https://picsum.photos/seed/live1/400/300',
        'viewers': 1247,
      },
      {
        'title': 'Démo Smartphones 5G',
        'shop_name': 'Tech Pro CI',
        'thumbnail': 'https://picsum.photos/seed/live2/400/300',
        'viewers': 892,
      },
      {
        'title': 'Enchères Auto Prestige',
        'shop_name': 'Auto Prestige',
        'thumbnail': 'https://picsum.photos/seed/live3/400/300',
        'viewers': 2456,
      },
      {
        'title': 'Beauté & Bien-être Live',
        'shop_name': 'Beauté Nature',
        'thumbnail': 'https://picsum.photos/seed/live4/400/300',
        'viewers': 567,
      },
    ];
  }

  List<Map<String, dynamic>> _generateMockBanners() {
    return [
      {
        'title': '🔥 Super Soldes Jusqu\'à -70%',
        'image_url': 'https://picsum.photos/seed/banner1/800/300',
        'link': '/promo1',
      },
      {
        'title': '📱 Nouveaux Smartphones Arrivage',
        'image_url': 'https://picsum.photos/seed/banner2/800/300',
        'link': '/promo2',
      },
      {
        'title': '🚚 Livraison Gratuite Offre Limitée',
        'image_url': 'https://picsum.photos/seed/banner3/800/300',
        'link': '/promo3',
      },
    ];
  }

  List<Map<String, dynamic>> _generateMockProducts(int count) {
    final titles = [
      'Smartphone Pro Max 5G', 'Casque Audio Bluetooth Pro', 'Montre Connectée Sport',
      'Enceinte Portable Bass Boost', 'Sac à Main Luxe Cuir', 'Chaussures Running Air',
      'Tablette Graphique Pro', 'Lunettes de Soleil Polarised', 'Parfum Exclusif Or',
      'Machine à Café Expresso', 'Aspirateur Robot Autonome', 'Télévision OLED 65"',
      'Bracelet Connecté Fitness', 'Écouteurs True Wireless', 'Drone 4K Professionnel'
    ];
    final shops = [
      'Tech Pro CI', 'Mode Élégance', 'Maison & Jardin', 'Auto Prestige', 
      'Beauté Nature', 'Sport Fit', 'Électronique Pro', 'Lifestyle Shop'
    ];
    final images = [
      'https://picsum.photos/seed/prod1/400/400',
      'https://picsum.photos/seed/prod2/400/400',
      'https://picsum.photos/seed/prod3/400/400',
      'https://picsum.photos/seed/prod4/400/400',
      'https://picsum.photos/seed/prod5/400/400',
      'https://picsum.photos/seed/prod6/400/400',
      'https://picsum.photos/seed/prod7/400/400',
      'https://picsum.photos/seed/prod8/400/400',
    ];
    List<Map<String, dynamic>> products = [];
    for (int i = 0; i < count; i++) {
      final price = 15000 + (i % 10) * 7500;
      final hasDiscount = i % 2 == 0;
      final discountPrice = hasDiscount ? (price * 0.6).roundToDouble() : null;
      products.add({
        'id': 'prod_${i + 1}',
        'title': titles[i % titles.length],
        'price': price,
        'discount_price': discountPrice,
        'image_url': images[i % images.length],
        'shop_name': shops[i % shops.length],
        'rating': 3.5 + (i % 6) * 0.3,
        'reviews_count': 20 + (i * 12),
        'free_shipping': i % 3 == 0,
        'stock': 5 + (i % 15),
        'is_flash_sale': i < 4,
        'is_verified': i % 2 == 0,
      });
    }
    return products;
  }

  List<Map<String, dynamic>> _generateMockShops(int count) {
    final names = [
      'Mode Élégance', 'Tech Pro CI', 'Maison & Jardin', 'Auto Prestige',
      'Beauté Nature', 'Sport Fit', 'Électronique Pro', 'Lifestyle Shop'
    ];
    final logos = [
      'https://picsum.photos/seed/shop1/200/200',
      'https://picsum.photos/seed/shop2/200/200',
      'https://picsum.photos/seed/shop3/200/200',
      'https://picsum.photos/seed/shop4/200/200',
      'https://picsum.photos/seed/shop5/200/200',
      'https://picsum.photos/seed/shop6/200/200',
    ];
    List<Map<String, dynamic>> shops = [];
    for (int i = 0; i < count; i++) {
      shops.add({
        'id': 'shop_${i + 1}',
        'name': names[i % names.length],
        'logo_url': logos[i % logos.length],
        'cover': 'https://picsum.photos/seed/cover_$i/600/200',
        'rating': 4.0 + (i % 4) * 0.25,
        'products_count': 30 + (i * 25),
        'followers': 300 + (i * 250),
        'is_verified': i % 2 == 0,
        'description': 'Boutique de référence pour ${names[i % names.length].toLowerCase()}',
      });
    }
    return shops;
  }

  // ============================================================
  // CHARGEMENT DES DONNÉES (MOCK + RÉEL)
  // ============================================================
  
  Future<void> loadHomeData() async {
    _setLoading(true);
    try {
      // 🔥 DONNÉES MOCKÉES INSTANTANÉES (UI immédiate)
      _liveSessions = _generateMockLives();
      _flashSales = _generateMockProducts(6);
      _promoBanners = _generateMockBanners();
      _recommendedProducts = _generateMockProducts(6);
      _featuredShops = _generateMockShops(6);
      _forYouProducts = _generateMockProducts(8);
      _unreadNotifications = 3;
      
      // ✅ TENTATIVE DE CHARGEMENT SUPABASE (en arrière-plan)
      _loadFromSupabase();
      
    } catch (e) {
      debugPrint('Error loading home data (mock fallback): $e');
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // CHARGEMENT RÉEL DEPUIS SUPABASE (en arrière-plan)
  // ============================================================
  Future<void> _loadFromSupabase() async {
    try {
      final futureLives = _supabase
          .from('lives')
          .select('*, shop:shops(name, logo_url)')
          .eq('status', 'live')
          .order('viewer_count', ascending: false)
          .limit(5);
      
      final futureProducts = _supabase
          .from('products')
          .select('*, shop:shops(name)')
          .eq('status', 'active')
          .order('views', ascending: false)
          .limit(20);
      
      final results = await Future.wait([futureLives, futureProducts]);
      
      // Mettre à jour les données si Supabase répond
      if (results[0].isNotEmpty) {
        _liveSessions = List<Map<String, dynamic>>.from(results[0]);
      }
      if (results[1].isNotEmpty) {
        final products = List<Map<String, dynamic>>.from(results[1]);
        _recommendedProducts = products.take(6).toList();
        _forYouProducts = products.length > 6 ? products.skip(6).take(8).toList() : products.toList();
        _flashSales = products.where((p) => p['is_flash_sale'] == true).take(6).toList();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Supabase loading skipped (using mock data): $e');
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
