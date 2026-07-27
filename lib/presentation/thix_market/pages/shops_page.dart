import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../providers/shop_provider.dart';

class ShopsPage extends ConsumerStatefulWidget {
  const ShopsPage({super.key});
  @override ConsumerState<ShopsPage> createState() => _ShopsPageState();
}

class _ShopsPageState extends ConsumerState<ShopsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const Color navy = Color(0xFF1B2A4A);
  static const Color navyDeep = Color(0xFF10192E);
  static const Color gold = Color(0xFFC9962C);
  static const Color bgApp = Color(0xFFF6F7FB);
  static const Color textMuted = Color(0xFF8A8FA3);
  static const Color danger = Color(0xFFE53935);

  @override void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    Future.microtask(_loadData);
  }

  Future<void> _loadData() async {
    ref.invalidate(myShopsProvider);
    ref.invalidate(followedShopsProvider);
  }

  @override void dispose() { _tabController.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgApp,
      appBar: AppBar(
        title: const Text('Mes Boutiques', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19, color: Color(0xFF1A1D29))),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Mes boutiques'), Tab(text: 'Boutiques suivies')],
          indicatorColor: gold,
          indicatorWeight: 3,
          labelColor: navy,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          unselectedLabelColor: textMuted,
        ),
        actions: [
          if (_tabController.index == 0) IconButton(icon: const Icon(Icons.add_circle_outline, color: navy), onPressed: () => context.push('/market/shop/create')),
          IconButton(icon: const Icon(Icons.refresh_rounded, color: navy), onPressed: _loadData),
        ],
      ),
      body: TabBarView(controller: _tabController, children: [_buildMyShops(), _buildFollowed()]),
    );
  }

  Widget _buildMyShops() {
    final async = ref.watch(myShopsProvider);
    return async.when(
      loading: ()=> const Center(child: CircularProgressIndicator(color: gold)),
      error: (e,_ )=> Center(child: Text('Erreur $e')),
      data: (shops){
        if(shops.isEmpty) return _empty('Vous n\'avez pas encore de boutique','Créez votre première boutique pour commencer à vendre', Icons.store_outlined, ()=> context.push('/market/shop/create'));
        return RefreshIndicator(color: gold, onRefresh: () async => _loadData(), child: ListView.builder(padding: const EdgeInsets.all(12), itemCount: shops.length, itemBuilder: (_, i)=> _shopCard(shops[i], isOwner: true)));
      },
    );
  }

  Widget _buildFollowed() {
    final async = ref.watch(followedShopsProvider);
    return async.when(
      loading: ()=> const Center(child: CircularProgressIndicator(color: gold)),
      error: (e,_ )=> Center(child: Text('Erreur $e')),
      data: (shops){
        if(shops.isEmpty) return _empty('Aucune boutique suivie','Suivez des boutiques pour voir leurs nouveautés', Icons.favorite_border_rounded, ()=> context.push('/market/search'));
        return RefreshIndicator(color: gold, onRefresh: () async => _loadData(), child: ListView.builder(padding: const EdgeInsets.all(12), itemCount: shops.length, itemBuilder: (_, i)=> _shopCard(shops[i], isOwner: false)));
      },
    );
  }

  Widget _shopCard(Map<String, dynamic> shop, {required bool isOwner}) {
    final isActive = shop['status'] == 'active';
    final isVerified = shop['is_verified'] == true;
    final followers = (shop['followers'] as num?)?.toInt()?? 0;
    final productsCount = (shop['products_count'] as num?)?.toInt()?? (shop['products'] is List? (shop['products'] as List).length : 0);
    final rating = (shop['rating'] as num?)?.toDouble()?? 0;
    final isLive = shop['is_live']==true || shop['live_status']=='live';
    final liveId = shop['current_live_id']?? shop['live_id'];
    final logo = shop['logo_url'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: isLive? Border.all(color: danger.withValues(alpha: 0.4), width: 1.4) : null, boxShadow: [BoxShadow(color: navy.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0,6))]),
      child: InkWell(
        onTap: ()=> context.push('/market/shop/${shop['id']}'),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if(isLive) Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: danger, borderRadius: BorderRadius.circular(6)), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.fiber_manual_record, size: 8, color: Colors.white), SizedBox(width: 4), Text('EN DIRECT MAINTENANT', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.4))])),
            Row(children: [
              Stack(children: [
                Container(
                  width: 62,height: 62,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: bgApp, border: Border.all(color: isLive? danger.withValues(alpha: 0.5) : Colors.grey.shade200, width: isLive?1.5:1)),
                  child: logo==null || logo.isEmpty
                   ? const Icon(Icons.store_rounded, size: 28, color: textMuted)
                    : ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(logo, fit: BoxFit.cover, errorBuilder: (_,__,___)=> const Icon(Icons.store_rounded, size: 28, color: textMuted))),
                ),
                if(isVerified) Positioned(bottom: -2,right: -2, child: Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.verified_rounded, size: 17, color: navy))),
                if(!isActive) Positioned(top: 0,right: 0, child: Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2), decoration: BoxDecoration(color: danger, borderRadius: BorderRadius.circular(6)), child: const Text('Inactif', style: TextStyle(color: Colors.white, fontSize: 8.5)))),
              ]),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(shop['name']?? 'Boutique', style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: Color(0xFF1A1D29)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  if(!isOwner) Consumer(builder: (context, ref, _){
                    final cur = ref.watch(currentShopProvider).valueOrNull;
                    final followed = cur!=null && cur['id']==shop['id']? cur['is_followed']==true : false;
                    return IconButton(onPressed: ()=> ref.read(currentShopProvider.notifier).toggleFollow(shop['id']), icon: Icon(followed? Icons.favorite_rounded : Icons.favorite_border_rounded, color: followed? danger : Colors.grey.shade400, size: 21), padding: EdgeInsets.zero, constraints: const BoxConstraints());
                  }),
                ]),
                const SizedBox(height: 2),
                RatingBar.builder(initialRating: rating, minRating: 1, direction: Axis.horizontal, allowHalfRating: true, itemCount: 5, itemSize: 13, ignoreGestures: true, itemBuilder: (_, __)=> const Icon(Icons.star_rounded, color: gold), onRatingUpdate: (_){}),
                const SizedBox(height: 4),
                Row(children: [const Icon(Icons.shopping_bag_outlined, size: 13, color: textMuted), const SizedBox(width: 4), Text('$productsCount produits', style: const TextStyle(fontSize: 11.5, color: textMuted)), const SizedBox(width: 10), const Icon(Icons.favorite_rounded, size: 13, color: textMuted), const SizedBox(width: 4), Text(_formatNumber(followers), style: const TextStyle(fontSize: 11.5, color: textMuted))]),
              ])),
            ]),
            if(shop['description']!=null && (shop['description'] as String).isNotEmpty)...[const SizedBox(height: 8), Text(shop['description'], maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: textMuted, fontSize: 12.5))],
            if(isOwner)...[
              const SizedBox(height: 14),
              SizedBox(width: double.infinity, child: isLive? ElevatedButton.icon(onPressed: ()=> context.push('/market/live/$liveId'), icon: const Icon(Icons.podcasts_rounded, size: 18), label: const Text('Rejoindre mon live', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)), style: ElevatedButton.styleFrom(backgroundColor: danger, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 11), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))) : ElevatedButton.icon(onPressed: ()=> context.push('/market/shop/${shop['id']}/go-live'), icon: const Icon(Icons.videocam_rounded, size: 18), label: const Text('Démarrer un live', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)), style: ElevatedButton.styleFrom(backgroundColor: navy, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 11), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))))),
              const SizedBox(height: 8),
              Row(children: [Expanded(child: _actionButton(icon: Icons.history_rounded, label: 'Historique', onTap: ()=> context.push('/market/shop/${shop['id']}/history'))), const SizedBox(width: 8), Expanded(child: _actionButton(icon: Icons.podcasts_outlined, label: 'Mes lives', onTap: ()=> context.push('/market/shop/${shop['id']}/lives'))), const SizedBox(width: 8), Expanded(child: _actionButton(icon: Icons.settings_outlined, label: 'Gérer', onTap: ()=> context.push('/market/shop/${shop['id']}/manage')))]),
              const SizedBox(height: 8),
              Row(children: [Expanded(child: _actionButton(icon: Icons.bar_chart_rounded, label: 'Stats', onTap: ()=> context.push('/market/shop/${shop['id']}/stats'))), const SizedBox(width: 8), Expanded(child: _actionButton(icon: Icons.share_rounded, label: 'Partager', onTap: ()=> context.push('/market/shop/${shop['id']}/share')))]),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _actionButton({required IconData icon, required String label, required VoidCallback onTap}){
    return OutlinedButton.icon(onPressed: onTap, icon: Icon(icon, size: 16), label: Text(label, style: const TextStyle(fontSize: 11.5)), style: OutlinedButton.styleFrom(foregroundColor: navy, side: BorderSide(color: Colors.grey.shade300), padding: const EdgeInsets.symmetric(vertical: 9), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9))));
  }

  Widget _empty(String title, String subtitle, IconData icon, VoidCallback onAction){
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 72, color: Colors.grey.shade300), const SizedBox(height: 16), Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1A1D29))), textAlign: TextAlign.center), const SizedBox(height: 6), Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Text(subtitle, style: const TextStyle(color: textMuted, fontSize: 13), textAlign: TextAlign.center)), const SizedBox(height: 22), ElevatedButton(onPressed: onAction, style: ElevatedButton.styleFrom(backgroundColor: gold, foregroundColor: navyDeep, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12)), child: Text(title.contains('pas encore')? 'Créer ma boutique' : 'Découvrir', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)))]));
  }

  String _formatNumber(int num){
    if(num>=1000000) return '${(num/1000000).toStringAsFixed(1)}M';
    if(num>=1000) return '${(num/1000).toStringAsFixed(1)}k';
    return num.toString();
  }
}
