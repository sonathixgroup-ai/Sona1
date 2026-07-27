import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/market_providers.dart';

final myAnnouncementsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final db = ref.read(supabaseClientProvider);
  final uid = db.auth.currentUser?.id;
  if(uid==null) return [];
  final res = await db.from('products').select().eq('owner_id', uid).order('created_at', ascending: false);
  return List<Map<String,dynamic>>.from(res);
});

final myOrdersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final db = ref.read(supabaseClientProvider);
  final uid = db.auth.currentUser?.id;
  if(uid==null) return [];
  final res = await db.from('orders').select().eq('seller_id', uid).order('created_at', ascending: false).limit(100);
  return List<Map<String,dynamic>>.from(res);
});

final myLivesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final db = ref.read(supabaseClientProvider);
  final uid = db.auth.currentUser?.id;
  if(uid==null) return [];
  final res = await db.from('lives').select().eq('host_id', uid).order('created_at', ascending: false);
  return List<Map<String,dynamic>>.from(res);
});

final sellerStatsProvider = FutureProvider<Map<String,dynamic>>((ref) async {
  final orders = await ref.watch(myOrdersProvider.future);
  final ann = await ref.watch(myAnnouncementsProvider.future);
  final totalSales = orders.length;
  int revenue = 0;
  for(final o in orders){ revenue += ((o['total'] as num?)?.toInt()?? 0); }
  int views = 0;
  for(final a in ann){ views += ((a['views'] as num?)?.toInt()?? 0); }
  final conv = ann.isEmpty? 0.0 : (totalSales / ann.length * 100).clamp(0,100).toDouble();
  return {
    'total_sales': totalSales,
    'revenue': revenue,
    'total_views': views,
    'conversion_rate': conv,
    'sales_data': List.generate(6, (i){
      final d = DateTime.now().subtract(Duration(days: (5-i)*30));
      return {'label': DateFormat('MMM').format(d), 'value': (i+1) * (revenue>0? revenue/6.0 : 10.0)};
    }),
    'top_products': ann.take(5).map((e)=> {'image_url': e['image_url'], 'name': e['title'], 'sales': e['views']??0, 'revenue': e['price']??0}).toList(),
  };
});

class SellPage extends ConsumerStatefulWidget {
  const SellPage({super.key});
  @override ConsumerState<SellPage> createState() => _SellPageState();
}

