import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});
  @override 
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  List<Map<String,dynamic>> _orders = [];
  bool _loading = true;
  String _filter = 'all';

  static const navy = Color(0xFF0A1931);
  static const red = Color(0xFFD81E2C);
  static const gold = Color(0xFFF0A93B);
  static const blue = Color(0xFF2D6CDF);
  static const bg = Color(0xFFF7F8FC);

  String _cur(dynamic c) {
    final v = (c ?? 'FC').toString().toUpperCase();
    if (v == 'XOF' || v == 'CDF' || v == 'FCFA') return 'FC';
    if (v == '\$') return 'USD';
    return v;
  }

  Color _statusColor(String s) { 
    switch(s) { 
      case 'delivered': return const Color(0xFF00B074); 
      case 'cancelled': return red; 
      case 'shipped': return blue; 
      case 'confirmed': 
      case 'processing': return const Color(0xFF8B5CF6); 
      default: return gold; 
    }
  }

  String _statusLabel(String s) { 
    switch(s) { 
      case 'pending': return 'En attente'; 
      case 'confirmed': return 'Confirmée'; 
      case 'processing': return 'Préparation'; 
      case 'shipped': return 'Expédiée'; 
      case 'delivered': return 'Livrée'; 
      case 'cancelled': return 'Annulée'; 
      default: return s; 
    }
  }

  @override
  void initState() { 
    super.initState(); 
    _load(); 
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    
    try {
      final supa = Supabase.instance.client;
      final uid = supa.auth.currentUser!.id;
      
      var q = supa.from('orders').select('*').eq('user_id', uid);
      if (_filter != 'all') q = q.eq('status', _filter);
      
      final res = await q.order('created_at', ascending: false);
      final list = List<Map<String, dynamic>>.from(res as List);
      final full = [];

      for (var o in list) {
        List<dynamic> items = [];
        // 1. Protection de la requête des articles (items)
        try {
          items = await supa.from('order_items')
              .select('*, product:products(title,image_url)')
              .eq('order_id', o['id'])
              .limit(3);
        } catch (e) {
          debugPrint('⚠️ Erreur items pour commande ${o['id']}: $e');
          // Fallback : On essaie de récupérer sans la jointure 'product' si ça crash
          try {
             items = await supa.from('order_items').select('*').eq('order_id', o['id']).limit(3);
          } catch (_) {}
        }

        Map<String, dynamic>? shop;
        // 2. Protection de la requête de la boutique
        if (o['shop_id'] != null) {
          try {
            shop = await supa.from('shops')
                .select('id,name,logo_url,city,ville,is_verified')
                .eq('id', o['shop_id'])
                .maybeSingle();
          } catch (e) {
            debugPrint('⚠️ Erreur shop pour commande ${o['id']}: $e');
            // Fallback : On essaie sans la colonne 'is_verified' si elle n'existe pas
            try {
              shop = await supa.from('shops').select('id,name,logo_url,city,ville').eq('id', o['shop_id']).maybeSingle();
            } catch (_) {}
          }
        }
        
        full.add({...o, 'currency': _cur(o['currency']), 'items': items, 'shop': shop});
      }
      
      if (mounted) {
        setState(() {
          _orders = List<Map<String, dynamic>>.from(full);
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('🚨 ERREUR GLOBALE CHARGEMENT COMMANDES : $e');
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de charger les commandes')),
        );
      }
    }
  }

  Future<void> _cancel(String id) async {
    final ok = await showDialog<bool>(
      context: context, 
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20), 
          child: Column(
            mainAxisSize: MainAxisSize.min, 
            children: [
              Container(
                padding: const EdgeInsets.all(14), 
                decoration: const BoxDecoration(color: Color(0xFFFFF0F0), shape: BoxShape.circle), 
                child: const Icon(Icons.warning_amber_rounded, color: red, size: 32)
              ),
              const SizedBox(height: 14), 
              const Text('Annuler la commande?', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)), 
              const SizedBox(height: 6),
              const Text('Le stock sera rendu à la boutique.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false), 
                      style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), 
                      child: const Text('Garder')
                    )
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true), 
                      style: ElevatedButton.styleFrom(backgroundColor: red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), 
                      child: const Text('Oui, annuler', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800))
                    )
                  ),
                ]
              )
            ]
          )
        ),
      )
    );
    
    if (ok != true) return;
    
    try { 
      await supaRpc(id); 
    } catch (_) { 
      await Supabase.instance.client.from('orders').update({'status':'cancelled'}).eq('id', id); 
    }
    _load();
  }

  Future supaRpc(String id) => Supabase.instance.client.rpc(
    'cancel_order', 
    params: {'p_order_id': id, 'p_reason_code': 'client_request', 'p_reason': 'Client depuis historique'}
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0, scrolledUnderElevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: navy), onPressed: () => context.pop()),
        title: const Text('Mes commandes', style: TextStyle(fontWeight: FontWeight.w900, color: navy, fontSize: 18)),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded, color: navy))],
      ),
      body: Column(
        children: [
          _filterBar(),
          Expanded(
            child: _loading 
              ? const Center(child: CircularProgressIndicator(color: navy))
              : _orders.isEmpty 
                  ? _empty()
                  : RefreshIndicator(
                      color: navy, 
                      onRefresh: _load, 
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24), 
                        itemCount: _orders.length, 
                        itemBuilder: (_, i) => _orderCard(_orders[i])
                      )
                    )
          ),
        ]
      ),
    );
  }

  Widget _filterBar() {
    final tabs = [
      {'k': 'all', 'l': 'Tous'},
      {'k': 'pending', 'l': 'En attente'},
      {'k': 'confirmed', 'l': 'Confirmée'},
      {'k': 'shipped', 'l': 'Expédiée'},
      {'k': 'delivered', 'l': 'Livrée'},
      {'k': 'cancelled', 'l': 'Annulée'}
    ];
    return Container(
      color: Colors.white, 
      padding: const EdgeInsets.only(bottom: 10), 
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal, 
        padding: const EdgeInsets.symmetric(horizontal: 12), 
        child: Row(
          children: tabs.map((t) {
            final sel = _filter == t['k'];
            return GestureDetector(
              onTap: () { setState(() => _filter = t['k']!); _load(); }, 
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200), 
                margin: const EdgeInsets.only(right: 8), 
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  color: sel ? navy : const Color(0xFFF3F4F6), 
                  borderRadius: BorderRadius.circular(24), 
                  border: sel ? null : Border.all(color: const Color(0xFFE5E7EB))
                ),
                child: Text(
                  t['l']!, 
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: sel ? Colors.white : const Color(0xFF6B7280))
                )
              )
            ); 
          }).toList()
        )
      )
    );
  }

  Widget _empty() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center, 
      children: [
        Container(
          padding: const EdgeInsets.all(26), 
          decoration: BoxDecoration(
            color: Colors.white, 
            shape: BoxShape.circle, 
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16)]
          ), 
          child: const Icon(Icons.receipt_long_rounded, size: 56, color: Color(0xFFD1D5DB))
        ),
        const SizedBox(height: 14), 
        const Text('Aucune commande', style: TextStyle(fontWeight: FontWeight.w800, color: navy)), 
        const SizedBox(height: 6), 
        const Text('Vos commandes apparaîtront ici', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
      ]
    )
  );

  Widget _orderCard(Map<String,dynamic> o) {
    final status = (o['status'] ?? 'pending').toString();
    final total = ((o['total'] ?? o['total_amount'] ?? 0) as num).toDouble();
    final items = List<Map<String, dynamic>>.from(o['items'] ?? []);
    final shop = o['shop'] as Map?;
    final cur = _cur(o['currency']);
    final shopName = shop?['name'] ?? 'Boutique';
    final city = shop?['city'] ?? shop?['ville'] ?? 'RDC';
    final date = DateTime.tryParse(o['created_at'].toString());
    final color = _statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20), 
        border: Border.all(color: const Color(0xFFF0F0F0)), 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 3))]
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0), 
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, 
              children: [
                Row(
                  children: [
                    Container(
                      width: 36, height: 36, 
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6), 
                        borderRadius: BorderRadius.circular(10), 
                        image: shop?['logo_url'] != null ? DecorationImage(image: NetworkImage(shop!['logo_url']), fit: BoxFit.cover) : null
                      ), 
                      child: shop?['logo_url'] == null ? const Icon(Icons.storefront_rounded, size: 18, color: Color(0xFF9CA3AF)) : null
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start, 
                      children: [
                        Row(
                          children: [ 
                            Flexible(child: Text(shopName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: navy))), 
                            if (shop?['is_verified'] == true) ...[const SizedBox(width: 4), const Icon(Icons.verified_rounded, size: 12, color: blue)] 
                          ]
                        ),
                        Row(
                          children: [ 
                            const Icon(Icons.location_on_outlined, size: 11, color: Color(0xFF9CA3AF)), 
                            const SizedBox(width: 2), 
                            Text(city, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))) 
                          ]
                        ),
                      ]
                    )
                  ]
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), 
                  decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)), 
                  child: Row(
                    mainAxisSize: MainAxisSize.min, 
                    children: [ 
                      Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), 
                      const SizedBox(width: 5), 
                      Text(_statusLabel(status), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color)) 
                    ]
                  )
                ),
              ]
            )
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14), 
            child: Divider(height: 22, color: Color(0xFFF3F4F6))
          ),

          // Items preview
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14), 
            child: Column(
              children: items.take(2).map((it) {
                final img = it['product_image'] ?? it['product']?['image_url'] ?? '';
                final name = it['product_name'] ?? it['product']?['title'] ?? 'Produit';
                final qty = it['quantity'] ?? 1; 
                final price = (it['price'] as num?)?.toInt() ?? 0;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8), 
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10), 
                        child: Image.network(
                          img, 
                          width: 48, height: 48, fit: BoxFit.cover, 
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Container(width: 48, height: 48, color: const Color(0xFFF3F4F6), child: const Center(child: CircularProgressIndicator(strokeWidth: 2)));
                          },
                          errorBuilder: (_, __, ___) => Container(width: 48, height: 48, color: const Color(0xFFF3F4F6), child: const Icon(Icons.image_outlined, size: 18))
                        )
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start, 
                          children: [
                            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: navy)),
                            const SizedBox(height: 2),
                            Text('$qty x $price $cur', style: const TextStyle(fontSize: 11.5, color: Color(0xFF6B7280))),
                          ]
                        )
                      ),
                    ]
                  )
                );
              }).toList()
            )
          ),

          if(items.length > 2) 
            Padding(
              padding: const EdgeInsets.only(left: 14, right: 14, bottom: 4), 
              child: Align(
                alignment: Alignment.centerLeft, 
                child: Text('+ ${items.length - 2} article(s)', style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF), fontStyle: FontStyle.italic))
              )
            ),

          // Footer Total + Actions
          Container(
            margin: const EdgeInsets.fromLTRB(14, 8, 14, 14), 
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), 
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB), 
              borderRadius: BorderRadius.circular(14), 
              border: Border.all(color: const Color(0xFFF0F0F0))
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, 
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start, 
                  children: [
                    Text(date != null ? '${date.day}/${date.month}/${date.year}' : '', style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                    const SizedBox(height: 2),
                    Text('#${o['id'].toString().substring(0, 8).toUpperCase()}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: navy)),
                  ]
                ),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end, 
                      children: [
                        const Text('Total', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))), 
                        const SizedBox(height: 1),
                        Text('${total.toInt()} $cur', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: navy)),
                      ]
                    ),
                    const SizedBox(width: 12),
                    if (status == 'pending' || status == 'confirmed')
                      InkWell(
                        onTap: () => _cancel(o['id']), 
                        borderRadius: BorderRadius.circular(10), 
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), 
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFFFD0D0))), 
                          child: const Text('Annuler', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: red))
                        )
                      ),
                    if (status != 'pending' && status != 'confirmed')
                      InkWell(
                        onTap: () => context.pushNamed('marketOrderDetail', pathParameters: {'orderId': o['id'].toString()}), 
                        borderRadius: BorderRadius.circular(10), 
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), 
                          decoration: BoxDecoration(color: navy, borderRadius: BorderRadius.circular(10)), 
                          child: const Text('Détails', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white))
                        )
                      ),
                  ]
                )
              ]
            ),
          )
        ]
      ),
    );
  }
}
