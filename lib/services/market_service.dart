import 'package:flutter/foundation.dart';
import 'package:thix_id/models/market_category.dart';
import 'package:thix_id/models/market_live.dart';
import 'package:thix_id/models/market_product.dart';
import 'package:thix_id/models/market_store.dart';
import 'package:thix_id/supabase/supabase_config.dart';

class ThixMarketService {
  ThixMarketService();

  static const String categoriesTable = 'market_categories';
  static const String productsTable = 'market_products';
  static const String storesTable = 'market_stores';
  static const String livesTable = 'market_lives';

  Future<List<MarketCategory>> listCategories({int limit = 16}) async {
    try {
      final rows = await SupabaseService.select(categoriesTable, orderBy: 'sort_order', ascending: true, limit: limit);
      return rows.map(MarketCategory.fromJson).toList(growable: false);
    } catch (e) {
      debugPrint('ThixMarketService.listCategories failed: $e');
      rethrow;
    }
  }

  Future<List<MarketProduct>> listFlashProducts({int limit = 20}) async {
    try {
      final rows = await SupabaseService.select(
        productsTable,
        filters: const {'is_flash': true},
        orderBy: 'updated_at',
        ascending: false,
        limit: limit,
      );
      return rows.map(MarketProduct.fromJson).toList(growable: false);
    } catch (e) {
      debugPrint('ThixMarketService.listFlashProducts failed: $e');
      rethrow;
    }
  }

  Future<List<MarketStore>> listRecommendedStores({int limit = 12}) async {
    try {
      final rows = await SupabaseService.select(storesTable, orderBy: 'rating', ascending: false, limit: limit);
      return rows.map(MarketStore.fromJson).toList(growable: false);
    } catch (e) {
      debugPrint('ThixMarketService.listRecommendedStores failed: $e');
      rethrow;
    }
  }

  Future<List<MarketLive>> listLives({int limit = 12}) async {
    try {
      final rows = await SupabaseService.select(livesTable, orderBy: 'started_at', ascending: false, limit: limit);
      return rows.map(MarketLive.fromJson).toList(growable: false);
    } catch (e) {
      debugPrint('ThixMarketService.listLives failed: $e');
      rethrow;
    }
  }

  Future<List<MarketProduct>> listProducts({int limit = 60, String? categoryId}) async {
    try {
      final filters = <String, dynamic>{};
      if (categoryId != null && categoryId.trim().isNotEmpty) filters['category_id'] = categoryId.trim();
      final rows = await SupabaseService.select(productsTable, filters: filters.isEmpty ? null : filters, orderBy: 'updated_at', ascending: false, limit: limit);
      return rows.map(MarketProduct.fromJson).toList(growable: false);
    } catch (e) {
      debugPrint('ThixMarketService.listProducts failed: $e');
      rethrow;
    }
  }

  /// Simple helper: current user id (if logged in)
  String? get currentUserId => SupabaseConfig.currentUser?.id;
}