class _SellPageState extends ConsumerState<SellPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  @override void initState(){ super.initState(); _tabController = TabController(length: 4, vsync: this); _tabController.addListener(()=> setState((){})); }
  Future<void> _refresh() async { ref.invalidate(myAnnouncementsProvider); ref.invalidate(myOrdersProvider); ref.invalidate(myLivesProvider); ref.invalidate(sellerStatsProvider); }
  @override void dispose(){ _tabController.dispose(); super.dispose(); }

  @override Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('Espace Vendeur', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF1A1D29))),
        backgroundColor: Colors.white, elevation: 0,
        bottom: TabBar(controller: _tabController, tabs: const [Tab(text: 'Annonces'), Tab(text: 'Commandes'), Tab(text: 'Stats'), Tab(text: 'Lives')], indicatorColor: Color(0xFF1A73E8), labelColor: Color(0xFF1A73E8), unselectedLabelColor: Colors.grey),
        actions: [IconButton(icon: const Icon(Icons.refresh, color: Colors.black87), onPressed: _refresh)],
      ),
      body: TabBarView(controller: _tabController, children: [_annoncesTab(), _ordersTab(), _statsTab(), _livesTab()]),
      floatingActionButton: _tabController.index==0 || _tabController.index==3? FloatingActionButton.extended(
        onPressed: _tabController.index==0? ()=> context.push('/market/announcement/publish') : ()=> context.push('/market/live/create'),
        backgroundColor: const Color(0xFF1A73E8),
        icon: Icon(_tabController.index==0? Icons.add : Icons.videocam, color: Colors.white),
        label: Text(_tabController.index==0? 'Publier' : 'Créer un live', style: const TextStyle(color: Colors.white)),
      ) : null,
    );
  }

  Widget _annoncesTab(){
    final async = ref.watch(myAnnouncementsProvider);
    return async.when(
      loading: ()=> const Center(child: CircularProgressIndicator()),
      error: (e,_ )=> Center(child: Text('Erreur $e')),
      data: (list){
        if(list.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.sell, size: 72, color: Colors.grey.shade300), const SizedBox(height: 12), const Text('Aucune annonce'), const SizedBox(height: 12), ElevatedButton(onPressed: ()=> context.push('/market/announcement/publish'), style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF1A73E8)), child: Text('Publier', style: TextStyle(color: Colors.white)))]));
        return RefreshIndicator(onRefresh: _refresh, child: ListView.builder(padding: const EdgeInsets.all(12), itemCount: list.length, itemBuilder: (_,i)=> _announcementCard(list[i])));
      },
    );
  }

  Widget _announcementCard(Map<String,dynamic> ann){
    final statusColors = {'active': Colors.green, 'pending': Colors.orange, 'expired': Colors.grey, 'refused': Colors.red};
    final status = (ann['status'] as String?)?? 'active';
    final priceVal = (ann['price'] as num?)?.toInt()?? 0;
    final discountVal = (ann['discount_price'] as num?)?.toInt();
    final hasDiscount = discountVal!=null && discountVal < priceVal;
    final displayPrice = hasDiscount? discountVal : priceVal;
    final images = ann['images'] is List? List.from(ann['images']) : [];
    final img = ann['image_url']?? (images.isNotEmpty? images.first : null);
    return Card(margin: const EdgeInsets.only(bottom: 12), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)), child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        ClipRRect(borderRadius: BorderRadius.circular(8), child: img==null? Container(width: 80, height: 80, color: Colors.grey.shade200, child: const Icon(Icons.image, color: Colors.grey)) : Image.network(img.toString(), width: 80, height: 80, fit: BoxFit.cover, errorBuilder: (a,b,c)=> Container(width: 80, height: 80, color: Colors.grey.shade200, child: const Icon(Icons.image)))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text((ann['title'] as String?)?? 'Sans titre', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 4),
          Row(children: [
            Text('$displayPrice FCFA', style: const TextStyle(color: Color(0xFF1A73E8), fontWeight: FontWeight.bold)),
            if(hasDiscount) Padding(padding: const EdgeInsets.only(left: 6), child: Text('$priceVal FCFA', style: TextStyle(decoration: TextDecoration.lineThrough, fontSize: 12, color: Colors.grey.shade500))),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: (statusColors[status]?? Colors.grey).withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: Text(status, style: TextStyle(color: statusColors[status], fontSize: 11))),
            const SizedBox(width: 8),
            Text('Vues: ${ann['views']??0}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ]),
        ])),
      ]),
      const Divider(height: 20),
      Row(children: [
        Expanded(child: OutlinedButton.icon(onPressed: ()=> context.push('/market/announcement/${ann['id']}/edit'), icon: const Icon(Icons.edit, size: 18), label: const Text('Modifier'))),
        const SizedBox(width: 8),
        Expanded(child: OutlinedButton.icon(onPressed: ()=> _showBoost(ann['id'].toString()), icon: const Icon(Icons.trending_up, size: 18), label: const Text('Booster'))),
        const SizedBox(width: 8),
        Expanded(child: OutlinedButton.icon(onPressed: (){}, icon: const Icon(Icons.share, size: 18), label: const Text('Partager'))),
      ]),
    ])));
  }

  Widget _ordersTab(){
    final async = ref.watch(myOrdersProvider);
    return async.when(
      loading: ()=> const Center(child: CircularProgressIndicator()),
      error: (e,_ )=> Center(child: Text('Erreur $e')),
      data: (orders){
        if(orders.isEmpty) return const Center(child: Text('Aucune commande'));
        final pending = orders.where((o)=> o['status']=='pending').toList();
        final preparing = orders.where((o)=> o['status']=='preparing').toList();
        final shipped = orders.where((o)=> o['status']=='shipped').toList();
        final completed = orders.where((o)=> o['status']=='completed').toList();
        return DefaultTabController(length: 4, child: Column(children: [
          const TabBar(tabs: [Tab(text: 'À traiter'), Tab(text: 'Préparation'), Tab(text: 'Expédiées'), Tab(text: 'Terminées')], isScrollable: true, indicatorColor: Color(0xFF1A73E8), labelColor: Color(0xFF1A73E8), unselectedLabelColor: Colors.grey),
          Expanded(child: TabBarView(children: [_orderList(pending), _orderList(preparing), _orderList(shipped), _orderList(completed)])),
        ]));
      },
    );
  }

  Widget _orderList(List<Map<String,dynamic>> orders){
    if(orders.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.inbox, size: 64, color: Colors.grey.shade300), const SizedBox(height: 12), Text('Aucune commande', style: TextStyle(color: Colors.grey.shade600))]));
    return ListView.builder(padding: const EdgeInsets.all(12), itemCount: orders.length, itemBuilder: (_,i){
      final o = orders[i];
      final total = (o['total'] as num?)?.toInt()?? 0;
      return Card(margin: const EdgeInsets.only(bottom: 12), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)), child: ListTile(onTap: ()=> context.push('/market/order/${o['id']}'), title: Text('Commande #${o['id'].toString().substring(0,8)}', style: const TextStyle(fontWeight: FontWeight.w600)), subtitle: Text('$total FCFA'), trailing: Text((o['status'] as String?)?? '', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))));
    });
  }

  Widget _statsTab(){
    final async = ref.watch(sellerStatsProvider);
    return async.when(
      loading: ()=> const Center(child: CircularProgressIndicator()),
      error: (e,_ )=> Center(child: Text('Erreur $e')),
      data: (stats){
        final salesData = (stats['sales_data'] as List).map((e)=> (e['value'] as num).toDouble()).toList();
        final labels = (stats['sales_data'] as List).map((e)=> (e['label'] as String)).toList();
        return SingleChildScrollView(padding: const EdgeInsets.all(12), child: Column(children: [
          GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.1, children: [
            _statCard('Ventes totales', '${stats['total_sales']}', Icons.trending_up, Colors.green),
            _statCard('Chiffre', '${stats['revenue']} CDF', Icons.attach_money, const Color(0xFF1A73E8)),
            _statCard('Vues', '${stats['total_views']}', Icons.visibility, Colors.purple),
            _statCard('Conversion', '${(stats['conversion_rate'] as double).toStringAsFixed(1)}%', Icons.percent, Colors.orange),
          ]),
          const SizedBox(height: 16),
          Card(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Ventes mensuelles', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(height: 200, child: LineChart(LineChartData(gridData: const FlGridData(show: false), titlesData: FlTitlesData(bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v,m){ final idx=v.toInt(); if(idx>=0 && idx<labels.length) return Text(labels[idx], style: const TextStyle(fontSize: 10)); return const Text(''); }, reservedSize: 24)), leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false))), lineBarsData: [LineChartBarData(spots: List.generate(salesData.length, (i)=> FlSpot(i.toDouble(), salesData[i])), isCurved: true, color: const Color(0xFF1A73E8), barWidth: 3, dotData: const FlDotData(show: false), belowBarData: BarAreaData(show: true, color: const Color(0xFF1A73E8).withOpacity(0.1)))]))),
          ]))),
        ]));
      },
    );
  }

  Widget _statCard(String t, String v, IconData ic, Color c){
    return Card(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)), child: Padding(padding: const EdgeInsets.all(12), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(ic, color: c, size: 28), const SizedBox(height: 6), Text(v, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis), Text(t, style: TextStyle(fontSize: 11, color: Colors.grey.shade600), textAlign: TextAlign.center)])));
  }

  Widget _livesTab(){
    final async = ref.watch(myLivesProvider);
    return async.when(
      loading: ()=> const Center(child: CircularProgressIndicator()),
      error: (e,_ )=> Center(child: Text('Erreur $e')),
      data: (lives){
        if(lives.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.live_tv, size: 80, color: Colors.grey.shade300), const SizedBox(height: 16), const Text('Aucun live', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 8), Text('Créez votre premier live', style: TextStyle(color: Colors.grey.shade600)), const SizedBox(height: 24), ElevatedButton.icon(onPressed: ()=> context.push('/market/live/create'), icon: const Icon(Icons.videocam), label: const Text('Démarrer un live'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A73E8)))]));
        return RefreshIndicator(onRefresh: _refresh, child: ListView.builder(padding: const EdgeInsets.all(12), itemCount: lives.length, itemBuilder: (_,i){
          final live = lives[i];
          final isLive = live['status']=='live';
          final thumb = live['thumbnail'] as String?;
          return Card(margin: const EdgeInsets.only(bottom: 12), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)), child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
            ClipRRect(borderRadius: BorderRadius.circular(8), child: thumb==null? Container(width: 80, height: 80, color: Colors.grey.shade200, child: const Icon(Icons.live_tv, color: Colors.grey)) : Image.network(thumb, width: 80, height: 80, fit: BoxFit.cover, errorBuilder: (a,b,c)=> Container(width: 80, height: 80, color: Colors.grey.shade200, child: const Icon(Icons.live_tv))))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Expanded(child: Text((live['title'] as String?)?? 'Live', style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)), if(isLive) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)), child: const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))]),
              const SizedBox(height: 4),
              Text(DateFormat('dd/MM/yyyy HH:mm').format(DateTime.tryParse((live['created_at'] as String?)?? '')?? DateTime.now()), style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              const SizedBox(height: 8),
              Row(children: [
                if(isLive) Expanded(child: ElevatedButton.icon(onPressed: ()=> context.push('/market/live/${live['id']}'), icon: const Icon(Icons.visibility, size: 16), label: const Text('Voir', style: TextStyle(fontSize: 12)), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53935), foregroundColor: Colors.white))),
                if(!isLive) Expanded(child: OutlinedButton.icon(onPressed: ()=> context.push('/market/live/${live['id']}/replay'), icon: const Icon(Icons.replay, size: 16), label: const Text('Replay', style: TextStyle(fontSize: 12)))),
                const SizedBox(width: 8),
                Expanded(child: OutlinedButton.icon(onPressed: ()=> context.push('/market/live/${live['id']}/stats'), icon: const Icon(Icons.bar_chart, size: 16), label: const Text('Stats', style: TextStyle(fontSize: 12)))),
              ]),
            ])),
          ])));
        }));
      },
    );
  }

  void _showBoost(String id){
    showModalBottomSheet(context: context, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (c)=> Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('Booster votre annonce', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      ListTile(title: const Text('Standard - 2500 FCFA'), subtitle: const Text('5 000 vues garanties'), onTap: ()=> Navigator.pop(context)),
      ListTile(title: const Text('Premium - 5000 FCFA'), subtitle: const Text('15 000 vues garanties'), onTap: ()=> Navigator.pop(context)),
      ListTile(title: const Text('VIP - 10000 FCFA'), subtitle: const Text('50 000 vues garanties'), onTap: ()=> Navigator.pop(context)),
    ])));
  }
}
