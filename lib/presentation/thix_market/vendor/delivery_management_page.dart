// lib/presentation/thix_market/vendor/vendor_dashboard.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/shop_provider.dart';
import '../providers/sell_provider.dart';

class VendorDashboard extends StatefulWidget {
  const VendorDashboard({super.key});
  @override State<VendorDashboard> createState() => _VendorDashboardState();
}

class _VendorDashboardState extends State<VendorDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['pending','processing','shipped','delivered'];
  final Map<String, String> _labels = {
    'pending':'À traiter',
    'processing':'Préparation',
    'shipped':'Expédiées',
    'delivered':'Terminées',
  };
  final Map<String, Color> _colors = {
    'pending': Color(0xFFF59E0B),
    'processing': Color(0xFF8B5CF6),
    'shipped': Color(0xFF2D6CDF),
    'delivered': Color(0xFF00B074),
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShopProvider>().loadMyShops();
      context.read<SellProvider>().loadOrders();
      context.read<SellProvider>().loadMyAnnouncements();
    });
  }

  Future<void> _advance(String orderId, String next) async {
    try {
      String? note;
      if(next=='cancelled'){
        note = await _askCancelReason();
        if(note==null) return;
      }
      await Supabase.instance.client.rpc('advance_order', params: {
        'p_order_id': orderId,
        'p_next_status': next,
        'p_note': note,
      });
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Commande passée en $next'), backgroundColor: _colors[next]??Color(0xFF0A1931)));
        context.read<SellProvider>().loadOrders();
      }
    } catch(e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
    }
  }

  Future<String?> _askCancelReason() {
    final c = TextEditingController();
    return showDialog<String>(context: context, builder: (_)=> AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Raison annulation', style: TextStyle(fontWeight: FontWeight.w900)),
      content: TextField(controller: c, decoration: const InputDecoration(hintText: 'Rupture stock, etc.', border: OutlineInputBorder())),
      actions: [
        TextButton(onPressed: ()=> Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(onPressed: ()=> Navigator.pop(context, c.text.trim()), style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFD81E2C)), child: const Text('Confirmer', style: TextStyle(color: Colors.white))),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final shopProvider = context.watch<ShopProvider>();
    final sellProvider = context.watch<SellProvider>();
    final hasShop = shopProvider.myShops.isNotEmpty;
    final shop = hasShop? shopProvider.myShops.first : null;
    final orders = sellProvider.orders;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation:0,
        title: const Text('Espace vendeur', style: TextStyle(color: Color(0xFF0A1931), fontWeight: FontWeight.w900, fontSize:18)),
        actions: [IconButton(icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0A1931)), onPressed: ()=> sellProvider.loadOrders())],
        bottom: hasShop? TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Color(0xFF0A1931), unselectedLabelColor: Colors.grey,
          indicatorColor: Color(0xFF0A1931), indicatorWeight: 3,
          tabs: _tabs.map((k){
            final count = orders.where((o)=> (o['status']??'').toString()==k).length;
            return Tab(child: Row(children:[Text(_labels[k]!), if(count>0)...[SizedBox(width:6), Container(padding: EdgeInsets.symmetric(horizontal:6,vertical:2), decoration: BoxDecoration(color: _colors[k]!.withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: Text('$count', style: TextStyle(fontSize:11, fontWeight: FontWeight.w800, color: _colors[k])))]]));
          }).toList(),
        ) : null,
      ),
      body:!hasShop? _buildNoShop(context) : Column(children:[
        _buildHeader(shop!),
        _buildKpis(orders),
        Expanded(child: TabBarView(controller: _tabController, children: _tabs.map((k)=> _buildOrderList(orders.where((o)=> (o['status']??'')==k).toList(), k)).toList())),
      ]),
    );
  }

  Widget _buildHeader(Map<String,dynamic> shop){
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(gradient: const LinearGradient(colors:[Color(0xFF1A73E8), Color(0xFF0D47A1)]), borderRadius: BorderRadius
