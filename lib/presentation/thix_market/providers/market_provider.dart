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
  int _unreadNotifications = 0;
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

  Future<void> loadHomeData() async {
    _setLoading(true);
    try {
      // 🔥 DONNÉES MOCKÉES POUR TESTER L'UI
      _liveSessions = _generateMockLives();
      _flashSales = _generateMockProducts(6);
      _promoBanners = _generateMockBanners();
      _recommendedProducts = _generateMockProducts(4);
      _featuredShops = _generateMockShops(5);
      _forYouProducts = _generateMockProducts(8);
      _unreadNotifications = 3;
    } catch (e) {
      debugPrint('Error loading home data: $e');
    } finally {
      _setLoading(false);
    }
  }

  List<Map<String, dynamic>> _generateMockLives() {
    return [
      {
        'title': 'Vente Flash Mode',
        'shop_name': 'Mode Express',
        'thumbnail': 'https://picsum.photos/seed/live1/400/300',
        'viewers': 1247,
      },
      {
        'title': 'Démo Smartphones',
        'shop_name': 'TechZone',
        'thumbnail': 'https://picsum.photos/seed/live2/400/300',
        'viewers': 892,
      },
      {
        'title': 'Enchères Auto',
        'shop_name': 'Auto Prestige',
        'thumbnail': 'https://picsum.photos/seed/live3/400/300',
        'viewers': 2456,
      },
    ];
  }

  List<Map<String, dynamic>> _generateMockProducts(int count) {
    final titles = [
      'Smartphone Pro Max', 'Casque Audio Bluetooth', 'Montre Connectée',
      'Enceinte Portable', 'Sac à Main Luxe', 'Chaussures Sport',
      'Tablette Graphique', 'Lunettes de Soleil', 'Parfum Exclusif',
      'Machine à Café', 'Aspirateur Robot', 'Télévision OLED'
    ];
    final shops = ['Shop A', 'Shop B', 'Shop C', 'Shop D', 'Shop E'];
    final images = [
      'https://picsum.photos/seed/prod1/400/400',
      'https://picsum.photos/seed/prod2/400/400',
      'https://picsum.photos/seed/prod3/400/400',
      'https://picsum.photos/seed/prod4/400/400',
      'https://picsum.photos/seed/prod5/400/400',
    ];
    List<Map<String, dynamic>> products = [];
    for (int i = 0; i < count; i++) {
      products.add({
        'id': 'prod_$i',
        'title': titles[i % titles.length],
        'price': (10000 + i * 5000).toDouble(),
        'discount_price': i % 2 == 0 ? (5000 + i * 2000).toDouble() : null,
        'image_url': images[i % images.length],
        'shop_name': shops[i % shops.length],
        'rating': 3.5 + (i % 3) * 0.5,
        'reviews_count': 50 + i * 10,
        'free_shipping': i % 3 == 0,
        'stock': 20 - i,
        'is_flash_sale': i < 3,
        'is_verified': i % 2 == 0,
      });
    }
    return products;
  }

  List<Map<String, dynamic>> _generateMockBanners() {
    return [
      {
        'title': 'Offre Spéciale -50%',
        'image_url': 'https://picsum.photos/seed/banner1/800/300',
        'link': '/promo1',
      },
      {
        'title': 'Nouvelle Collection',
        'image_url': 'https://picsum.photos/seed/banner2/800/300',
        'link': '/promo2',
      },
      {
        'title': 'Livraison Gratuite',
        'image_url': 'https://picsum.photos/seed/banner3/800/300',
        'link': '/promo3',
      },
    ];
  }

  List<Map<String, dynamic>> _generateMockShops(int count) {
    final names = [
      'Mode Express', 'TechZone', 'Maison Chic', 'Auto Prestige',
      'Beauté Nature', 'Sport Fit', 'Électronique Pro'
    ];
    final logos = [
      'https://picsum.photos/seed/shop1/200/200',
      'https://picsum.photos/seed/shop2/200/200',
      'https://picsum.photos/seed/shop3/200/200',
      'https://picsum.photos/seed/shop4/200/200',
      'https://picsum.photos/seed/shop5/200/200',
    ];
    List<Map<String, dynamic>> shops = [];
    for (int i = 0; i < count; i++) {
      shops.add({
        'id': 'shop_$i',
        'name': names[i % names.length],
        'logo_url': logos[i % logos.length],
        'cover': 'https://picsum.photos/seed/cover$i/600/200',
        'rating': 4.0 + (i % 3) * 0.3,
        'products_count': 50 + i * 20,
        'followers': 500 + i * 200,
        'is_verified': i % 2 == 0,
        'description': 'Boutique de qualité supérieure',
      });
    }
    return shops;
  }

  // Les méthodes réelles (pour Supabase) restent, mais avec des mock pour l'instant
  // Vous pourrez les remplacer par les vrais appels plus tard.

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
