import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class MyAnnouncementsList extends StatefulWidget {
  final String shopId;
  final Function(Map<String, dynamic>)? onEdit;
  final Function(String)? onDelete;

  const MyAnnouncementsList({
    super.key,
    required this.shopId,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<MyAnnouncementsList> createState() => _MyAnnouncementsListState();
}

class _MyAnnouncementsListState extends State<MyAnnouncementsList> {
  List<Map<String, dynamic>> _announcements = [];
  bool _isLoading = true;
  String _filter = 'all'; // all, active, pending, sold_out

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    setState(() => _isLoading = true);
    
    try {
      var query = Supabase.instance.client
          .from('products')
          .select()
          .eq('shop_id', widget.shopId)
          .order('created_at', ascending: false);
      
      if (_filter == 'active') {
        query = query.eq('status', 'active').gt('stock', 0);
      } else if (_filter == 'pending') {
        query = query.eq('status', 'pending');
      } else if (_filter == 'sold_out') {
        query = query.eq('stock', 0);
      }
      
      final response = await query;
      
      setState(() {
        _announcements = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading announcements: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAnnouncement(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'annonce'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette annonce ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    try {
      await Supabase.instance.client
          .from('products')
          .delete()
          .eq('id', id);
      
      widget.onDelete?.call(id);
      await _loadAnnouncements();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Annonce supprimée')),
        );
      }
    } catch (e) {
      debugPrint('Error deleting: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    }
  }

  Future<void> _toggleStatus(Map<String, dynamic> announcement) async {
    final newStatus = announcement['status'] == 'active' ? 'inactive' : 'active';
    
    try {
      await Supabase.instance.client
          .from('products')
          .update({'status': newStatus})
          .eq('id', announcement['id']);
      
      await _loadAnnouncements();
    } catch (e) {
      debugPrint('Error toggling status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter chips
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildFilterChip('Tous', 'all'),
              const SizedBox(width: 8),
              _buildFilterChip('En ligne', 'active'),
              const SizedBox(width: 8),
              _buildFilterChip('En attente', 'pending'),
              const SizedBox(width: 8),
              _buildFilterChip('Épuisés', 'sold_out'),
            ],
          ),
        ),
        
        // List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _announcements.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _announcements.length,
                      itemBuilder: (context, index) {
                        return _buildAnnouncementCard(_announcements[index]);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return FilterChip(
      label: Text(label),
      selected: _filter == value,
      onSelected: (selected) {
        setState(() => _filter = value);
        _loadAnnouncements();
      },
      selectedColor: const Color(0xFFE5592F).withOpacity(0.1),
      checkmarkColor: const Color(0xFFE5592F),
    );
  }

  Widget _buildAnnouncementCard(Map<String, dynamic> announcement) {
    final isActive = announcement['status'] == 'active';
    final stock = announcement['stock'] ?? 0;
    final hasDiscount = announcement['discount_price'] != null &&
        announcement['discount_price'] < announcement['price'];
    
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
          children: [
            Row(
              children: [
                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: (announcement['images'] as List?)?.first ?? '',
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        announcement['title'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${(hasDiscount ? announcement['discount_price'] : announcement['price']).toInt()} FCFA',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE5592F),
                            ),
                          ),
                          if (hasDiscount)
                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Text(
                                '${announcement['price'].toInt()} FCFA',
                                style: TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isActive ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isActive ? 'En ligne' : (stock == 0 ? 'Épuisé' : 'Inactif'),
                              style: TextStyle(
                                fontSize: 11,
                                color: isActive ? Colors.green : Colors.orange,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Stock: $stock',
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Vues: ${announcement['views'] ?? 0}',
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
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
                    onPressed: () => widget.onEdit?.call(announcement),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Modifier'),
                    style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.grey[300]!)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _toggleStatus(announcement),
                    icon: Icon(
                      isActive ? Icons.visibility_off : Icons.visibility,
                      size: 18,
                    ),
                    label: Text(isActive ? 'Désactiver' : 'Activer'),
                    style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.grey[300]!)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _deleteAnnouncement(announcement['id']),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Supprimer'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'Aucune annonce',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Publiez votre première annonce',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
