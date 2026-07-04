import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/sell_provider.dart';

class SellPage extends StatefulWidget {
  const SellPage({super.key});

  @override
  State<SellPage> createState() => _SellPageState();
}

class _SellPageState extends State<SellPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SellProvider>().loadMyAnnouncements();
      context.read<SellProvider>().loadOrders();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
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
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Mes annonces'),
            Tab(text: 'Commandes'),
            Tab(text: 'Stats'),
          ],
          indicatorColor: const Color(0xFFE5592F),
          labelColor: const Color(0xFFE5592F),
          unselectedLabelColor: Colors.grey,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _publishAnnouncement(),
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
        onPressed: () => _publishAnnouncement(),
        backgroundColor: const Color(0xFFE5592F),
        icon: const Icon(Icons.add),
        label: const Text('Publier'),
      ),
    );
  }

  Widget _buildMyAnnouncements(SellProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.announcements.isEmpty) {
      return _buildEmptyState(
        'Aucune annonce',
        'Publiez votre première annonce pour commencer à vendre',
        Icons.sell,
        () => _publishAnnouncement(),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.announcements.length,
      itemBuilder: (context, index) {
        final announcement = provider.announcements[index];
        return _buildAnnouncementCard(announcement);
      },
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
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[200],
                  ),
                  child: announcement['images'] != null && announcement['images'].isNotEmpty
                      ? Image.network(
                          announcement['images'][0],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.image),
                        )
                      : const Icon(Icons.image),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        announcement['title'],
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${announcement['price']} FCFA',
                        style: const TextStyle(
                          color: Color(0xFFE5592F),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              statusText!,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Vues: ${announcement['views'] ?? 0}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _editAnnouncement(announcement['id']),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Modifier'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _boostAnnouncement(announcement['id']),
                    icon: const Icon(Icons.trending_up, size: 18),
                    label: const Text('Booster'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey[300]!),
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

    // Group orders by status
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
            indicatorColor: Color(0xFFE5592F),
            labelColor: Color(0xFFE5592F),
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

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFE5592F).withOpacity(0.1),
              child: Text('${index + 1}'),
            ),
            title: Text('Commande #${order['id']}'),
            subtitle: Text('${order['items_count']} produits · ${order['total']} FCFA'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  order['status'] == 'pending' ? 'À traiter' : 
                  order['status'] == 'preparing' ? 'En préparation' :
                  order['status'] == 'shipped' ? 'Expédiée' : 'Terminée',
                  style: TextStyle(
                    color: order['status'] == 'pending' ? Colors.orange :
                           order['status'] == 'preparing' ? Colors.blue :
                           order['status'] == 'shipped' ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  order['date'],
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
            onTap: () => _viewOrderDetail(order['id']),
          ),
        );
      },
    );
  }

  Widget _buildStats(SellProvider provider) {
    final stats = provider.stats;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // KPIs
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              _buildStatCard('Ventes totales', '${stats['total_sales'] ?? 0}', Icons.trending_up, Colors.green),
              _buildStatCard('Chiffre d\'affaires', '${stats['revenue'] ?? 0} FCFA', Icons.attach_money, Colors.blue),
              _buildStatCard('Vues totales', '${stats['total_views'] ?? 0}', Icons.visibility, Colors.purple),
              _buildStatCard('Taux conversion', '${stats['conversion_rate'] ?? 0}%', Icons.percent, Colors.orange),
            ],
          ),
          const SizedBox(height: 24),
          
          // Chart placeholder
          Card(
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
                  SizedBox(
                    height: 200,
                    child: Center(
                      child: Text(
                        'Graphique des ventes',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Top products
          Card(
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
                  ...(stats['top_products'] as List? ?? []).map((product) => ListTile(
                    leading: const Icon(Icons.shopping_bag),
                    title: Text(product['name']),
                    trailing: Text('${product['sales']} vendus'),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon, VoidCallback onAction) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onAction,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE5592F),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            child: const Text('Publier une annonce'),
          ),
        ],
      ),
    );
  }

  void _publishAnnouncement() {
    Navigator.pushNamed(context, '/publish-announcement');
  }

  void _editAnnouncement(String id) {
    Navigator.pushNamed(context, '/edit-announcement/$id');
  }

  void _boostAnnouncement(String id) {
    showModalBottomSheet(
      context: context,
      builder: (context) => BoostOptionsSheet(announcementId: id),
    );
  }

  void _shareAnnouncement(String id) {
    // Share logic
  }

  void _viewOrderDetail(String orderId) {
    Navigator.pushNamed(context, '/order-detail/$orderId');
  }
}

class BoostOptionsSheet extends StatelessWidget {
  final String announcementId;
  const BoostOptionsSheet({super.key, required this.announcementId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Booster votre annonce', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildBoostOption('Standard', '2 500 FCFA', '5 000 vues garanties', 7),
          _buildBoostOption('Premium', '5 000 FCFA', '15 000 vues garanties', 14),
          _buildBoostOption('VIP', '10 000 FCFA', '50 000 vues garanties', 30),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE5592F),
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('Choisir cette offre'),
          ),
        ],
      ),
    );
  }

  Widget _buildBoostOption(String name, String price, String description, int days) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(price, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE5592F))),
            Text('$days jours', style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
