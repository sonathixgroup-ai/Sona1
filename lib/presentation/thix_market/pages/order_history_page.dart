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
  static const Color bgLight = Color(0xFFF8F9FA);

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) { setState(() { _orders = []; _isLoading = false; }); return; }

      // 1. On charge les commandes SANS jointure
      var query = supabase.from('orders').select().eq('user_id', userId);
      if (_filter!= 'all') query = query.eq('status', _filter);
      final ordersRes = await query.order('created_at', ascending: false);
      final ordersList = List<Map<String, dynamic>>.from(ordersRes as List);

      // 2. Pour chaque commande, on charge ses items et sa boutique séparément
      final List<Map<String, dynamic>> fullOrders = [];
      for (var order in ordersList) {
        final orderId = order['id'];
        Map<String, dynamic>? shopData;
        List<Map<String, dynamic>> itemsData = [];

        try {
          itemsData = List<Map<String, dynamic>>.from(
            await supabase.from('order_items').select().eq('order_id', orderId)
          );
        } catch (e) { debugPrint('items error $orderId: $e'); }

        try {
          final shopId = order['shop_id'];
          if (shopId!= null) {
            final s = await supabase.from('shops').select('name, logo_url').eq('id', shopId).maybeSingle();
            if (s!= null) shopData = Map<String, dynamic>.from(s);
          }
        } catch (e) { debugPrint('shop error: $e'); }

        fullOrders.add({
         ...order,
          'items': itemsData,
          'shop': shopData,
        });
      }

      setState(() { _orders = fullOrders; _isLoading = false; });
    } catch (e, st) {
      debugPrint('🚨 Erreur commandes: $e\n$st');
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  String _formatDate(String? d){ if(d==null) return ''; try{return DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(d));}catch(_){return d;}}
  Color _getStatusColor(String s){ switch(s){case 'pending':return Colors.orange;case 'processing':return Colors.blue;case 'shipped':return Colors.purple;case 'delivered':return Colors.green;case 'cancelled':return Colors.red;default:return Colors.grey;}}
  String _getStatusLabel(String s){ switch(s){case 'pending':return 'En attente';case 'processing':return 'Préparation';case 'shipped':return 'Expédiée';case 'delivered':return 'Livrée';case 'cancelled':return 'Annulée';default:return s;}}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        title: const Text('Historique des commandes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87)),
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black87), onPressed: () => context.pop()),
        actions: [IconButton(icon: const Icon(Icons.refresh, color: Colors.black87), onPressed: _loadOrders)],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(48), child: _buildFilterChips()),
      ),
      body: _isLoading? const Center(child: CircularProgressIndicator(color: primaryBlue))
          : _error!= null? _buildErrorState()
          : _orders.isEmpty? _buildEmptyState()
          : RefreshIndicator(onRefresh: _loadOrders, color: primaryBlue,
              child: ListView.builder(padding: const EdgeInsets.all(12), itemCount: _orders.length, itemBuilder: (_, i) => _buildOrderCard(_orders[i]))),
    );
  }

  Widget _buildFilterChips(){
    final filters=[{'key':'all','label':'Tous'},{'key':'pending','label':'En attente'},{'key':'processing','label':'Préparation'},{'key':'shipped','label':'Expédiée'},{'key':'delivered','label':'Livrée'},{'key':'cancelled','label':'Annulée'}];
    return Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(scrollDirection: Axis.horizontal,
        child: Row(children: filters.map((f){ final sel=_filter==f['key']; return Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(f['label'] as String), selected: sel, onSelected: (_){setState(()=>_filter=f['key'] as String);_loadOrders();}, selectedColor: primaryBlue, labelStyle: TextStyle(color: sel?Colors.white:Colors.black87, fontWeight: sel?FontWeight.w600:FontWeight.w400), backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: sel?primaryBlue:Colors.grey[300]!)), showCheckmark: false));}).toList())));
  }

  Widget _buildOrderCard(Map<String, dynamic> order){
    final status=order['status']??'pending'; final total=(order['total'] as num?)?.toDouble()??0; final createdAt=_formatDate(order['created_at']);
    final items=List<Map<String,dynamic>>.from(order['items']??[]); final shop=order['shop'] as Map?; final statusColor=_getStatusColor(status);
    final String currency=order['currency']??(items.isNotEmpty?items.first['currency']:null)??'FCFA';
    return Card(margin: const EdgeInsets.only(bottom:12), elevation:0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!)),
      child: InkWell(onTap: ()=>context.pushNamed('marketOrderDetail', pathParameters:{'orderId':order['id'].toString()}), borderRadius: BorderRadius.circular(12),
        child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[Expanded(child: Text('Commande #${order['id'].toString().substring(0,8)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize:16), overflow: TextOverflow.ellipsis)), Container(padding: const EdgeInsets.symmetric(horizontal:10,vertical:4), decoration: BoxDecoration(color: statusColor.withValues(alpha:0.1), borderRadius: BorderRadius.circular(12)), child: Text(_getStatusLabel(status), style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize:12))) ] ),
          const SizedBox(height:8), Row(children:[Icon(Icons.access_time,size:14,color:Colors.grey[500]), const SizedBox(width:4), Text(createdAt, style:TextStyle(fontSize:12,color:Colors.grey[500]))]),
          const SizedBox(height:12),
          if(shop!=null) Row(children:[CircleAvatar(radius:14, backgroundImage: shop['logo_url']!=null?CachedNetworkImageProvider(shop['logo_url']):null, child: shop['logo_url']==null?const Icon(Icons.store,size:14):null), const SizedBox(width:8), Expanded(child: Text(shop['name']??'Boutique', style: const TextStyle(fontWeight: FontWeight.w500)))]),
          const SizedBox(height:12),
          if(items.isNotEmpty)...[...items.take(2).map((item){ final p=(item['price'] as num?)?.toDouble()??0; final ic=item['currency']??currency; return Padding(padding: const EdgeInsets.only(bottom:6), child: Row(children:[ClipRRect(borderRadius: BorderRadius.circular(6), child: item['product_image']!=null?CachedNetworkImage(imageUrl:item['product_image'], width:40, height:40, fit:BoxFit.cover, errorWidget:(_,__,___)=>_buildFallbackImage()):_buildFallbackImage()), const SizedBox(width:10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[Text(item['product_name']??'Produit', style: const TextStyle(fontWeight:FontWeight.w500), maxLines:1, overflow:TextOverflow.ellipsis), Text('${item['quantity']} x ${p.toStringAsFixed(p.truncateToDouble()==p?0:2)} $ic', style:TextStyle(fontSize:12,color:Colors.grey[600]))]))]));}), if(items.length>2) Padding(padding: const EdgeInsets.only(top:4), child: Text('et ${items.length-2} autre(s) article(s)', style:TextStyle(fontSize:12,color:Colors.grey[600])))],
          const Divider(height:24), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[const Text('Total', style:TextStyle(fontWeight:FontWeight.bold)), Text('${total.toStringAsFixed(total.truncateToDouble()==total?0:2)} $currency', style: const TextStyle(fontWeight:FontWeight.bold,fontSize:18,color:primaryBlue))])
        ]))));
  }
  Widget _buildFallbackImage()=>Container(width:40,height:40,color:Colors.grey[200],child: const Icon(Icons.image,size:20,color:Colors.grey));
  Widget _buildErrorState()=>Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children:[Icon(Icons.error_outline,size:60,color:Colors.grey[400]), const SizedBox(height:16), Padding(padding: const EdgeInsets.symmetric(horizontal:24), child: Text(_error??'Erreur', textAlign:TextAlign.center, style: const TextStyle(fontSize:14,color:Colors.grey))), const SizedBox(height:16), ElevatedButton(onPressed:_loadOrders, style:ElevatedButton.styleFrom(backgroundColor:primaryBlue, shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(20))), child: const Text('Réessayer', style:TextStyle(color:Colors.white)))]));
  Widget _buildEmptyState()=>Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children:[Icon(Icons.shopping_bag_outlined,size:60,color:Colors.grey[300]), const SizedBox(height:16), const Text('Aucune commande', style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)), const SizedBox(height:8), Text('Vos commandes apparaîtront ici', style:TextStyle(color:Colors.grey[500])), const SizedBox(height:24), ElevatedButton(onPressed:()=>context.pushNamed('marketBuy'), style:ElevatedButton.styleFrom(backgroundColor:primaryBlue, shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(24)), padding: const EdgeInsets.symmetric(horizontal:24,vertical:12)), child: const Text('Découvrir des produits', style:TextStyle(color:Colors.white,fontWeight:FontWeight.bold)))]));
}
