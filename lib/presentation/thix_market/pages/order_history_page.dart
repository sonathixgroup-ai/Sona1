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
  String _filter = 'all'; // all, pending, processing, shipped, delivered, cancelled

  static const Color primaryBlue = Color(0xFF1A73E8);
  static const Color bgLight = Color(0xFFF8F9FA);

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        setState(() {
          _orders = [];
          _isLoading = false;
        });
        return;
      }

      var query = Supabase.instance.client
          .from('orders')
          .select('''
            *,
            items:order_items(*),
            shop:shops(name, logo_url)
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      if (_filter != 'all') {
        query = query.eq('status', _filter);
      }

      final response = await query;
      setState(() {
        _orders = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Impossible de charger vos commandes';
        _isLoading = false;
      });
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy, HH:mm').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'shipped':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'processing':
        return 'En préparation';
      case 'shipped':
        return 'Expédiée';
      case 'delivered':
        return 'Livrée';
      case 'cancelled':
        return 'Annulée';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        title: const Text(
          'Historique des commandes',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: _loadOrders,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _buildFilterChips(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _orders.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadOrders,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _orders.length,
                        itemBuilder: (context, index) {
                          final order = _orders[index];
                          return _buildOrderCard(order);
                        },
                      ),
                    ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'key': 'all', 'label': 'Tous'},
      {'key': 'pending', 'label': 'En attente'},
      {'key': 'processing', 'label': 'Préparation'},
      {'key': 'shipped', 'label': 'Expédiée'},
      {'key': 'delivered', 'label': 'Livrée'},
      {'key': 'cancelled', 'label': 'Annulée'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            final isSelected = _filter == filter['key'];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(filter['label'] as String),
                selected: isSelected,
                onSelected: (_) {
                  setState(() => _filter = filter['key'] as String);
                  _loadOrders();
                },
                selectedColor: primaryBlue,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                ),
                backgroundColor: isSelected ? primaryBlue : Colors.white,
                side: BorderSide(
                  color: isSelected ? primaryBlue : Colors.grey[300]!,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'] ?? 'pending';
    final total = (order['total'] as num?)?.toDouble() ?? 0;
    final createdAt = _formatDate(order['created_at']);
    final items = List<Map<String, dynamic>>.from(order['items'] ?? []);
    final shop = order['shop'] as Map?;
    final statusColor = _getStatusColor(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: () => context.push('/market/order/${order['id']}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête : numéro, date, statut
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Commande #${order['id']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusLabel(status),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Date
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    createdAt,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Boutique
              if (shop != null)
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundImage: shop['logo_url'] != null
                          ? CachedNetworkImageProvider(shop['logo_url'])
                          : null,
                      child: shop['logo_url'] == null
                          ? const Icon(Icons.store, size: 14)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        shop['name'] ?? 'Boutique',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 12),

              // Articles (max 2)
              if (items.isNotEmpty) ...[
                ...items.take(2).map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: item['product_image'] != null
                            ? CachedNetworkImage(
                                imageUrl: item['product_image'],
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => Container(
                                  width: 40,
                                  height: 40,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.image, size: 20),
                                ),
                              )
                            : Container(
                                width: 40,
                                height: 40,
                                color: Colors.grey[200],
                                child: const Icon(Icons.image, size: 20),
                              ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['product_name'] ?? 'Produit',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${item['quantity']} x ${item['price']?.toInt() ?? 0} FCFA',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
                if (items.length > 2)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'et ${items.length - 2} autre(s) article(s)',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
              ],
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${total.toInt()} FCFA',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: primaryBlue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadOrders,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
            ),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'Aucune commande',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Vos commandes apparaîtront ici',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.push('/market/buy'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text('Découvrir des produits'),
          ),
        ],
      ),
    );
  }
}
