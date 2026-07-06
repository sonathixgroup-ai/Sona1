import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../providers/sell_provider.dart';

class SellPage extends StatefulWidget {
  const SellPage({super.key});

  @override
  State<SellPage> createState() => _SellPageState();
}

class _SellPageState extends State<SellPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final provider = context.read<SellProvider>();
    await Future.wait([
      provider.loadMyAnnouncements(),
      provider.loadOrders(),
    ]);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sellProvider = context.watch<SellProvider>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Vendre',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Annonces'),
            Tab(text: 'Commandes'),
            Tab(text: 'Stats'),
          ],
          indicatorColor: const Color(0xFF1A73E8),
          labelColor: const Color(0xFF1A73E8),
          unselectedLabelColor: Colors.grey,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: _loadData,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyAnnouncements(sellProvider),
          _buildOrders(sellProvider),
          _buildStats(sellProvider),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/market/announcement/publish'),
        backgroundColor: const Color(0xFF1A73E8),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Publier',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  // ============================================================
  // TAB 1 : MES ANNONCES
  // ============================================================
  Widget _buildMyAnnouncements(SellProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.announcements.isEmpty) {
      return _buildEmptyState(
        'Aucune annonce',
        'Publiez votre première annonce pour commencer à vendre',
        Icons.sell,
        () => context.push('/market/announcement/publish'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: provider.announcements.length,
        itemBuilder: (context, index) {
          final announcement = provider.announcements[index];
          return _buildAnnouncementCard(announcement);
        },
      ),
    );
  }

  Widget _buildAnnouncementCard(Map<String, dynamic> announcement) {
    final statusColors = {
      'active': Colors.green,
      'pending': Colors.orange,
      'expired': Colors.grey,
      'refused': Colors.red,
    };
    final statusColor = statusColors[announcement['status']] ?? Colors.grey;
    final statusText = {
      'active': 'En ligne',
      'pending': 'En attente',
      'expired': 'Expirée',
      'refused': 'Refusée',
    }[announcement['status']] ?? 'Inconnu';
    final hasDiscount = announcement['discount_price'] != null &&
        announcement['discount_price'] < announcement['price'];
    final images = (announcement['images'] as List?) ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: images.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: images.first,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[200],
                          ),
                          errorWidget: (_, __, ___) => Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[200],
                            child: const Icon(Icons.image, color: Colors.grey),
                          ),
                        )
                      : Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[200],
                          child: const Icon(Icons.image, color: Colors.grey),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        announcement['title'] ?? 'Sans titre',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${(hasDiscount ? announcement['discount_price'] : announcement['price']).toInt()} FCFA',
                            style: const TextStyle(
                              color: Color(0xFF1A73E8),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (hasDiscount)
                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Text(
                                '${announcement['price'].toInt()} FCFA',
                                style: TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              statusText!,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Vues: ${announcement['views'] ?? 0}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Stock: ${announcement['stock'] ?? 0}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/market/announcement/${announcement['id']}/edit'),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Modifier'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showBoostDialog(announcement['id']),
                    icon: const Icon(Icons.trending_up, size: 18),
                    label: const Text('Booster'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _shareAnnouncement(announcement['id']),
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('Partager'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TAB 2 : COMMANDES
  // ============================================================
  Widget _buildOrders(SellProvider provider) {
    if (provider.isLoadingOrders) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.orders.isEmpty) {
      return _buildEmptyState(
        'Aucune commande',
        'Les commandes apparaîtront ici',
        Icons.shopping_bag,
        () {},
      );
    }

    // Grouper par statut
    final pendingOrders = provider.orders.where((o) => o['status'] == 'pending').toList();
    final preparingOrders = provider.orders.where((o) => o['status'] == 'preparing').toList();
    final shippedOrders = provider.orders.where((o) => o['status'] == 'shipped').toList();
    final completedOrders = provider.orders.where((o) => o['status'] == 'completed').toList();

    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'À traiter'),
              Tab(text: 'Préparation'),
              Tab(text: 'Expédiées'),
              Tab(text: 'Terminées'),
            ],
            isScrollable: true,
            indicatorColor: Color(0xFF1A73E8),
            labelColor: Color(0xFF1A73E8),
            unselectedLabelColor: Colors.grey,
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildOrderList(pendingOrders),
                _buildOrderList(preparingOrders),
                _buildOrderList(shippedOrders),
                _buildOrderList(completedOrders),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList(List<Map<String, dynamic>> orders) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('Aucune commande', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return _buildOrderCard(order);
        },
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final statusColors = {
      'pending': Colors.orange,
      'preparing': Colors.blue,
      'shipped': Colors.purple,
      'completed': Colors.green,
      'cancelled': Colors.red,
    };
    final statusLabels = {
      'pending': 'À traiter',
      'preparing': 'En préparation',
      'shipped': 'Expédiée',
      'completed': 'Terminée',
      'cancelled': 'Annulée',
    };
    final status = order['status'] ?? 'pending';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ListTile(
        onTap: () => context.push('/market/order/${order['id']}'),
        leading: CircleAvatar(
          backgroundColor: statusColors[status]?.withOpacity(0.1) ?? Colors.grey[200],
          child: Icon(
            status == 'pending' ? Icons.pending :
            status == 'preparing' ? Icons.inventory :
            status == 'shipped' ? Icons.local_shipping :
            Icons.check,
            color: statusColors[status] ?? Colors.grey,
            size: 20,
          ),
        ),
        title: Text(
          'Commande #${order['id']}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${order['items_count'] ?? 0} produits · ${order['total']?.toInt() ?? 0} FCFA',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColors[status]?.withOpacity(0.1) ?? Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                statusLabels[status] ?? status,
                style: TextStyle(
                  color: statusColors[status] ?? Colors.grey,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              order['date'] ?? '',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TAB 3 : STATISTIQUES
  // ============================================================
  Widget _buildStats(SellProvider provider) {
    final stats = provider.stats;
    final salesData = (stats['sales_data'] as List?)?.map((e) => (e['value'] ?? 0).toDouble()).toList() ?? [];
    final labels = (stats['sales_data'] as List?)?.map((e) => e['label'] ?? '').toList() ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // KPIs
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.1,
            children: [
              _buildStatCard(
                'Ventes totales',
                '${stats['total_sales'] ?? 0}',
                Icons.trending_up,
                Colors.green,
              ),
              _buildStatCard(
                'Chiffre d\'affaires',
                '${stats['revenue']?.toInt() ?? 0} FCFA',
                Icons.attach_money,
                const Color(0xFF1A73E8),
              ),
              _buildStatCard(
                'Vues totales',
                '${stats['total_views'] ?? 0}',
                Icons.visibility,
                Colors.purple,
              ),
              _buildStatCard(
                'Taux conversion',
                '${stats['conversion_rate']?.toStringAsFixed(1) ?? 0}%',
                Icons.percent,
                Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Graphique
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey[200]!),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ventes mensuelles',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (salesData.isNotEmpty)
                    SizedBox(
                      height: 200,
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(show: false),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  if (index >= 0 && index < labels.length) {
                                    return Text(
                                      labels[index],
                                      style: const TextStyle(fontSize: 10),
                                    );
                                  }
                                  return const Text('');
                                },
                                reservedSize: 24,
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: List.generate(salesData.length, (index) {
                                return FlSpot(index.toDouble(), salesData[index]);
                              }),
                              isCurved: true,
                              color: const Color(0xFF1A73E8),
                              barWidth: 3,
                              dotData: FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color: const Color(0xFF1A73E8).withOpacity(0.1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('Aucune donnée de vente'),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Top produits
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey[200]!),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Meilleures ventes',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...(stats['top_products'] as List? ?? []).take(5).map((product) => ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: CachedNetworkImage(
                        imageUrl: product['image_url'] ?? '',
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          width: 40,
                          height: 40,
                          color: Colors.grey[200],
                          child: const Icon(Icons.image, size: 20),
                        ),
                      ),
                    ),
                    title: Text(
                      product['name'] ?? 'Produit',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text('${product['sales']} vendus'),
                    trailing: Text(
                      '${product['revenue']?.toInt() ?? 0} FCFA',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A73E8),
                      ),
                    ),
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // UTILITAIRES
  // ============================================================
  Widget _buildEmptyState(String title, String subtitle, IconData icon, VoidCallback onAction) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onAction,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A73E8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Publier une annonce'),
          ),
        ],
      ),
    );
  }

  void _showBoostDialog(String announcementId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => BoostOptionsSheet(
        announcementId: announcementId,
        onBoostSelected: (package) {
          // Logique d'achat du boost
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Boost ${package['name']} sélectionné')),
          );
        },
      ),
    );
  }

  void _shareAnnouncement(String id) {
    // Logique de partage
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Partage en cours de développement')),
    );
  }
}

