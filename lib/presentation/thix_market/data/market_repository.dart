import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) => Supabase.instance.client);
final marketRepositoryProvider = Provider<MarketRepository>((ref) => MarketRepository(ref.watch(supabaseClientProvider)));

class MarketRepository {
  final SupabaseClient db;
  MarketRepository(this.db);
  static const _cols = 'id,title,price,discount_price,original_price,currency,image_url,images,rating,reviews_count,shop_id,shop_name,city,is_flash_sale,discount_percent,created_at';

  Future<List<Map<String, dynamic>>> fetchProducts({int page=0,int limit=20,bool flashOnly=false,String orderBy='created_at'}) async {
    final from = page*limit;
    final to = from+limit-1;
    var q = db.from('products').select(_cols).eq('status','active');
    if(flashOnly) q = q.eq('is_flash_sale', true);
    final res = orderBy=='rating'? await q.order('rating', ascending: false).range(from,to) : await q.order('created_at', ascending: false).range(from,to);
    return (res as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> fetchBanners() async {
    final res = await db.from('promo_banners').select('id,title,subtitle,image_url').eq('active', true).order('display_order').limit(5);
    return (res as List).cast<Map<String, dynamic>>();
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
    final r = await db.from('notifications').select('id').eq('user_id', uid).eq('is_read', false).count(CountOption.exact);
    return r.count;
  }
}
