import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MarketRepository {
  final SupabaseClient db;
  MarketRepository(this.db);
  static const _pCols = 'id,title,price,discount_price,currency,image_url,images,rating,shop_name,city,is_flash_sale,discount_percent,created_at,stock';
  static const _sCols = 'id,name,logo_url,city,is_featured,is_supermarket,followers_count';

  Future<List<Map<String,dynamic>>> fetchProducts({int page=0,int limit=20,bool flashOnly=false}) async {
    final from = page*limit;
    final to = from+limit-1;
    var q = db.from('products').select(_pCols).eq('status','active').gt('stock',0);
    if(flashOnly) q = q.eq('is_flash_sale', true);
    final res = await q.order('created_at', ascending: false).range(from,to);
    return (res as List).cast<Map<String,dynamic>>();
  }

  Future<List<Map<String,dynamic>>> fetchBanners() async {
    try{
      final res = await db.from('promo_banners').select('id,title,subtitle,image_url').eq('active', true).order('display_order').limit(5);
      return (res as List).cast<Map<String,dynamic>>();
    }catch(e){ debugPrint('banners $e'); return []; }
  }

  Future<List<Map<String,dynamic>>> fetchFeaturedShops() async {
    try{
      final res = await db.from('shops').select(_sCols).eq('is_featured', true).order('followers_count', ascending: false).limit(8);
      return (res as List).cast<Map<String,dynamic>>();
    }catch(e){ debugPrint('shops $e'); return []; }
  }

  Future<String?> fetchMyShopId() async {
    final uid = db.auth.currentUser?.id;
    if(uid==null) return null;
    final r = await db.from('shops').select('id').eq('owner_id', uid).limit(1).maybeSingle();
    return r?['id'] as String?;
  }

  Future<int> fetchUnread() async {
    final uid = db.auth.currentUser?.id;
    if(uid==null) return 0;
    try{
      final r = await db.from('notifications').select('id').eq('user_id', uid).eq('is_read', false).count(CountOption.exact);
      return r.count;
    }catch(_){ return 0; }
  }
}