// ============================================================
// BOOST OPTIONS SHEET
// ============================================================
class BoostOptionsSheet extends StatelessWidget {
  final String announcementId;
  final Function(Map<String, dynamic>)? onBoostSelected;

  const BoostOptionsSheet({
    super.key,
    required this.announcementId,
    this.onBoostSelected,
  });

  final List<Map<String, dynamic>> packages = const [
    {
      'name': 'Standard',
      'price': 2500,
      'description': '5 000 vues garanties',
      'days': 7,
      'color': 0xFF4CAF50,
    },
    {
      'name': 'Premium',
      'price': 5000,
      'description': '15 000 vues garanties',
      'days': 14,
      'color': 0xFF1A73E8,
    },
    {
      'name': 'VIP',
      'price': 10000,
      'description': '50 000 vues garanties',
      'days': 30,
      'color': 0xFFE5592F,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Booster votre annonce',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Augmentez la visibilité de votre annonce',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 20),
          ...packages.map((pkg) => _buildPackageOption(context, pkg)),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageOption(BuildContext context, Map<String, dynamic> pkg) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ListTile(
        onTap: () {
          onBoostSelected?.call(pkg);
          Navigator.pop(context);
        },
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Color(pkg['color']).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.trending_up,
            color: Color(pkg['color']),
            size: 22,
          ),
        ),
        title: Text(
          pkg['name'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${pkg['description']} · ${pkg['days']} jours',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${pkg['price']} FCFA',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A73E8),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF1A73E8).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Populaire',
                style: TextStyle(
                  fontSize: 9,
                  color: const Color(0xFF1A73E8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
