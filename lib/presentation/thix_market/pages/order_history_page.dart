import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});
  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  String? _error;
  String _filter = 'all';
  
  static const Color primaryBlue = Color(0xFF1A73E8);

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final uid = supabase.auth.currentUser!.id;
      
      var q = supabase.from('orders').select().eq('user_id', uid);
      if (_filter != 'all') q = q.eq('status', _filter);
      
      final res = await q.order('created_at', ascending: false);
      final List<Map<String, dynamic>> ordersList = List<Map<String, dynamic>>.from(res as List);

      final List<Map<String, dynamic>> fullOrders = [];
      for (var o in ordersList) {
        final items = List<Map<String, dynamic>>.from(
          await supabase.from('order_items').select().eq('order_id', o['id'])
        );
        
        Map<String, dynamic>? shop;
        if (o['shop_id'] != null) {
          shop = await supabase.from('shops').select('name, logo_url, owner_id').eq('id', o['shop_id']).maybeSingle();
          if (shop != null && shop['owner_id'] != null) {
            final prof = await supabase.from('profiles').select('full_name').eq('id', shop['owner_id']).maybeSingle();
            if (prof != null) shop['vendor_name'] = prof['full_name'];
          }
        }
        fullOrders.add({...o, 'items': items, 'shop': shop});
      }
      if (mounted) setState(() { _orders = fullOrders; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _cancelOrder(String orderId) async {
    final confirm = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Annuler la commande ?'),
      content: const Text('Cette action est irréversible.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Non')),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(context, true), child: const Text('Oui', style: TextStyle(color: Colors.white)))
      ],
    ));
    if (confirm != true) return;
    try {
      await Supabase.instance.client.from('orders').update({'status': 'cancelled'}).eq('id', orderId);
      _loadOrders();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Commande annulée')));
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'))); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Historique', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, elevation: 0.5,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadOrders)],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(50), child: _buildFilters()),
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) 
            : _orders.isEmpty ? const Center(child: Text('Aucune commande')) 
            : RefreshIndicator(onRefresh: _loadOrders, child: ListView.builder(padding: const EdgeInsets.all(12), itemCount: _orders.length, itemBuilder: (_, i) => _card(_orders[i]))),
    );
  }

  Widget _buildFilters() {
    final f = [{'k':'all','l':'Tous'},{'k':'pending','l':'En attente'},{'k':'processing','l':'Préparation'},{'k':'shipped','l':'Expédiée'},{'k':'delivered','l':'Livrée'}];
    return SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), 
      child: Row(children: f.map((e){ final sel=_filter==e['k']; return Padding(padding: const EdgeInsets.only(right:8), child: ChoiceChip(label: Text(e['l']!), selected: sel, selectedColor: primaryBlue, onSelected: (_){ setState(()=> _filter=e['k']!); _loadOrders(); })); }).toList()));
  }

  Widget _card(Map<String, dynamic> o) {
    final status = o['status'] ?? 'pending';
    final total = (o['total'] as num?)?.toDouble() ?? 0;
    final items = List<Map<String, dynamic>>.from(o['items'] ?? []);
    final shop = o['shop'] as Map?;
    final currency = o['currency'] ?? 'XOF';

    return Card(margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(onTap: () => context.pushNamed('marketOrderDetail', pathParameters: {'orderId': o['id'].toString()}), borderRadius: BorderRadius.circular(12),
        child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Commande #${o['id'].toString().substring(0, 8)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(status.toUpperCase(), style: TextStyle(color: status=='delivered'?Colors.green:Colors.orange, fontWeight: FontWeight.bold, fontSize: 12))
          ]),
          const SizedBox(height: 10),
          if(shop != null) Text('Vendeur: ${shop['vendor_name'] ?? shop['name']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ...items.take(1).map((it) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: ClipRRect(borderRadius: BorderRadius.circular(4), child: CachedNetworkImage(imageUrl: it['product_image'] ?? '', width: 40, height: 40, fit: BoxFit.cover)),
            title: Text(it['product_name'] ?? 'Produit', style: const TextStyle(fontSize: 14)),
            subtitle: Text('${it['quantity']} x ${it['price']} $currency'),
          )),
          const Divider(),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('${total.toInt()} $currency', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryBlue))
          ]),
          if(status == 'pending') OutlinedButton(onPressed: () => _cancelOrder(o['id']), child: const Text('Annuler'))
        ]))));
  }
}
